# On Premise Habitat Builder

## Introduction

This repository contains scripts to install Habitat Builder back-end services. These services (referred to as the On-Premise Habitat Builder depot) allow privately hosting Habitat packages (and associated artifacts such as keys) on-premise. Habitat clients (such as the `hab` cli, Supervisors and Studios) can be pointed to the on-premise depot and allow for development, execution and management without depending on the public Habitat services.

## Audience

This work is *MVP/Alpha* level, and intended for use by Chef Customer Development Partners only. We will be continually improving it over the next few months, and users should be prepared to actively update their installations to benefit from these updates.

## Requirements

The following are minimum requirements for installation/deployment of the Habitat Depot:

* Services should be deployed on a Habitat supported [Linux OS](https://www.habitat.sh/docs/install-habitat/)
* OS should support `systemd` process manager
* Deployment to bare-metal, VM or container image
* 8 GB or more RAM recommended (for single node)
* Significant free disk space (depends on package storage, which depends on the size of the applications you are building and storing here - plan conservatively. Around 2GB is required for the baseline installation with only the packages required to run the Builder services, and another 5GB+ of disk space for the latest versions of core packages)
* Services should be deployed single-node - scale out is not yet supported
* Outbound network (HTTPS) connectivity to WAN is required for the _initial_ install
* Inbound network connectivity from LAN (HTTP/HTTPS) is required for internal clients to access the depot
* OAuth2 authentication provider (Azure AD, GitHub, GitHub Enterprise, GitLab, Okta and Bitbucket have been verified - additional providers may be added on request)

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

Your on-premise Builder instance will need to have the following _inbound_ port open:
* Port 80 (or 443 if you plan to enable SSL)

You may need to work with your enterprise network admin to enable the appropriate firewall rules.

### OAuth Application

We currently support Azure AD (OpenId Connect), GitHub, GitLab (OpenId Connect), Okta (OpenId Connect) and Atlassian Bitbucket OAuth providers for authentication. You will need to set up an OAuth application for the instance of the depot you are setting up.

Refer to the steps that are specific to your OAuth provider to create and configure your OAuth application. The below steps illustrate setting up the OAuth application using Github as the identity provider:

1. Create a new OAuth Application in your OAuth Provider - for example, [GitHub](https://github.com/settings/applications/new)
1. Set the value of `Homepage URL` to `http://${APP_HOSTNAME_OR_IP}`, or `https://${APP_HOSTNAME_OR_IP}` if you plan to enable SSL.
1. Set the value of `User authorization callback URL` to `http://${APP_HOSTNAME_OR_IP}/` (The trailing `/` is *important*). Specify `https` instead of `http` if you plan to enable SSL.
1. Record the the Client Id and Client Secret. These will be used for the `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` environment variables in the section below.

For the configuration below, you will also need to know following *fully qualified* end-points:
* Authorization Endpoint (example: `https://github.com/login/oauth/authorize`)
* Token Endpoint (example: `https://github.com/login/oauth/access_token`)
* API Endpoint (example: `https://api.github.com`)

For more information, please refer to the developer documentation of these services:
* [Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-protocols-oauth-code)
* [GitHub](https://developer.github.com/apps/building-oauth-apps/authorization-options-for-oauth-apps/)
* [GitLab](https://docs.gitlab.com/ee/integration/oauth_provider.html)
* [Okta](https://developer.okta.com/authentication-guide/implementing-authentication/auth-code)
* [BitBucket](https://confluence.atlassian.com/bitbucket/oauth-on-bitbucket-cloud-238027431.html)

Further information on the OAuth endpoints can also be found [here](https://tools.ietf.org/html/rfc6749#page-21).

### Preparing your filesystem (Optional)

Since substantial storage may be required for holding packages, please ensure you have an appropriate amount of free space on your filesystem.

For reference, the package artifacts will be stored at the following location: `/hab/svc/builder-api/data`

If you need to add additional storage, it is recommended that you create a mount at `/hab` and point it to your external storage. This is not required if you already have sufficient free space.

### Procuring SSL certificate (Recommended)

By default, the on-premise Builder will expose the web UI and API via http. Though it allows for easier setup and is fine for evaluation purposes, for a secure and more permanent installation it is recommended that you enable SSL on the Builder endpoints.

In order to prepare for this, you should procure a SSL certificate. If needed, you may use a self-signed certificate - however if you do so, you will need to install the certificate in the trusted chain on client machines (ones that will use the Builder UI or APIs). You may use the `SSL_CERT_FILE` environment variable to also point to the certificate on client machines when invoking the `hab` client, for example:

```
SSL_CERT_FILE=ssl-certificate.crt hab pkg search -u https://localhost <search term>
```

Below is a sample command to generate a self-signed certificate with OpenSSL:

```
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-certificate.key -out /etc/ssl/certs/ssl-certificate.crt
```

*Important*: Make sure that the certificate files are named exactly `ssl-certificate.key` and `ssl-certificate.crt`. If you have procured the certificate from a different source, rename them to the prescribed filenames, and ensure that they are located in the same folder as the `install.sh` script. They will get uploaded to the Habitat supervisor during the install.

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

Do a `hab svc status` to check the status of all the services. They may take a few seconds to all come up.

If things don't work as expected (eg, if all the services are not in the `up` state), please see the Troubleshooting section below.

## Web UI

Once the services are running successfully, the Builder UI will become available at the configured hostname or IP address.

Navigate to `http://${APP_HOSTNAME_OR_IP}/#/sign-in` to access the Builder UI.

At that point you should be able to log in using your configured OAuth provider.

### Create an Origin

Once you are logged in, you should be able to create an origin by clicking on the 'Create Origin' button.

You will need to at least create a `core` origin for an initial set of base packages (see section below). Go ahead and create a new origin now, and type in `core` as the origin name.

### Generate a Personal Access Token

In order to bootstrap a set of `core` package, as well as perform authenticated operations using the `hab` client, you will need to generate a Personal Access Token.

Click on your Gravatar icon on the top right corner of the Builder web page, and then select Profile. This will take you to a page where you can generate your access token. Make sure to save it away securely.

## Bootstrap `core` packages

*Important*: Please make sure you have created a `core` origin before starting this process.

The freshly installed Builder depot does not contain any packages. In order to bootstrap a set of stable `core` origin packages (refer to the [core-plans repo](https://github.com/habitat-sh/core-plans)), you can do the following:

1. Export your Personal Access Token as `HAB_AUTH_TOKEN` to
   your environment (e.g, `export HAB_AUTH_TOKEN=<your token>`)
1. `sudo -E ./scripts/on-prem-archive.sh populate-depot http://${APP_HOSTNAME_OR_IP}`, passing the
   root URL of your new depot as the last argument  (Replace `http` with `https` in the URL if SSL is enabled)

This is quite a lengthy process, so be patient. It will download a *large* (~ 5GB currently) archive of the latest stable core plans, and then install them to your on-premise depot.

Please ensure that you have plenty of free drive space available, for hosting the `core` packages as well as your own packages.

## Upgrading

Currently, the Builder services are not set to auto-upgrade. If you need to upgrade the services, there is a simple uninstall script you can use to stop and unload the services, and remove the services. In order to uninstal, you may do the following:
1. `cd ${SRC_ROOT}`
1. `sudo ./uninstall.sh`

Once the services are uninstalled, you may re-install them by running `./install.sh` again.

## Support

Please work with your Chef success engineers for support. You may also file issues directly at the [Github repo](https://github.com/habitat-sh/on-prem-builder/issues).

## Troubleshooting

### Network access

If the initial install fails, please check that you have outgoing connectivity, and that you can successfully ping the following:
* `raw.githubusercontent.com`
* `bldr.habitat.sh`

If you have outgoing access via a proxy, please ensure that HTTPS_PROXY is set correctly in your environment.

You also will need to have the following _inbound_ port open for your instance:
* Port 80

Please work with your enterprise network admin to ensure the appropriate firewall rules are configured for network access.

### Authentication failure when logging in

If you are not able to log in, please double check the settings that you have configured your OAuth application with, as well as the URLs that you have specified in your `bldr.env` file.

You can also turn on debug logging (section below) and check to see that the authenticate endpoint is getting called at the Builder API backend, and whether there is any additional information in the logs that may be helpful.

The OAuth Token and API endpoints must be reachable from the on-premise install point.

*Important*: If you change any settings in your `bldr.env` file, you will need to do the following steps after making the changes:
1. Re-run the install script (`./install.sh`)
2. Restart the services (`sudo systemctl restart hab-sup`)

### Error "sorry, too many clients already"

If the hab services don't come up as expected, use `journalctl -fu hab-sup` to check the service logs (also see below for turning on Debug Logging).

If you see a Postgresql error "sorry, too many clients already", you may need to increase the number of configured connections to the database.

In order to do that, run the following:

`echo 'max_connections=200' | hab config apply "builder-datastore.default" $(date +%s)`

Wait for a bit for the datastore service to restart. If the service does not restart on it's own, you can do a 'sudo systemctl restart hab-sup' to restart things.

### Error "Text file busy"

Occasionally you may get an error saying "Text file too busy" during install.
If you get this, please re-try the install step again.

### Error when bootstrapping core packages

You may see the following error when bootstrapping the core packages using the script above. If this happens, the bootstrap process will continue re-trying, and the upload will eventually succeed. Be patient and let the process continue until successful completion.

```
✗✗✗
✗✗✗ Pooled stream disconnected
✗✗✗
```
### Error uploading large packages

By default, there is a 1GB limit for packages that can be uploaded to Builder. If you need to change the limit, you can do so by injecting an updated config to the Builder services.

For example, to change the limit to 2GB, you can do the following:

Create a file called `config.toml` with the following content:
```
[nginx]
max_body_size = "2048m"
```

Then, issue the following command:
```
hab config apply builder-api-proxy.default $(date +%s) config.toml
```
After the config is successfully applied, re-try the upload.

### Debug Logging

If you want to turn on and examine the services debug logging, you can do so by doing the following on your install location:

`for svc in originsrv api router sessionsrv; do echo 'log_level="debug"' | hab config apply "builder-${svc}.default" $(date +%s) ; done`

Once the logging is enabled, you can examine it via `journalctl -fu hab-sup`

When you are done with debugging, you can set the logging back to the default setting by running:

`for svc in originsrv api router sessionsrv; do echo 'log_level="info"' | hab config apply "builder-${svc}.default" $(date +%s) ; done`
