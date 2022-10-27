# 
# Build lizmap installer image
# 

NAME=lizmap-installer-helper
VERSION=latest

LIZMAP_VERSION:=3.5
QGIS_VERSION:=3.22
POSTGIS_VERSION:=13-3

INSTALL_DIR:=$(shell pwd)/lizmap

configure:
	@mkdir -p $(INSTALL_DIR)
	@echo "Configuring environment"
	@INSTALL_DEST=$(INSTALL_DIR) \
	INSTALL_SOURCE=./ \
	LIZMAP_VERSION_TAG=$(LIZMAP_VERSION) \
	QGIS_VERSION_TAG=$(QGIS_VERSION) \
	POSTGIS_VERSION=$(POSTGIS_VERSION) \
	LIZMAP_INSTALL_DIR=$(INSTALL_DIR) \
	LIZMAP_PLUGIN_VERSION=$(LIZMAP_PLUGIN_VERSION) \
	./configure.sh configure
	@rm -f ./.env
	@ ln -sf  $(INSTALL_DIR)/.env
	@echo "Execute 'docker compose up' to run lizmap"


clean:
	@INSTALL_DEST=$(INSTALL_DIR) \
	./configure.sh clean


