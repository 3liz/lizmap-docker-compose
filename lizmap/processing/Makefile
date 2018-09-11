
ifdef REGISTRY_URL
REGISTRY_PREFIX=$(REGISTRY_URL)/
endif

LOCAL_PORT:=127.0.0.1:8080

LOGSTORAGE:=DBLOG
REDIS_HOST:=192.168.0.6

run:
	docker run -it --rm -p $(LOCAL_PORT):8080 \
    -v $(shell pwd):/processing \
    -v $(shell pwd)/data:/projects \
    -v $(shell pwd)/.workdir:/srv/data \
    -e QYWPS_SERVER_PARALLELPROCESSES=2 \
    -e QYWPS_SERVER_LOGSTORAGE=$(LOGSTORAGE) \
    -e QYWPS_REDIS_HOST=$(REDIS_HOST) \
    -e QYWPS_PROCESSSING_PROVIDERS=lzmtest \
    -e QYWPS_PROCESSSING_PROVIDERS_MODULE_PATH=/processing \
    -e QYWPS_CACHE_ROOTDIR=/projects \
    -e QYWPS_SERVER_WORKDIR=/srv/data \
    -e QYWPS_USER=501:20 \
    qgis3-wps-service

