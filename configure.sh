#!/bin/bash

#
# Check uid/gid of installation dir
#

set -e

scriptdir=$(realpath `dirname $0`)

if [ ! -d $INSTALL_DEST ]; then
    echo "Error: '$INSTALL_DEST' does not exists"
    exit 1
fi

export LIZMAP_UID=$(id -u)
export LIZMAP_GID=$(id -g)

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
		POSTGRES_LIZMAP_DB=$POSTGRES_LIZMAP_DB
		POSTGRES_LIZMAP_USER=$POSTGRES_LIZMAP_USER
		POSTGRES_LIZMAP_PASSWORD=$POSTGRES_LIZMAP_PASSWORD
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

_makepgservice() {
    source $INSTALL_SOURCE/env.default
    cat > $INSTALL_DEST/etc/pg_service.conf <<-EOF
[lizmap_local]
host=$POSTGIS_ALIAS
port=5432
dbname=$POSTGRES_LIZMAP_DB
user=$POSTGRES_LIZMAP_USER
password=$POSTGRES_LIZMAP_PASSWORD
EOF
    chown $LIZMAP_UID:$LIZMAP_GID $INSTALL_DEST/etc/pg_service.conf
}

_makelizmapprofiles() {
    source $INSTALL_SOURCE/env.default
    cat > $INSTALL_DEST/etc/profiles.d/lizmap_local.ini.php <<-EOF
[jdb:jauth]
driver=pgsql
host=$POSTGIS_ALIAS
port=5432
database=$POSTGRES_LIZMAP_DB
user=$POSTGRES_LIZMAP_USER
password="$POSTGRES_LIZMAP_PASSWORD"
search_path=lizmap,public
EOF
    chown $LIZMAP_UID:$LIZMAP_GID $INSTALL_DEST/etc/profiles.d/lizmap_local.ini.php
}

_install-plugin() {
    local plugindir=$INSTALL_DEST/plugins
    docker run -it \
        -u $(id -u):$(id -g) \
        -e QGSRV_SERVER_PLUGINPATH=/srv/plugins \
        -v $plugindir:/srv/plugins \
        -v $scriptdir:/src \
        --entrypoint /src/install-lizmap-plugin.sh \
        3liz/qgis-map-server:${QGIS_VERSION_TAG}
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
    # Create pg_service.conf
    #
    echo "Creating pg_service.conf"
    _makepgservice

    #
    # Create lizmap profiles
    #
    echo "Creating lizmap profiles"
    _makelizmapprofiles

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

