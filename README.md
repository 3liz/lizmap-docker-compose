# Run Lizmap stack with docker-compose

Run a complete Lizmap stack with test data. 

- Lizmap Web Client
- QGIS Server with Py-QGIS-Server
- PostgreSQL with PostGIS
- Redis

**Note**: this is a sample configuration for testing Lizmap web client with QGIS and WPS features.

❗**If you want to use it on a production server, you will need to make adjustments to meet your
production requirements.**

## 🚀 Try Lizmap online in one click (no install)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/3liz/lizmap-docker-compose)

Want to test Lizmap without installing anything? Click the badge above (a free
GitHub account is enough). GitHub Codespaces starts the whole stack for you and opens
Lizmap in your browser after a few minutes — with two demo maps already loaded.

- **Administrator login:** `admin` — **password:** `admin`
- Free within GitHub's [Codespaces free tier](https://github.com/features/codespaces)
  (60 hours/month). Your instance is private to you and keeps its state for a few weeks
  (it suspends when idle and resumes on demand).
- Everything runs in *your* Codespace, reachable at the URL Codespaces gives you
  (`https://<your-codespace>-8090.app.github.dev`) — there is no shared server.

Want to **publish your own QGIS project** (including data stored in the PostGIS database)?
See **[PUBLISH.md](PUBLISH.md)**.

This is meant for evaluation/testing. For production, use the `docker compose` setup below.

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

## WebDAV module

The stack ships with the [Lizmap WebDAV module](https://github.com/3liz/lizmap-webdav-module)
declared in `lizmap.dir/var/lizmap-my-packages/composer.json`, ready to be installed and
activated with no manual step — but it is **opt-in** for a plain local stack, and **on by
default** for the "Open in GitHub Codespaces" online demo.

- **GitHub Codespaces**: enabled automatically (see `LIZMAP_ENABLE_EXTRA_MODULES` in
  `.devcontainer/docker-compose.codespaces.yml`). Once the Codespace is up, browse projects over
  WebDAV at `<your-codespace-url>/dav.php/` (basic auth, same credentials as the Lizmap admin
  account).
- **Local `docker compose up`**: disabled by default. To turn it on, set
  `LIZMAP_ENABLE_EXTRA_MODULES=1` before starting the stack, e.g. add it to `lizmap/.env` or run:
  ```bash
  LIZMAP_ENABLE_EXTRA_MODULES=1 docker compose up -d
  ```
  Then browse WebDAV at `http://localhost:8090/dav.php/`.

Under the hood, the `lizmap` container's entrypoint is wrapped by `lizmap.dir/etc/module-init.sh`.
When `LIZMAP_ENABLE_EXTRA_MODULES=1`, it runs `composer install` on `var/lizmap-my-packages` and
configures any newly installed module before starting Lizmap normally. This runs on every
container start and is a no-op once everything is already installed/configured, so it adds no
noticeable overhead after the first run. When the variable is unset, the script does nothing and
Lizmap starts exactly as before.

To add another module the same way, add it to `lizmap.dir/var/lizmap-my-packages/composer.json`
(and update `composer.lock`, e.g. with
`docker compose exec lizmap composer update --working-dir=/www/lizmap/my-packages`) — it will be
installed and configured automatically the next time the stack starts with
`LIZMAP_ENABLE_EXTRA_MODULES=1`.

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
