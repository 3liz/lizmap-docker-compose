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

