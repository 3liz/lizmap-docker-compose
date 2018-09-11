#

export LIZMAP_DIR=$(shell pwd)/lizmap
export LIZMAP_USER_ID:=$(shell id -u)
export LIZMAP_USER_GID:=$(shell id -g)

run:
	docker-compose rm || true
	docker-compose up

rm: 
	docker-compose rm

clean:
	rm -rf $(LIZMAP_DIR)/www/*
	rm -rf $(LIZMAP_DIR)/var/*
	rm -rf $(LIZMAP_DIR)/wps-data/*

