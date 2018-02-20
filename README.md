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
1. `for svc in originsrv api sessionsrv; do echo 'log_level="debug"' | hab config apply "builder-${svc}.default" $(date +%s) ; done`
1. `journalctl -fu hab-sup`

## Adding an initial set of packages

1. If you'd like to bootstrap your depot with the latest set of stable packages
   from the [core-plans repo](https://github.com/habitat-sh/on-prem-builder.git), there's a script for that.
1. Export a valid GitHub personal authentication token as `HAB_AUTH_TOKEN` in
   your environment and run `sudo ./scripts/on-prem-install.sh`, passing the
   root URL of your new depot as the first argument. For example:
   `HAB_AUTH_TOKEN=abc123 ./scripts/on-prem-install.sh http://depot.example.com`
1. The above process currently does not currently support air-gapped environments and
   will require internet access in order to work. It's also quite a lengthy
   process, as it will download a large number of packages from the public
   Habitat Depot and then re-upload those packages to your new on-prem depot.
   It's also worth noting that the core packages downloaded will get installed
   into the Habitat artifact cache (`/hab/cache/artifacts`) on the machine
   where this script is run. Please ensure that you have plenty of free drive
   space available. It also may be difficult to cleanup any unused packages
   after this process has run.
