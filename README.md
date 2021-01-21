# Run Lizmap stack with docker-compose

Run a complete Lizmap stack with test data. 

- lizmap web client
- Qgis server
- redis

**Note**: this is a sample configuration for testing Lizmap web client with Qgis and WPS features: 
if you want use it on a production server you will need to make adjustements for meeting 
your production requirements. 

## Requirements

- Docker engine
- docker-compose
- make (optional in Windows)

## Quick start

Execute those commands above for your system and open your browser at http://localhost:8090.
### Linux

In command shell execute:
```
make start
```

### Windows

In command powershell execute:

```
docker-compose --env-file .env.windows up
```

OR

If you use `make` (optional):
```
make start
```

## Running the first time

The command creates a docker-compose environnement and start the stack

The Lizmap service will start two toys projects that you will have to configure in the Lizmap
interface.

See the [Lizmap documentation](https://docs.lizmap.com) for how to configure Lizmap at first run.

Default login is `admin`, password `admin`. It will be asked to change it at first login.

## Reset the configuration

In command line

```
make clean 
```

This will remove all previous configuration. Youl will have to reenter the configuration in Lizmap
as for the first run.

For more informations, refer to the [docker-compose documentation](https://docs.docker.com/compose/)

Refs:
    - https://github.com/3liz/lizmap-web-client
    - https://github.com/3liz/py-qgis-server
    
    


