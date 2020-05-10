#!/bin/bash

setup_dir=$(dirname "${BASH_SOURCE[0]}")

# source .env to get user/group settings
source "${setup_dir}/../.env"

# copy configs
docker-compose up synapse_volume_provisioner
docker cp config/homeserver.yaml matrix-synapse-volume-provisioner:/data
docker cp config/turnserver.conf matrix-synapse-volume-provisioner:/data

docker-compose run --entrypoint \
    "/bin/sh -c 'chown ${SYNAPSE_USER}:${SYNAPSE_GROUP} /data/homeserver.yaml /data/turnserver.conf'" \
    synapse_volume_provisioner
