FROM postgis/postgis:15-3.3

COPY init-lizmap-db.sh /docker-entrypoint-initdb.d/init-lizmap-db.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-lizmap-db.sh
