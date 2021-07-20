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
else
  export LIZMAP_UID=$(id -u)
  export LIZMAP_GID=$(id -g)
fi

#
# Commands
#

_makedirs() {
    su-exec $LIZMAP_UID:$LIZMAP_GID mkdir -p $INSTALL_DEST/plugins \
             $INSTALL_DEST/processing \
             $INSTALL_DEST/wps-data \
             $INSTALL_DEST/www/var/log \
             $INSTALL_DEST/var/log/nginx \
             $INSTALL_DEST/var/nginx-cache \
             $INSTALL_DEST/var/lizmap-theme-config \
             $INSTALL_DEST/var/lizmap-db \
             $INSTALL_DEST/var/lizmap-config
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
    source $INSTALL_SOURCE/env.default

    LIZMAP_PROJECTS=${LIZMAP_PROJECTS:-"$LIZMAP_INSTALL_DIR/instances"} 

    su-exec $LIZMAP_UID:$LIZMAP_GID cat > $INSTALL_DEST/.env <<-EOF
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

    #
    # Send docker-compose file to standard output
    #
    if [ "$COPY_COMPOSE_FILE" = 'yes' ]; then
       echo "Copying docker compose file"
       cp $INSTALL_SOURCE/docker-compose.yml $INSTALL_DEST/
       chown $LIZMAP_UID:$LIZMAP_GID $INSTALL_DEST/docker-compose.yml
    fi
}


clean() {
    echo "Cleaning lizmap configs"
    rm -rf $INSTALL_DEST/www/*
    rm -rf $INSTALL_DEST/var/*
    rm -rf $INSTALL_DEST/wps-data/*
    _makedirs
}


"$@"

