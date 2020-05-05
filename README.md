# matrix-docker-compose

Docker compose managed Synapse home server with Postgres and Riot.

## Docker Images
* Synapse and Coturn: [avhost/docker-matrix](https://hub.docker.com/r/avhost/docker-matrix)
* Postgres: [postgres](https://hub.docker.com/_/postgres)
* Riot: [vectorim/riot-web](https://hub.docker.com/r/vectorim/riot-web)
* Volume provisioner: [hasnat/volumes-provisioner](https://hub.docker.com/r/hasnat/volumes-provisioner)

## Requirements
* Docker
* docker-compose
* A reverse proxy
* Python 3 (for admin scripts)

## Reverse Proxy
You will need to have a reverse proxy setup. I use a variant of [jwilder/nginx-proxy](https://github.com/nginx-proxy/nginx-proxy).

Assuming you have some base domain, domain.com, and you want the matrix client to use matrix.domain.com and Riot to be at riot.domain.com, you will need the following from your reverse proxy:
* Listen on 443 for matrix.domain.com and forward to the Synapse container (name: matrix-synapse) at port 8008
* Listen on 8448 for domain.com and forward to the Synapse container (name: matrix-synapse) at port 8008
* Listen on 443 for riot.domain.com and forward to the Riot container (name: matrix-riot) at port 80

See [docs/reverse_proxy](https://github.com/matrix-org/synapse/blob/master/docs/reverse_proxy.md) for Synapse docs on reverse proxying.

## Initial Setup
### Configuration
1. Configure env files
   1. Copy `samples/env` to `.env` and set desired values
   2. Copy `samples/{postgres|synapse|riot}.env` files to top level directory and set desired values
2. Configure postgres synapse user
   1. Copy `samples/init.sql` to `config/init.sql`
   2. Add postrgres synapse user password in `config/init.sql`
3. Configure Riot
   1. Copy `samples/config.json` to `config/config.json`
   2. Change desired settings
4. Run `setup/generate.sh`
5. Configure Synapse
   1. Copy `config/generated/homeserver.yaml` to `config/homeserver.yaml`
   2. Configure `database` section
   3. Make other desired changes (see sample)
6. Configure Coturn
   1. Copy `config/generated/turnserver.conf` to `config/turnserver.conf`
   2. Add `min-port=49152` and `max-port=49300` or desired range
   3. Be sure to update the port ranges in `docker-compose.yml` if you change these values
   4. Make other desired changes to `config/turnserver.conf`

### Initialize
1. Run `setup/init.sh`
2. Run `docker-compose up -d`

### Create Admin User
1. Register your user
2. Make user an admin:
   1. `docker-compose exec postgres bash`
   2. `psql -U postgress`
   3. `\c synapse`
   4. `UPDATE users SET admin = 1 WHERE name = '@foo:bar.com'`

## Configuration Examples

The following are the settings I have changed from the generated homeserver config.

* `public_baseurl: https://matrix.domain.com/`
* Keys under `Listeners` and value `port: 8008`:
  * `bind_addresses: ['0.0.0.0']`
* `admin_contact: 'mailto:email@email.email'`
* Keys under `database`:
  * `name: psycopg2`
  * Keys under `args`:
    * `user: synapse`
    * `password: "changethisbadpassword"`
    * `database: synapse`
    * `host: postgres`
    * `cp_min: 5`
    * `cp_max: 10`
* `enable_registration: true`
  * This enables registration from your Riot client; set to `false` if you want to disable.
* Values under `registrations_require_3pid`:
  * `- email`
* `disable_msisdn_registration: true`
* `enable_3pid_lookup: true`
* Keys under `email`:
  * `smtp_host: smtp.gmail.com`
  * `smtp_port: 587`
  * `smtp_user: "email@gmail.com"`
  * `smtp_pass: "gmailpassword"`
  * `require_transport_security: true`
  * `notif_from: "%(app)s Homeserver <email@gmail.com>"`
  * `app_name: "whatever"`
  * `enable_notifs: true`
  * `client_base_url: "https://riot.domain.com"`
* Keys under `push`:
  * `include_content: true`
* Keys under `server_notices`:
  * `system_mxid_localpart: notices`
  * `system_mxid_display_name: "Server Notices"`
  * `room_name: "Server Notices"`

## Synapse Admin API
`adm/synapseadm` provides a convient command line wrapper around curling the Synapse admin API. This is written with Python 3.

Run `adm/synapseadm --help` to see available commands.

See [docs/admin_api](https://github.com/matrix-org/synapse/tree/master/docs/admin_api) for additional Synapse admin API.

## Reference

### Synapse Docs
* Synapse docs: [synapse](https://github.com/matrix-org/synapse/blob/master/README.rst)
* Generating `homeserver.yaml`: [synapse/docker](https://github.com/matrix-org/synapse/tree/master/docker)
* Postgres settings: [docs/postgres](https://github.com/matrix-org/synapse/blob/master/docs/postgres.md)
* Federation
  * [docs/federate](https://github.com/matrix-org/synapse/blob/master/docs/federate.md)
  * [test federation](https://federationtester.matrix.org/)
* Email settings: [synapse/install](https://github.com/matrix-org/synapse/blob/master/INSTALL.md#email)
* Reverse proxy: [docs/reverse_proxy](https://github.com/matrix-org/synapse/blob/master/docs/reverse_proxy.md)
* TURN
  - [docs/turn-howto](https://github.com/matrix-org/synapse/blob/master/docs/turn-howto.md)
  - [avhost/example](https://github.com/AVENTER-UG/docker-matrix/blob/master/Example.configs.md)
* Synapse Admin API: [docs/admin_api](https://github.com/matrix-org/synapse/tree/master/docs/admin_api)
* Matrix [FAQ](https://matrix.org/faq/#self-hosting)
* Matrix [API](https://matrix.org/docs/spec/client_server/latest#get-well-known-matrix-client)

### Riot Docs
* Riot docs: [riot](https://github.com/vector-im/riot-web)
* Configuration: [docs/config](https://github.com/vector-im/riot-web/blob/develop/docs/config.md)
* Key backup:
  * [Serverfault - Where is the Riot keybackup stored?](https://serverfault.com/questions/984095/where-is-the-riot-keybackup-stored-chat-riot-matix-synapse)
  * [Storing megolm keys serverside](https://github.com/uhoreg/matrix-doc/blob/e2e_backup/proposals/1219-storing-megolm-keys-serverside.md)

### General Docs
* Used for inspiration
  * [Setting up Matrix and Riot with docker](https://zerowidthjoiner.net/2020/03/20/setting-up-matrix-and-riot-with-docker)
  * [Running a personal Matrix server using docker](https://zingmars.info/2019/12/29/Running-a-personal-Matrix-server-using-docker)

