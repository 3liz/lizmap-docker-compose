#!/bin/bash

#
# Check uid/gid of installation dir
#

set -e

if [ ! -d $INSTALL_DEST ]; then
    echo "Error: '$INSTALL_DEST' does not exists"
    exit 1
fi

if [ "$(id -u)" = '0' ]; then
    export LIZMAP_UID=$(stat -c '%u' $INSTALL_DEST)
    export LIZMAP_GID=$(stat -c '%g' $INSTALL_DEST)
    # Warn if the destination is owned by
    # Root, this may indicates that the directory was created
    # at binding
    if [ "$LIZMAP_UID" = '0' ]; then
        echo "WARNING: Your destination directory is owned by 'root'"
    else
        SUEXEC="su-exec $LIZMAP_UID:$LIZMAP_GID"
    fi
else
    export LIZMAP_UID=$(id -u)
    export LIZMAP_GID=$(id -g)
fi

#
# Commands
#

_makedirs() {
    $SUEXEC mkdir -p $INSTALL_DEST/plugins \
             $INSTALL_DEST/processing \
             $INSTALL_DEST/wps-data \
             $INSTALL_DEST/www/var/log \
             $INSTALL_DEST/var/log/nginx \
             $INSTALL_DEST/var/nginx-cache \
             $INSTALL_DEST/var/lizmap-theme-config \
             $INSTALL_DEST/var/lizmap-db \
             $INSTALL_DEST/var/lizmap-config \
             $INSTALL_DEST/var/lizmap-modules \
             $INSTALL_DEST/var/lizmap-my-packages
}

_makenv() {
    source $INSTALL_SOURCE/env.default
    LIZMAP_PROJECTS=${LIZMAP_PROJECTS:-"$LIZMAP_INSTALL_DIR/instances"} 
    cat > $INSTALL_DEST/.env <<-EOF
		LIZMAP_PROJECTS=$LIZMAP_PROJECTS
		LIZMAP_DIR=$LIZMAP_INSTALL_DIR
		LIZMAP_UID=$LIZMAP_UID
		LIZMAP_GID=$LIZMAP_GID
		LIZMAP_VERSION_TAG=$LIZMAP_VERSION_TAG
		QGIS_VERSION_TAG=$QGIS_VERSION_TAG
		POSTGIS_VERSION=$POSTGIS_VERSION
		POSTGRES_PASSWORD=$POSTGRES_PASSWORD
		QGIS_MAP_WORKERS=$QGIS_MAP_WORKERS
		WPS_NUM_WORKERS=$WPS_NUM_WORKERS
		LIZMAP_PORT=$LIZMAP_PORT
		OWS_PORT=$OWS_PORT
		WPS_PORT=$WPS_PORT
		POSTGIS_PORT=$POSTGIS_PORT
		POSTGIS_ALIAS=$POSTGIS_ALIAS   
		EOF
    chown $LIZMAP_UID:$LIZMAP_GID $INSTALL_DEST/.env
}


_install-plugin() {
    local plugindir=$INSTALL_DEST/plugins/lizmap
    if [ -d $plugindir ]; then
        local version=$(cat $plugindir/metadata.txt | grep "version=" |  cut -d '=' -f2)
        echo "Found installed version $version"
        if [ ! "$LIZMAP_PLUGIN_VERSION" = "$version" ]; then
            echo "Removing installed version"
            rm -rf $plugindir
        else
            echo "Installed version match required version"
            return 0
        fi
    fi
    echo "Installing version $LIZMAP_PLUGIN_VERSION"
    wget https://github.com/3liz/lizmap-plugin/releases/download/$LIZMAP_PLUGIN_VERSION/lizmap.$LIZMAP_PLUGIN_VERSION.zip \
        -O lizmap-plugin.zip
    unzip -qq lizmap-plugin.zip -d lizmap-plugin-$LIZMAP_PLUGIN_VERSION
    (
        cd lizmap-plugin-$LIZMAP_PLUGIN_VERSION
        local files="lizmap/__init__.py lizmap/server lizmap/tooltip.py lizmap/metadata.txt"
        mkdir $plugindir
        cp -rLp $files $plugindir/
    )
    # Clean up stuff
    rm -rf lizmap-plugin.zip lizmap-plugin-$LIZMAP_PLUGIN_VERSION
    # Since we fetche a tag directly from github,
    # we need to update the version in the metadata.txt
    chown -R $LIZMAP_UID:$LIZMAP_GID $plugindir
}


configure() {

    #
    # Copy configuration and create directories
    #
    echo "Copying files"
    cp -R $INSTALL_SOURCE/lizmap.dir/* $INSTALL_DEST/
    chown -R $LIZMAP_UID:$LIZMAP_GID $INSTALL_DEST

    echo "Creating directories"
    _makedirs

    #
    # Create env file
    #
    echo "Creating env file"
    _makenv

    #
    # Copy docker-compose file
    #
    if [ "$COPY_COMPOSE_FILE" = 'yes' ]; then
       echo "Copying docker compose file"
       cp $INSTALL_SOURCE/docker-compose.yml $INSTALL_DEST/
       chown $LIZMAP_UID:$LIZMAP_GID $INSTALL_DEST/docker-compose.yml
    fi

    #
    # Lizmap plugin
    #
    echo "Installing lizmap plugin"
    _install-plugin
}

clean() {
    echo "Cleaning lizmap configs"
    rm -rf $INSTALL_DEST/www/*
    rm -rf $INSTALL_DEST/var/*
    rm -rf $INSTALL_DEST/wps-data/*
    _makedirs
}


"$@"

