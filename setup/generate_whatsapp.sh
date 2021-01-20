#!/bin/bash

# generate whatsapp config
docker-compose up -d whatsapp

sleep 3

# copy configs to be edited
mkdir -p config/generated
docker cp matrix-whatsapp:/data/config.yaml config/generated/

# tear down containers
docker-compose stop whatsapp

echo
echo "Copy config/generated/config.yaml to config/config.yaml and make any desired modifications"
echo
