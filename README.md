# Run Lizmap stack with docker-compose

Run a complete Lizmap stack with test data. 

- Lizmap Web Client
- QGIS Server with Py-QGIS-Server
- PostgreSQL with PostGIS
- Redis

**Note**: this is a sample configuration for testing Lizmap web client with QGIS and WPS features.

❗**If you want to use it on a production server, you will need to make adjustments to meet your
production requirements.**

## Requirements

- Docker Engine also knonw as Docker CE
- Docker Compose plugin

We recommend to use the docker's repository https://docs.docker.com/engine/install/

## Quick start

Execute the commands below for your system and open your browser at http://localhost:8090.

### Linux

In a shell, configure the environment:
```bash
./configure.sh configure
```
Or if you want to test specific version (here last 3.X.Y version):
```bash
LIZMAP_VERSION_TAG=3.9 ./configure.sh configure
```

Run the stack:
```bash
docker compose pull
docker compose up -d
```

To run lizmap visible to another system, prefix the docker command with a variable. NB! This will be plain HTTP with no encryption and not suitable for production.
```bash
LIZMAP_PORT=EXTERNAL_IP_HERE:80 docker compose up
```

### Windows

In order to user Docker on Windows you may install [Docker desktop for Windows](https://docs.docker.com/desktop/windows/install/)


If you have some distribution installed (Ubuntu, ...) in WSL, you can simply run the linux command as above, once in it.

Or in PowerShell, run the following command to set up some files
```bash
configure.bat
``` 
You can then launch the docker using
```bash
docker compose --env-file .env.windows up
```
Or if you want to test specific version, you can edit `.env.windows` and change (here last 3.X.Y version):

```bash
LIZMAP_VERSION_TAG=3.9
```

## Running the first time

The previous commands create a docker-compose environment and run the stack

The Lizmap service will start two toys projects that you will have to configure in the Lizmap
interface.

See the [Lizmap documentation](https://docs.lizmap.com) for how to configure Lizmap at first run.

Default login is `admin`, password `admin`. It will be asked to change it at first login.

## Add your own project

You need to :
* create a directory in `lizmap/instances`
* visit http://localhost:8090/admin.php/admin/maps/
* in the Lizmap admin panel, add the directory you created
* add one or more QGIS projects with the Lizmap CFG file in the directory

## Update versions

To update versions simply update your `.env` file.

```bash
LIZMAP_VERSION_TAG=3.8
QGIS_VERSION_TAG=3.40
POSTGIS_VERSION=13-3
```

Find the **list of available docker images versions** available, in the Docker Hub tag page of each image :

| Image name | Dockerhub image | Env variable related |
| ------------ | ------ | ---- |
| **3liz/lizmap-web-client** | [hub.docker.com/r/3liz/lizmap-web-client](https://hub.docker.com/r/3liz/lizmap-web-client/tags) | `LIZMAP_VERSION_TAG` |
| **3liz/qgis-map-server** | [hub.docker.com/r/3liz/qgis-map-server](https://hub.docker.com/r/3liz/qgis-map-server/tags) | `QGIS_VERSION_TAG` |
| **3liz/postgis** | [hub.docker.com/r/3liz/postgis](https://hub.docker.com/r/3liz/postgis/tags) | `POSTGIS_VERSION` |

Once updated, simply **run the following command**

``` bash
docker compose up -d
```

This one will **pull the new images**, and update your instance versions.

#### *NB :* You might face `The lizmap_server plugin needs to be updated` error (see [#68](https://github.com/3liz/lizmap-docker-compose/issues/68))

To fix this issue :
1. Connect to your lizmap container.
``` bash
docker compose exec map bash
```

2. Move to your qgis server plugins folder 
``` bash
cd /srv/plugins
qgis-plugin-manager list
qgis-plugin-manager update
qgis-plugin-manager upgrade
```

More info about qgis-plugin-manager [here](https://github.com/3liz/qgis-plugin-manager)

3. Exit from your container and restart lizmap container to handle new changes
``` bash
exit
docker compose restart map
```

## Reset the configuration

In command line

```bash
./configure.sh  clean 
```

This will remove all previous configuration. You will have to reenter the configuration in Lizmap
as for the first run.

## References

For more information, refer to the [docker-compose documentation](https://docs.docker.com/compose/)

See also:

- https://github.com/3liz/lizmap-web-client
- https://github.com/3liz/py-qgis-server

Docker on Windows:

- https://docs.docker.com/desktop/windows/
- https://docs.microsoft.com/fr-fr/windows/dev-environment/docker/overview
