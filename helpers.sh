#!/usr/bin/env bash
set -euo pipefail


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
    docker-compose --env-file /root/.lizmap-env up -d
}

start-services() {
    docker-compose --env-file /root/.lizmap-env start $1
}

stop-services() {
    docker-compose --env-file /root/.lizmap-env stop $1
}

upgrade() {
    configure
    docker-compose --env-file /root/.lizmap-env pull
    docker-compose --env-file /root/.lizmap-env up -d --force-recreate
}

uninstall() {
    docker-compose --env-file /root/.lizmap-env down --remove-orphans -v
}

# Call the requested function and pass the arguments as-is
"$@"
