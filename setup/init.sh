#!/bin/bash

# source .env to get user/group settings
source .env

# initialize postgres
docker-compose up --no-start postgres
docker cp config/init.sql matrix-db:/docker-entrypoint-initdb.d
docker-compose up -d postgres

# copy configs
docker-compose up synapse_volume_provisioner
docker cp config/homeserver.yaml matrix-synapse-volume-provisioner:/data
docker cp config/turnserver.conf matrix-synapse-volume-provisioner:/data

docker-compose run --entrypoint "/bin/sh -c 'chown ${SYNAPSE_USER}:${SYNAPSE_GROUP} /data/homeserver.yaml /data/turnserver.conf'" synapse_volume_provisioner

# wait on postgres initialization
echo "Waiting 15 seconds for postgres initialization to complete..."
timeout 15s docker-compose logs -f postgres

# remove postgres init script
docker-compose exec --user root postgres /bin/sh -c 'rm -f /docker-entrypoint-initdb.d/init.sql'

# tear down containers
docker-compose down

echo
echo "Initialization complete. When ready, run: docker-compose up -d"
echo
