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

# Fixed, forwardable web port (matches forwardPorts in devcontainer.json)
export LIZMAP_PORT=8090

if [ ! -f "$MARKER" ]; then
  echo "▶ Configuring Lizmap (first run, this happens only once)…"

  # configure.sh runs `docker run -it ...`; allocate a pseudo-TTY so it works in the
  # non-interactive Codespaces/CI shell (otherwise: "the input device is not a TTY").
  script -qefc "./configure.sh configure" /dev/null

  # Pin the web port to the forwarded one (env.default would otherwise bind 127.0.0.1:8090).
  sed -i 's#^LIZMAP_PORT=.*#LIZMAP_PORT=8090#' lizmap/.env

  # admin / admin, WITHOUT a forced password change — see docker-compose.codespaces.yml.
  printf 'admin' > lizmap/etc/admin.conf

  # Auto-register the two bundled demo projects so a working map shows up immediately,
  # instead of an empty admin panel. Paths are inside the container (projects -> /srv/projects).
  cat > lizmap/etc/lizmapconfig.d/codespaces-demo.ini.php <<'INI'
; Demo repositories auto-registered for the online test instance (GitHub Codespaces).
; Remove this file to start from an empty Lizmap.
[repository:demo]
label="Demo - QGIS info"
path="/srv/projects/qgis_info/"

[repository:france]
label="Demo - France parts"
path="/srv/projects/test_france_parts/"
INI

  touch "$MARKER"
fi

echo "▶ Pulling images (first run can take a few minutes)…"
$COMPOSE pull --quiet || true

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
      ('lizmap.repositories.view','__anonymous','france',0)
    ON CONFLICT DO NOTHING;" || echo "  (skipped — DB not ready yet, will retry next start)"

cat <<'EOF'

✅ Lizmap is starting on port 8090.
   Open the forwarded "Lizmap Web Client" URL (it opens automatically in Codespaces).
   Administrator login: admin  /  password: admin
EOF
