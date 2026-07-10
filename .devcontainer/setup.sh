#!/usr/bin/env bash
#
# Bootstrap a ready-to-use Lizmap instance inside a GitHub Codespace (or any dev container).
# Idempotent: the heavy one-time configuration runs once; every (re)start just brings the
# stack back up. Invoked by .devcontainer/devcontainer.json on create and on start.
#
set -euo pipefail

# Repository root (this script lives in .devcontainer/)
cd "$(dirname "$0")/.."

COMPOSE="docker compose -f docker-compose.yml -f .devcontainer/docker-compose.codespaces.yml"
MARKER="lizmap/.codespaces-configured"

# Fixed, forwardable ports (match forwardPorts in devcontainer.json)
export LIZMAP_PORT=8090    # Lizmap web UI
export POSTGIS_PORT=8093   # PostGIS, so QGIS Desktop can reach it via `gh codespace ports forward`

# The public HTTPS URL GitHub forwards this port to (e.g.
# https://<name>-8090.app.github.dev). Without this, Lizmap sees the tunnel's
# internal "Host: localhost:8090" and generates absolute URLs pointing there —
# notably the WebDAV base URL the QGIS plugin uses to push projects, which then
# tries to reach the tester's own "localhost:8090" instead of the Codespace and
# fails with an SSL handshake error. See docker-compose.codespaces.yml.
if [ -n "${CODESPACE_NAME:-}" ] && [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
  export LIZMAP_PROXYURL_DOMAIN="${CODESPACE_NAME}-${LIZMAP_PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
fi

# devcontainer.json's portsAttributes.visibility isn't reliably honored by Codespaces
# (see https://github.com/orgs/community/discussions/4068); set it imperatively too so
# testers can open the map without a GitHub login.
if [ -n "${CODESPACE_NAME:-}" ]; then
  echo "▶ Making port ${LIZMAP_PORT} public…"
  gh codespace ports visibility "${LIZMAP_PORT}:public" -c "$CODESPACE_NAME" \
    || echo "  (couldn't set port visibility automatically — set it manually in the Ports tab, or check the org's Codespaces port-privacy policy)"
fi

if [ ! -f "$MARKER" ]; then
  echo "▶ Configuring Lizmap (first run, this happens only once)…"

  # configure.sh runs `docker run -it ...`; allocate a pseudo-TTY so it works in the
  # non-interactive Codespaces/CI shell (otherwise: "the input device is not a TTY").
  script -qefc "./configure.sh configure" /dev/null

  # Pin the forwarded ports (env.default would otherwise bind them to 127.0.0.1).
  sed -i 's#^LIZMAP_PORT=.*#LIZMAP_PORT=8090#'   lizmap/.env
  sed -i 's#^POSTGIS_PORT=.*#POSTGIS_PORT=8093#' lizmap/.env

  # admin / admin, WITHOUT a forced password change — see docker-compose.codespaces.yml.
  printf 'admin' > lizmap/etc/admin.conf

  # An empty, writable repository where testers drop their own project (see PUBLISH.md).
  mkdir -p lizmap/instances/myprojects

  # Auto-register the two bundled demo projects (so a working map shows up immediately
  # instead of an empty admin panel) plus the empty "My projects" repository. Paths are
  # inside the container (projects -> /srv/projects).
  cat > lizmap/etc/lizmapconfig.d/codespaces-demo.ini.php <<'INI'
; Repositories auto-registered for the online test instance (GitHub Codespaces).
; Remove this file to start from an empty Lizmap.
[repository:demo]
label="Demo - QGIS info"
path="/srv/projects/qgis_info/"

[repository:france]
label="Demo - France parts"
path="/srv/projects/test_france_parts/"

[repository:myprojects]
label="My projects"
path="/srv/projects/myprojects/"
INI

  echo "▶ Pulling images (first run can take a few minutes)…"
  $COMPOSE pull --quiet || true

  touch "$MARKER"
fi

echo "▶ Starting the Lizmap stack (waiting for healthchecks)…"
$COMPOSE up -d --wait

# Grant the "view" right on the demo repositories to anonymous visitors, so the maps are
# visible without logging in. The admin UI does this automatically when a repository is
# created there, but config-only creation (our drop-in) does not. Idempotent.
echo "▶ Granting anonymous access to the demo maps…"
# shellcheck disable=SC1091
source lizmap/.env
$COMPOSE exec -T postgis psql -v ON_ERROR_STOP=1 \
  -U "${POSTGRES_LIZMAP_USER:-lizmap}" -d "${POSTGRES_LIZMAP_DB:-lizmap}" -c "
    INSERT INTO lizmap.jacl2_rights (id_aclsbj, id_aclgrp, id_aclres, canceled) VALUES
      ('lizmap.repositories.view','__anonymous','demo',0),
      ('lizmap.repositories.view','__anonymous','france',0),
      ('lizmap.repositories.view','__anonymous','myprojects',0)
    ON CONFLICT DO NOTHING;" || echo "  (skipped — DB not ready yet, will retry next start)"

# Grant admins the rights to view the repositories and use the WMS links, edition and
# vector export tools, so an admin isn't limited to what anonymous visitors can do.
# Same drop-in-config gap as above (the admin UI would set this when creating a
# repository there). Idempotent.
echo "▶ Granting admins full tool access to the demo maps…"
$COMPOSE exec -T postgis psql -v ON_ERROR_STOP=1 \
  -U "${POSTGRES_LIZMAP_USER:-lizmap}" -d "${POSTGRES_LIZMAP_DB:-lizmap}" -c "
    INSERT INTO lizmap.jacl2_rights (id_aclsbj, id_aclgrp, id_aclres, canceled) VALUES
      ('lizmap.repositories.view','admins','demo',0),
      ('lizmap.repositories.view','admins','france',0),
      ('lizmap.repositories.view','admins','myprojects',0),
      ('lizmap.tools.displayGetCapabilitiesLinks','admins','demo',0),
      ('lizmap.tools.displayGetCapabilitiesLinks','admins','france',0),
      ('lizmap.tools.displayGetCapabilitiesLinks','admins','myprojects',0),
      ('lizmap.tools.edition.use','admins','demo',0),
      ('lizmap.tools.edition.use','admins','france',0),
      ('lizmap.tools.edition.use','admins','myprojects',0),
      ('lizmap.tools.layer.export','admins','demo',0),
      ('lizmap.tools.layer.export','admins','france',0),
      ('lizmap.tools.layer.export','admins','myprojects',0)
    ON CONFLICT DO NOTHING;" || echo "  (skipped — DB not ready yet, will retry next start)"

# Since PostgreSQL 15, the "public" schema no longer grants CREATE to everyone by
# default — only its owner (the bootstrap superuser) does. Testers connecting from
# QGIS as the "lizmap" role would hit "permission denied for schema public" the moment
# they try to create a table there. Restore the pre-15, friendlier default for this
# single-user sandbox (run as the postgres superuser, since lizmap doesn't own "public").
echo "▶ Allowing the lizmap user to create tables in the public schema…"
$COMPOSE exec -T postgis psql -v ON_ERROR_STOP=1 -U postgres -d "${POSTGRES_LIZMAP_DB:-lizmap}" \
  -c "GRANT CREATE, USAGE ON SCHEMA public TO \"${POSTGRES_LIZMAP_USER:-lizmap}\";" \
  || echo "  (skipped — DB not ready yet, will retry next start)"

cat <<'EOF'

✅ Lizmap is starting on port 8090.
   Open the forwarded "Lizmap Web Client" URL (it opens automatically in Codespaces).
   Administrator login: admin  /  password: admin
EOF
