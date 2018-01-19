# On Prem Habitat Builder

:construction: THIS IS NOT FOR PRODUCTION USE :construction:

## Pre-Requisites

### GitHub OAuth Application

1. Create a GitHub Organization
1. [Setup a GitHub application](https://github.com/settings/apps/new) for your GitHub organization.
1. Set the value of `Homepage URL` to `http://${APP_HOSTNAME}`
1. Set the value of `User authorization callback URL` to `http://${APP_HOSTNAME}/` (The trailing `/` is *important*)
1. Set the value of `Webhook URL` to `http://${APP_HOSTNAME}/`
1. Set everything to read only (this is only used for your org so it's safe)
1. Save and download the pem key
1. Copy the pem key to `${SRC_ROOT}/.secrets/builder-dev-app.pem`
1. Record the the client-id, client-secret and app_id. These will be used for the `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET` and `GITHUP_APP_ID` build variables (seen below).

## Setup

1. Clone this repo to the desired machine to stand up builder
1. `cd ${SRC_ROOT}`
1. `sudo ./install.sh`