#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=$CNAB_INSTALLATION_NAME

# The docker compose commande
DOCKER_COMPOSE="docker-compose --env-file /root/.lizmap-env"

# Actions

build-installer() {
    docker build --rm \
        -t lizmap-installer-helper:latest -f Dockerfile.installer .
}

configure() {
    docker run --rm \
    -e COPY_COMPOSE_FILE=no \
    -e LIZMAP_INSTALL_DIR \
    -e QGIS_VERSION_TAG \
    -e LIZMAP_VERSION_TAG \
    -e LIZMAP_PLUGIN_VERSION \
    -e POSTGIS_VERSION \
    -e QGIS_MAP_WORKERS \
    -e LIZMAP_PORT \
    -e POSTGIS_PORT \
    -e POSTGRES_PASSWORD \
    -v $LIZMAP_INSTALL_DIR:/lizmap \
    lizmap-installer-helper:latest configure

    # Dump the env file into our context
    docker run --rm -t -v $LIZMAP_INSTALL_DIR:/lizmap \
        lizmap-installer-helper:latest cat /lizmap/.env > /root/.lizmap-env
}

run-services() {
    $DOCKER_COMPOSE up -d
}

start-services() {
    $DOCKER_COMPOSE /root/.lizmap-env start $1
}

stop-services() {
    $DOCKER_COMPOSE stop $1
}

install-modules() {
    # Note: use -T since there is no TTY available
    echo "Installing lizmap module $@"
    $DOCKER_COMPOSE exec -T -- lizmap \
        lizmap-install-module "$@"
    echo "Updating lizmap installation"
    $DOCKER_COMPOSE exec -T -- lizmap \
        php /www/lizmap/install/installer.php
}

upgrade() {
    configure
    $DOCKER_COMPOSE pull
    $DOCKER_COMPOSE up -d --force-recreate
}

uninstall() {
    $DOCKER_COMPOSE down --remove-orphans -v
}

show-config() {
    echo "== Docker compose environment =="
    cat /root/.lizmap-env
    echo 
    echo "== System environment =="
    env
}

compose-ps() {
    $DOCKER_COMPOSE ps
}

compose-logs() {
    $DOCKER_COMPOSE logs $1
}


# Call the requested function and pass the arguments as-is
"$@"
