# On Premise Habitat Builder

## Introduction

This repository contains scripts to install Habitat Builder back-end services. These services (referred to as the On-Premise Habitat Builder depot) allow for the hosting of Habitat packages (and associated artifacts such as keys) by enterprises in-house (behind the firewall). Habitat clients can be pointed to the on-premise depot and allow for development, execution and management without depending on the public Habitat services.

## Audience

This work is *Alpha* level, and intended for use by Chef Customer Development Partners only.

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

## Functionality

Once installed, the following functionality will be available to users:

* Logging into the on-premise Builder depot web site
* Creation of origins, keys, access tokens, etc
* Invitation of users to origins
* Upload and download of Habitat packages
* Promotion and demotion of Habitat packages to channels
* Normal interactions of the `hab` client with the Builder API
* Package builds using the `hab` client and Habitat Studio

The following Habitat Builder functionality will *NOT* be available:
* Automated package builds using Builder
* Automated package exports using Builder

## Pre-Requisites

Prior to starting the install, please ensure you have reviewed all the items
in the Requirements section, and have a location for the installation that
meets all the requirements.

Note that the initial install will require _outgoing_ network connectivity.

### OAuth Application

We currently support GitHub and Atlassian Bitbucket OAuth providers for authentication. You will need to set up an OAuth application for the instance of the depot you are setting up.

Refer to the steps that are specific to your OAuth provider to create and configure your OAuth application. The below steps illustrate setting up the OAuth application using Github as the identity provider:

1. Create a new OAuth Application in your OAuth Provider - for example, [GitHub](https://github.com/settings/applications/new)
1. Set the value of `Homepage URL` to `http://${APP_HOSTNAME_OR_IP}`
1. Set the value of `User authorization callback URL` to `http://${APP_HOSTNAME_OR_IP}/` (The trailing `/` is *important*)
1. Record the the Client Id and Client Secret. These will be used for the `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` environment variables in the section below.

For the configuration below, you will also need to know following *fully qualified* end-points:
* Authorization Endpoint (example: `https://github.com/login/oauth/authorize`)
* Token Endpoint (example: `https://github.com/login/oauth/access_token`)
* API Endpoint (example: `https://api.github.com`)

For more information, please refer to the
[GitHub Developer Documentation](https://developer.github.com/apps/building-oauth-apps/authorization-options-for-oauth-apps/) or the [BitBucket Developer Documentation](https://confluence.atlassian.com/bitbucket/oauth-on-bitbucket-cloud-238027431.html).

Further information on the OAuth endpoints can also be found [here](https://tools.ietf.org/html/rfc6749#page-21)

## Setup

1. Clone this repo (or unzip the archive you have been given) at the desired machine where you will stand up the Habitat depot
1. `cd ${SRC_ROOT}`
1. `cp bldr.env.sample bldr.env`
1. Edit `bldr.env` with a text editor and replace the values appropriately
1. `./install.sh`

If everything goes well, you should see output similar to the following showing that the depot services are loaded:

```
hab-sup(MN): The habitat/builder-datastore service was successfully loaded
hab-sup(MN): The habitat/builder-router service was successfully loaded
hab-sup(MN): The habitat/builder-api service was successfully loaded
hab-sup(MN): The habitat/builder-api-proxy service was successfully loaded
hab-sup(MN): The habitat/builder-originsrv service was successfully loaded
hab-sup(MN): The habitat/builder-sessionsrv service was successfully loaded
```

If things don't work as expected, please see the Troubleshooting section below.

## Web UI

Once the services are running successfully, the Builder UI will become available at the configured hostname or IP address.

Nagigate to http://${APP_HOSTNAME_OR_IP}/#/sign-in to access the Builder UI

At that point you should be able to log in using your configured OAuth provider.

### Create an Origin

Once you are logged in, you should be able to create an origin by clicking on the 'Create Origin' button.

### Generate a Personal Access Token

In order to bootstrap a set of `core` package, as well as perform authenticated operations using the `hab` client, you will need to generate a Personal Access Token.

Click on your Gravatar icon on the top right corner of the Builder web page, and then select Profile. This will take you to a page where you can generate your access token. Make sure to save it away securely.

## Bootstrap `core` packages

The freshly installed Builder depot does not contain any packages. In order to bootstrap a set of stable `core` origin packages (refer to the [core-plans repo](https://github.com/habitat-sh/core-plans)), you can do the following:

1. Export your Personal Access Token as `HAB_AUTH_TOKEN` to
   your environment (e.g, `export HAB_AUTH_TOKEN=<your token>`)
1. `sudo ./scripts/on-prem-archive.sh populate-depot http://${APP_HOSTNAME_OR_IP}`, passing the
   root URL of your new depot as the last argument

This is quite a lengthy process, so be patient. It will download a *large* archive of the latest stable core plans, and then install them to your on-premise depot.

Please ensure that you have plenty of free drive space available, for hosting the `core` packages as well as your own packages.

## Upgrading

Currently, the Builder services are not set to auto-upgrade. If you need to upgrade the services, there is a simple uninstall script you can use to stop and unload the services, and remove the services. In order to uninstal, you may do the following:
1. `cd ${SRC_ROOT}`
1. `./uninstall.sh`

Once the services are uninstalled, you may re-install them by running `./install.sh` again.

## Support

Please work with your Chef success engineers for support. You may also file issues directly at the [Github repo](https://github.com/habitat-sh/on-prem-builder/issues)

## Troubleshooting

### Network access

If the initial install fails, please check that you have outgoing connectivity, and that you can successfully ping the following:
* `raw.githubusercontent.com`
* `bldr.habitat.sh`

If you have outgoing access via a proxy, please ensure that HTTPS_PROXY is set correctly in your environment.

### Authentication failure when logging in

If you are not able to log in, please double check the settings that you have configured your OAuth application with, as well as the URLs that you have specified in your bldr.env file.

You can also turn on debug logging (section below) and check to see that the authenticate endpoint is getting called at the Builder API backend, and whether there is any additional information in the logs that may be helpful.

The OAuth Token and API endpoints must be reachable from the on-premise install point.

### Debug Logging

If you want to turn on and examine the services debug logging, you can do so by doing the following on your install location:

`for svc in originsrv api sessionsrv; do echo 'log_level="debug"' | hab config apply "builder-${svc}.default" $(date +%s) ; done`

Once the logging is enabled, you can examine it via `journalctl -fu hab-sup`

When you are done with debugging, you can set the logging back to the default setting by running:

`for svc in originsrv api sessionsrv; do echo 'log_level="info"' | hab config apply "builder-${svc}.default" $(date +%s) ; done`
