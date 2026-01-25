# matrix-docker-compose

Docker compose managed Synapse home server with Postgres and Riot.

## Docker Images
* Synapse and Coturn: [avhost/docker-matrix](https://hub.docker.com/r/avhost/docker-matrix)
* Postgres: [postgres](https://hub.docker.com/_/postgres)
* Element: [vectorim/element-web](https://hub.docker.com/r/vectorim/element-web)
* Volume provisioner: [hasnat/volumes-provisioner](https://hub.docker.com/r/hasnat/volumes-provisioner)

## Requirements
* Docker
* docker-compose
* A reverse proxy
* Python 3 (for admin scripts)

## Reverse Proxy
You will need to have a reverse proxy setup. I use a variant of [jwilder/nginx-proxy](https://github.com/nginx-proxy/nginx-proxy).

Assuming you have some base domain, domain.com, and you want the matrix client to use matrix.domain.com and Element to be at element.domain.com, you will need the following from your reverse proxy:
* Listen on 443 for matrix.domain.com and forward to the Synapse container (name: matrix-synapse) at port 8008
* Listen on 8448 for domain.com and forward to the Synapse container (name: matrix-synapse) at port 8008
* Listen on 443 for element.domain.com and forward to the Riot container (name: matrix-element) at port 80

See [docs/reverse_proxy](https://github.com/matrix-org/synapse/blob/master/docs/reverse_proxy.md) for Synapse docs on reverse proxying.

## Initial Setup
### Configuration
1. Configure env files
   1. Copy `samples/env` to `.env` and set desired values
   2. Copy `samples/{postgres|synapse|element}.env` files to top level directory and set desired values
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
6. Configure Coturn - DEPRECATED
   1. Copy `config/generated/turnserver.conf` to `config/turnserver.conf`
   2. Add `min-port=49152` and `max-port=49300` or desired range
   3. Be sure to update the port ranges in `docker-compose.yml` if you change these values
   4. Make other desired changes to `config/turnserver.conf`

Coturn is deprecated in the avhost/docker-matrix image. So, I added a coturn as a separate container in this compose file. The idea is to use the same settings file and move needed ports to this container.

### Element Call
This docker compose has containers to support Element Call. But, it seems Element Call is still under development and how to setup may change. To get propery support there are several details you must get correct. This is a general overview of the steps. See the links below about Element Call for better information.

* Enable Synapse experimental features and settings:
```
experimental_features:
  # MSC3266: Room summary API. Used for knocking over federation
  msc3266_enabled: true
  # MSC4222 needed for syncv2 state_after. This allow clients to
  # correctly track the state of the room.
  msc4222_enabled: true

# The maximum allowed duration by which sent events can be delayed, as
# per MSC4140.
max_event_delay_duration: 24h

rc_message:
  # This needs to match at least e2ee key sharing frequency plus a bit of headroom
  # Note key sharing events are bursty
  per_second: 0.5
  burst_count: 30

rc_delayed_event_mgmt:
  # This needs to match at least the heart-beat frequency plus a bit of headroom
  # Currently the heart-beat is every 5 seconds which translates into a rate of 0.2s
  per_second: 1
  burst_count: 20
```
* Reverse proxy livekit jwt and sfu. This can be done with path based routing (like described in the self-hosting docs) or separate sub-domains.
* Respond to .well-known on your base domain to indicate that you support element call:
```
"org.matrix.msc4143.rtc_foci": [
    {
        "type": "livekit",
        "livekit_service_url": "https://matrix-rtc.example.com/livekit/jwt"
    }
]
```
* There may be other settings required in this .well-known, see self-hosting docs.
* Create livekit configuration in `config/livekit.conf`, with something like:
```
port: 7880 # Port LiveKit listens on internally
bind_addresses:
  - "0.0.0.0" # Listen on all interfaces within the container

rtc:
  tcp_port: 7881
  port_range_start: 50100 # Match docker-compose port range
  port_range_end: 50200   # Match docker-compose port range
  use_external_ip: false # Rely on reverse proxy/NAT

  # if you want to use coturn instead of the built in turn server:
  turn_servers:
    - host: turnserver.mydomain.com
      port: 3478
      protocol: tcp
      secret: ""
    - host: turnserver.mydomain.com
      port: 3478
      protocol: udp
      secret: ""

logging:
  level: info

# Disable LiveKit's internal TURN server - using coturn instead
turn:
  enabled: false
```
* Create `livekit.env` with LIVEKIT_KEYS:
```
LIVEKIT_KEYS="livekit: somesecret"
```
* Create `livekit-jwt.env` with these settings:
```
# Publicly accessible URL for the LiveKit SFU WebSocket endpoint (updated domain)
LIVEKIT_URL=wss://matrixrtc.server.tld/livekit/sfu
# API Key and Secret (must match LiveKit service and secrets)
LIVEKIT_KEY=livekit
LIVEKIT_SECRET=somesecret
# Optional: Restrict call creation to users from specific homeservers
LIVEKIT_FULL_ACCESS_HOMESERVERS=server.tld

```

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
  * `client_base_url: "https://element.domain.com"`
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

### Element Docs
* Element docs: [element](https://github.com/vector-im/element-web)
* Configuration: [docs/config](https://github.com/vector-im/element-web/blob/develop/docs/config.md)
* Key backup:
  * [Serverfault - Where is the Riot keybackup stored?](https://serverfault.com/questions/984095/where-is-the-riot-keybackup-stored-chat-riot-matix-synapse)
  * [Storing megolm keys serverside](https://github.com/uhoreg/matrix-doc/blob/e2e_backup/proposals/1219-storing-megolm-keys-serverside.md)

### Element Call
* Self-hosting: [self-hosting](https://github.com/element-hq/element-call/blob/livekit/docs/self-hosting.md)
* Blog walkthrough: [deploy-element-call](https://willlewis.co.uk/blog/posts/deploy-element-call-backend-with-synapse-and-docker-compose/)
* WebRTC explainer: [WebRTC TURN](https://bloggeek.me/webrtc-turn/)

### General Docs
* Used for inspiration
  * [Setting up Matrix and Riot with docker](https://zerowidthjoiner.net/2020/03/20/setting-up-matrix-and-riot-with-docker)
  * [Running a personal Matrix server using docker](https://zingmars.info/2019/12/29/Running-a-personal-Matrix-server-using-docker)

