#!/bin/bash

# generate synapse config
docker-compose run --rm synapse generate

# copy configs to be edited
mkdir -p config/generated
docker cp synapse-volume-provisioner:/data/homeserver.yaml config/generated/
docker cp synapse-volume-provisioner:/data/turnserver.conf config/generated/

# tear down containers
docker-compose down

echo
echo "Copy config/generated/homeserver.yaml to config/homeserver.yaml and make any desired modifications"
echo "Copy config/generated/turnserver.conf to config/turnserver.conf and make any desired modifications"
echo
