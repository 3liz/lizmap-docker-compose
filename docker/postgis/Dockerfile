FROM 3liz/postgis:17-3

COPY init-lizmap-db.sh /docker-entrypoint-initdb.d/init-lizmap-db.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-lizmap-db.sh
