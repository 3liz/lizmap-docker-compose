#!/bin/bash

#
# Check uid/gid of installation dir
#
set -e

if [ -z $INSTALL_DEST ]; then
# Define default install destination as current directory
INSTALL_DEST=$(pwd)/lizmap
mkdir -p $INSTALL_DEST
fi

scriptdir=$(realpath `dirname $0`)

LIZMAP_UID=${LIZMAP_UID:-$(id -u)}
LIZMAP_GID=${LIZMAP_GID:-$(id -g)}

INSTALL_SOURCE=${INSTALL_SOURCE:-$scriptdir}

#
# Commands
#

_makedirs() {
    mkdir -p $INSTALL_DEST/plugins \
             $INSTALL_DEST/processing \
             $INSTALL_DEST/wps-data \
             $INSTALL_DEST/www \
             $INSTALL_DEST/var/log/nginx \
             $INSTALL_DEST/var/nginx-cache \
             $INSTALL_DEST/var/lizmap-theme-config \
             $INSTALL_DEST/var/lizmap-db \
             $INSTALL_DEST/var/lizmap-config \
             $INSTALL_DEST/var/lizmap-log \
             $INSTALL_DEST/var/lizmap-modules \
             $INSTALL_DEST/var/lizmap-my-packages
}

_makenv() {
    source $INSTALL_SOURCE/env.default
    if [ "$LIZMAP_CUSTOM_ENV" = "1" ]; then
        echo "Copying custom environment"
        cp $INSTALL_SOURCE/env.default $INSTALL_DEST/.env
    else
    LIZMAP_PROJECTS=${LIZMAP_PROJECTS:-"$LIZMAP_DIR/instances"}
    cat > $INSTALL_DEST/.env <<-EOF
		LIZMAP_PROJECTS=$LIZMAP_PROJECTS
		LIZMAP_DIR=$LIZMAP_DIR
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
    fi
}

_makepgservice() {
# Do NOT override existing pg_service.conf
if [ ! -e $INSTALL_DEST/etc/pg_service.conf ]; then
    cat > $INSTALL_DEST/etc/pg_service.conf <<-EOF
[lizmap_local]
host=$POSTGIS_ALIAS
port=5432
dbname=$POSTGRES_LIZMAP_DB
user=$POSTGRES_LIZMAP_USER
password=$POSTGRES_LIZMAP_PASSWORD
EOF
    chmod 0600 $INSTALL_DEST/etc/pg_service.conf
fi
}

_makelizmapprofiles() {
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
    chmod 0600 $INSTALL_DEST/etc/profiles.d/lizmap_local.ini.php
}


_install-plugin() {
    /src/install-lizmap-plugin.sh
}

_configure() {

    #
    # Create env file
    #
    echo "Creating env file"
    _makenv

    #
    # Copy configuration and create directories
    #
    echo "Copying files"
    cp -R $INSTALL_SOURCE/lizmap.dir/* $INSTALL_DEST/

    echo "Creating directories"
    _makedirs

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
    # Lizmap plugin
    #
    echo "Installing lizmap plugin"
    _install-plugin
}


configure() {
    echo "=== Configuring lizmap in $INSTALL_DEST"

    source $INSTALL_SOURCE/env.default

    docker run -it \
        -u $LIZMAP_UID:$LIZMAP_GID \
        --rm \
        -e INSTALL_SOURCE=/install \
        -e INSTALL_DEST=/lizmap \
        -e LIZMAP_DIR=$INSTALL_DEST \
        -e QGSRV_SERVER_PLUGINPATH=/lizmap/plugins \
        -v $INSTALL_SOURCE:/install \
        -v $INSTALL_DEST:/lizmap \
        -v $scriptdir:/src \
        --entrypoint /src/configure.sh \
        3liz/qgis-map-server:${QGIS_VERSION_TAG} _configure

    #
    # Copy docker-compose file but preserve ownership
    # for admin user
    #
    if [ "$COPY_COMPOSE_FILE" = "1" ]; then
        echo "Copying docker compose file"
        cp $INSTALL_SOURCE/docker-compose.yml $INSTALL_DEST/
    else
        rm -f $INSTALL_SOURCE/.env
        ln -s $INSTALL_DEST/.env $INSTALL_SOURCE/.env
    fi
}

_clean() {
    echo "Cleaning lizmap configs in '$INSTALL_DEST'"
    rm -rf $INSTALL_DEST/www/*
    rm -rf $INSTALL_DEST/var/*
    rm -rf $INSTALL_DEST/wps-data/*
    _makedirs
}

clean() {
    if [ -z $INSTALL_DEST ]; then
        echo "Invalid install directory"
        exit 1
    fi
    source $INSTALL_DEST/.env
    if [ "$LIZMAP_UID" != "$(id -u)" ]; then
        docker run -it \
            -u $LIZMAP_UID:$LIZMAP_GID \
            --rm \
            -e INSTALL_DEST=/lizmap \
            -v $INSTALL_DEST:/lizmap \
            -v $scriptdir:/src \
            --entrypoint /src/configure.sh \
            3liz/qgis-map-server:${QGIS_VERSION_TAG} _clean
     else
         _clean
     fi
}


"$@"
