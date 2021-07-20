# 
# Build lizmap installer image
# 

NAME=lizmap-installer-helper
VERSION=latest

LIZMAP_VERSION:=3.4
QGIS_VERSION:=3.16
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
	./entrypoint.sh configure
	@cp lizmap/.env ./
	@echo "Execute 'docker-compose up' to run lizmap"


clean:
	@INSTALL_DEST=$(INSTALL_DIR) \
	./entrypoint.sh clean

build-installer:
	docker build --rm \
		-t $(NAME):$(VERSION) \
		-t $(NAME):latest -f Dockerfile.installer .

# Test installation from installer
run-installer:
	mkdir -p $(INSTALL_DIR)
	docker run -it --rm --name lizmap-installer \
	-e LIZMAP_VERSION_TAG=$(LIZMAP_VERSION) \
	-e QGIS_VERSION_TAG=$(QGIS_VERSION) \
	-e POSTGIS_VERSION=$(POSTGIS_VERSION) \
	-e LIZMAP_INSTALL_DIR=$(INSTALL_DIR) \
	-v $(INSTALL_DIR):/lizmap \
	$(NAME):$(VERSION) configure



