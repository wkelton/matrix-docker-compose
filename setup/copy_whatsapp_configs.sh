#!/bin/bash

setup_dir=$(dirname "${BASH_SOURCE[0]}")

# copy configs
docker-compose up --no-start whatsapp
docker cp config/config.yaml matrix-whatsapp:/data
docker cp config/registration.yaml matrix-whatsapp:/data

docker-compose up -d whatsapp
