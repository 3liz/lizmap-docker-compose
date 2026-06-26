# Publish your own QGIS project to your online Lizmap

This guide is for the one-click [GitHub Codespaces](README.md#-try-lizmap-online-in-one-click-no-install)
test instance. It explains how to author a QGIS project on your computer and publish it to
*your* online Lizmap, including the case where your data lives in the bundled PostGIS database.

Your Codespace ships with an empty **My projects** repository ready to receive your project.

## Prerequisites (on your computer)

- [QGIS Desktop](https://qgis.org) with the **Lizmap** plugin installed.
- The **GitHub CLI** [`gh`](https://cli.github.com), logged in (`gh auth login`). It is the
  bridge between your computer and the Codespace — no public ports, no extra password.

> Find your running Codespace with `gh codespace list`. The commands below will let you pick it
> interactively, or you can pass `-c <codespace-name>`.

## Step 1 — Make your data reachable by the server

### Option A — file-based data (simplest)
If your layers are in a **GeoPackage** (or Shapefile…), just keep the data file in the **same
folder** as your `.qgs` and use **relative paths** in QGIS. Nothing else to do — QGIS Server reads
the file directly. Skip to step 2.

### Option B — data in PostGIS
The stack already runs a PostGIS database; QGIS Server reads it through the pg_service
named **`lizmap_local`**. The trick is to use that **same service name** on your desktop, so the
exact same `.qgs` works on your machine *and* on the server with no edit.

1. **Open a tunnel** to the Codespace database (leave it running in a terminal):
   ```bash
   gh codespace ports forward 8093:5432
   ```
   PostGIS is now reachable at `localhost:8093` on your machine.

2. **Declare the `lizmap_local` service** on your computer. Add this to your pg_service file
   (`~/.pg_service.conf` on Linux/macOS, `%APPDATA%\postgresql\.pg_service.conf` on Windows):
   ```ini
   [lizmap_local]
   host=localhost
   port=8093
   dbname=lizmap
   user=lizmap
   password=lizmap1234!
   ```

3. In QGIS → **Data Source Manager → PostgreSQL → New**, set **Service = `lizmap_local`**
   (leave Host/Port empty) and *Test Connection*. Using the Service field is what makes QGIS write
   `service='lizmap_local'` into the project instead of a hard-coded host — essential for the
   project to resolve on the server.

4. **Load your data** into the database (schema `lizmap`, or create your own). For example with
   QGIS *DB Manager* (Import layer), or from a terminal:
   ```bash
   ogr2ogr -f PostgreSQL "PG:service=lizmap_local" my_data.gpkg -lco SCHEMA=lizmap
   ```

5. Build your map in QGIS from those PostGIS layers. Double-check (layer → Properties → Source)
   that the datasource starts with `service='lizmap_local'`.

## Step 2 — Configure the map with the Lizmap plugin

In QGIS, open the **Lizmap** plugin, configure your map (base layers, popups, tools…), and click
**Save**. It writes a `myproject.qgs.cfg` file next to your `myproject.qgs`.

## Step 3 — Send the project to your Codespace

Copy the project files into the **My projects** repository folder of the Codespace
(`lizmap/instances/myprojects/`). Two equivalent ways:

- **With `gh`** (from the folder containing your project):
  ```bash
  gh codespace cp ./myproject.qgs ./myproject.qgs.cfg \
    'remote:/workspaces/lizmap-docker-compose/lizmap/instances/myprojects/'
  ```
  Add your GeoPackage / data files too if you used Option A.

- **Or drag-and-drop**: in the Codespace's VS Code window, drop the files into the
  Explorer under `lizmap/instances/myprojects/`.

## Step 4 — Open it

Go to your Lizmap URL — the **My projects** repository now lists `myproject`. 🎉

---

### Notes & troubleshooting
- **Project not listed / "repository path" error**: the file must be directly under
  `lizmap/instances/myprojects/` and named `*.qgs` with its `*.qgs.cfg` beside it.
- **Layers fail to load on the server but work locally**: the datasource is probably hard-coded to
  `localhost:8093` instead of `service='lizmap_local'`. Re-add the PostGIS connection using the
  **Service** field (step 1B.3) and re-save the project.
- **Visibility**: *My projects* is viewable by anonymous visitors by default (like the demos), so
  you can share the map link. Change it in **Admin → Maps** if you prefer it private.
- **Lifetime**: everything (files and PostGIS data) lives inside your Codespace and is removed when
  the Codespace is deleted. This instance is meant for evaluation, not production.
