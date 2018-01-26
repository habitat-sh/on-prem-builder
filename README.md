# On Prem Habitat Builder

:construction: THIS IS NOT FOR PRODUCTION USE :construction:

## Pre-Requisites

### GitHub OAuth Application

1. Create a GitHub Organization
1. [Setup a GitHub application](https://github.com/settings/apps/new) for your GitHub organization.
1. Set the value of `Homepage URL` to `http://${APP_HOSTNAME_OR_IP}`
1. Set the value of `User authorization callback URL` to `http://${APP_HOSTNAME_OR_IP}/` (The trailing `/` is *important*)
1. Set the value of `Webhook URL` to `http://${APP_HOSTNAME_OR_IP}/`
1. Set everything to read only (this is only used for your org so it's safe)
1. Save and download the pem key
1. Copy the pem key to `${SRC_ROOT}/.secrets/builder-github-app.pem`
1. Record the the client-id, client-secret and app_id. These will be used for the `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET` and `GITHUP_APP_ID` build variables (seen below).

## Setup

1. Clone this repo to the desired machine to stand up builder
1. `cd ${SRC_ROOT}`
1. `cp bldr.env.sample bldr.env`
1. Edit `bldr.env` with a text editor and replace the values for the `APP_HOSTNAME`, `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, and `GITHUB_APP_ID` environment variables
1. `sudo ./install.sh`

## Web UI

Nagigate to http://${APP_HOSTNAME_OR_IP}/#/sign-in to access the Builder UI

## Debug Logging

1. `cd ${SRC_ROOT}`
1. for svc in originsrv api sessionsrv; do echo 'log_level="debug"' | hab config apply "builder-${svc}.default" $(date +%s) ; done
1. journalctl -fu hab-sup
