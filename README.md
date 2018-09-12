# Run Lizmap stack with docker-compose

Run a complete Lizmap stack with test data. 

## Quick start

In command shell execute:
```
./lizmap-run
```

and open your browser at http://localhost:8888

## Environment


The docker-compose.yml setup file will require to define the following
variables:

- `LIZMAP_DIR`: the directory to store your projects and configuraton files
- `LIZMAP_UID`: the uid used for running the service
- `LIZMAP_GID`: the gid used for runnnig the servige

Then run:
```
docker-compose up
```

For more informations, refer to the [docker-compose documentation](https://docs.docker.com/compose/)


