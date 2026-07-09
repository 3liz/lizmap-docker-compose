#!/bin/sh
#
# Runs before the official lizmap-entrypoint.sh so that any module declared
# in var/lizmap-my-packages/composer.json (e.g. the WebDAV module) is
# installed and configured automatically, with no manual step required.
#
# Opt-in: only runs when LIZMAP_ENABLE_EXTRA_MODULES=1, so plain local setups
# don't get extra modules unless they ask for it (see docker-compose.codespaces.yml
# for the Codespaces override that turns it on).
#
# Note: `php configurator.php` (with no module name) does not reliably pick
# up a module the very first time it is installed via Composer, so each
# module found in the Composer-generated jelix_modules_infos.json is
# configured explicitly by name.
#
# Idempotent: composer install is a no-op once vendor/ matches composer.lock,
# and configurator.php skips modules that are already configured.
#
set -e

MY_PACKAGES_DIR=/www/lizmap/my-packages

if [ "${LIZMAP_ENABLE_EXTRA_MODULES:-0}" = "1" ] && [ -f "$MY_PACKAGES_DIR/composer.json" ]; then
    # lizmap-entrypoint.sh normally seeds var/config from var/config.dist before
    # running the Jelix installer/configurator. Since we run *before* it, do the
    # same seeding here first: otherwise, on a brand new volume, configurator.php
    # below would initialize a bare profiles.ini.php missing the [jdb] defaults
    # (e.g. no driver for the "default" profile), and the real entrypoint would
    # then skip its own copy since the file already exists. Safe/idempotent to
    # run twice.
    CONFIG_DIR=/www/lizmap/var/config
    cp -aR "$CONFIG_DIR.dist"/* "$CONFIG_DIR"
    [ ! -f "$CONFIG_DIR/lizmapConfig.ini.php" ] && cp "$CONFIG_DIR/lizmapConfig.ini.php.dist" "$CONFIG_DIR/lizmapConfig.ini.php"
    [ ! -f "$CONFIG_DIR/localconfig.ini.php" ] && cp "$CONFIG_DIR/localconfig.ini.php.dist" "$CONFIG_DIR/localconfig.ini.php"
    [ ! -f "$CONFIG_DIR/profiles.ini.php" ] && cp "$CONFIG_DIR/profiles.ini.php.dist" "$CONFIG_DIR/profiles.ini.php"

    echo "Installing composer packages from $MY_PACKAGES_DIR"
    composer install --working-dir="$MY_PACKAGES_DIR" --no-interaction

    if [ "$(id -u)" -eq "0" ]; then
        UID_GID=${LIZMAP_USER:-1000}
        chown -R "$UID_GID:$UID_GID" "$MY_PACKAGES_DIR"
    fi

    MODULES_INFOS="$MY_PACKAGES_DIR/vendor/jelix_modules_infos.json"
    if [ -f "$MODULES_INFOS" ]; then
        MODULES=$(php -r '
            $data = json_decode(file_get_contents($argv[1]), true) ?: array();
            $names = array();
            foreach (($data["packages"] ?? array()) as $pkg) {
                foreach (($pkg["modules"] ?? array()) as $modPath) {
                    $names[] = basename($modPath);
                }
            }
            echo implode(" ", array_unique($names));
        ' "$MODULES_INFOS")

        for module in $MODULES; do
            echo "Configuring module: $module"
            php /www/lizmap/install/configurator.php --no-interaction "$module"
        done
    fi
fi

exec /bin/lizmap-entrypoint.sh "$@"
