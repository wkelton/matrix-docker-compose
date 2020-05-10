#!/bin/bash

# initialize postgres
docker-compose up --no-start postgres
docker cp config/init.sql matrix-db:/docker-entrypoint-initdb.d
docker-compose up -d postgres

# wait on postgres initialization
echo "Waiting 15 seconds for postgres initialization to complete..."
timeout 15s docker-compose logs -f postgres

# remove postgres init script
docker-compose exec --user root postgres /bin/sh -c 'rm -f /docker-entrypoint-initdb.d/init.sql'
