# On Premise Habitat Depot

:construction: THIS IS NOT FOR PRODUCTION USE :construction:

## Introduction

This repository contains scripts to install Habitat back-end services. These services (referred to as the On-Premise Habitat Depot) allow for the hosting of Habitat packages (and associated artifacts such as keys) by enterprises in-house (behind the firewall). Habitat clients can be pointed to the on-premise depot and allow for development, execution and management without depending on the public Habitat services.

This work is currently a MVP - it is not intended for general production use.

## Requirements

The following are minimum requirements for installation/deployment of the Habitat Depot:

* Services should be deployed on a Habitat supported [Linux OS](https://www.habitat.sh/docs/install-habitat/)
* OS should support `systemd` process manager
* Deployment to bare-metal, VM or container image
* 8 GB or more RAM recommended (for single node)
* Significant free disk space (depends on package storage - plan conservatively)
* Services should be deployed single-node - scale out is not yet supported
* Outbound network (HTTPS) connectivity to WAN is required for the _initial_ install
* Inbound network connectivity from LAN (HTTP) for internal access to the Depot
* OAuth2 authentication provider (Github or Bitbucket currently supported)

## Pre-Requisites

### OAuth Application

We currently support GitHub and Atlassian Bitbucket OAuth providers for authentication. Follow the steps below to configure your OAuth application.

1. Set up an OAuth Application in your OAuth Provider - for example, [GitHub](https://github.com/settings/applications/new)
1. Set the value of `Homepage URL` to `http://${APP_HOSTNAME_OR_IP}`
1. Set the value of `User authorization callback URL` to `http://${APP_HOSTNAME_OR_IP}/` (The trailing `/` is *important*)
1. Record the the Client Id and Client Secret. These will be used for the `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` environment variables in the section below.

For the configuration below, you will also need to know following end-points:
* Authorization Endpoint (example: `https://github.com/login/oauth/authorize`)
* Token Endpoint (example: `https://github.com` - only the base URL is needed)
* API Endpoint (example: `https://api.github.com`)

For more information, please refer to the
[GitHub Developer Documentation](https://developer.github.com/apps/building-oauth-apps/authorization-options-for-oauth-apps/) or the [BitBucket Developer Documentation](https://confluence.atlassian.com/bitbucket/oauth-on-bitbucket-cloud-238027431.html).

## Setup

1. Clone this repo to the desired machine where you will stand up the Habitat Depot
1. `cd ${SRC_ROOT}`
1. `cp bldr.env.sample bldr.env`
1. Edit `bldr.env` with a text editor and replace the values appropriately
1. `sudo ./install.sh`

## Web UI

Nagigate to http://${APP_HOSTNAME_OR_IP}/#/sign-in to access the Builder UI

## Debug Logging

If you want to turn on and examine the services debug logging, you can do so by doing the following:
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
