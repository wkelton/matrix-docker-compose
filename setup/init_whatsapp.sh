#!/bin/bash

# initialize whatsapp
docker-compose up --no-start whatsapp
docker cp config/config.yaml matrix-whatsapp:/data
docker-compose up -d whatsapp

sleep 2

docker-compose stop whatsapp
