#!/bin/bash

setup_dir=$(dirname "${BASH_SOURCE[0]}")

# create synapse contianer
docker-compose up synapse_volume_provisioner
docker-compose up --no-start synapse

# initialize postgres
"${setup_dir}/init_postgres.sh"

echo
echo "Postgres initialized and running."
echo "Synapse container created and volume provisioned."
echo
