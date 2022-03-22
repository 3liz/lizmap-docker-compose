# vim: ft=dockerfile
#
# Lizmap configuration installer
# Copyright 2021 3liz 
#
FROM alpine:3
LABEL Maintainer="3Liz/David Marteau" Version="21.07.0"

RUN apk --update --no-cache add su-exec bash unzip wget
     
ENV INSTALL_DEST=/lizmap \
    INSTALL_SOURCE=/lizmap.install \
    COPY_COMPOSE_FILE=yes \
    LIZMAP_PLUGIN_VERSION=3.7.4

COPY entrypoint.sh env.default docker-compose.yml  /lizmap.install/
COPY lizmap.dir /lizmap.install/lizmap.dir

ENTRYPOINT ["/lizmap.install/entrypoint.sh"]

