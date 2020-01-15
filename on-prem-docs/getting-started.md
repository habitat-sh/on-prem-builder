# Chef Habitat Builder on-prem

Chef Habitat Builder overview and pre-requisites

This repository contains scripts to install Chef Habitat Builder on-prem services. These services (referred to as the Chef Habitat Builder on-prem) allow privately hosting Chef Habitat packages (and associated artifacts such as keys) on-premise. Chef Habitat clients (such as the `hab` cli, Supervisors and Studios) can be pointed to the Chef Habitat Builder on-prem and allow for development, execution and management without depending on the public Chef Habitat services.

## Audience

This repository is intended for use by any one who wishes to host Chef Habitat packages in their own infrastructure. Users should be prepared to actively update their installations to benefit from continued improvements and updates.

## Requirements

The following are minimum requirements for installation/deployment of the Chef Habitat Builder on-prem:

* Services should be deployed on a Chef Habitat supported [Linux OS](https://www.habitat.sh/docs/install-habitat/)
* OS should support `systemd` process manager
* Deployment to bare-metal, VM or container image
* CPU / RAM should be appropriate for the deployment purpose:
  * 2 CPU/4 GB RAM for trial deployments
  * 16 CPU/32 GB RAM for production deployments
* Significant free disk space
  * 2GB for the baseline Chef Habitat Builder on-prem services
  * 15GB+ for the latest Chef Habitat Builder core packages
  * 30GB+ for downloading and expanding the core package bootstrap in the volume containing the `/tmp` directory
* We recommend:
  * 50 GB disk space for trial deployments
  * 100 GB disk space for production deployments
* Deploy services single-node - scale out is not yet supported
* Outbound network (HTTPS) connectivity to WAN is required for the _initial_ install
* Inbound network connectivity from LAN (HTTP/HTTPS) is required for internal clients to access the Chef Habitat Builder on-prem
* OAuth2 authentication provider (Chef Automate v2, Azure AD, GitHub, GitHub Enterprise, GitLab, Okta and Bitbucket (cloud) have been verified - additional providers may be added on request)

## Functionality

Once installed, the following functionality will be available to users:

* Logging into the Chef Habitat Builder on-prem web site
* Creation of origins, keys, access tokens, etc
* Invitation of users to origins
* Upload and download of Chef Habitat packages
* Promotion and demotion of Chef Habitat packages to channels
* Normal interactions of the `hab` client with the Chef Habitat Builder API
* Package builds using the `hab` client and Chef Habitat Studio
* Ability to import core packages from the upstream Chef Habitat Builder

The following Chef Habitat Builder on-prem functionalities are *NOT* currently available:

* Automated package builds using Chef Habitat Builder on-prem
* Automated package exports using Chef Habitat Builder on-prem

### Memory Filesystem Storage

Preparing your filesystem (Optional)
Since substantial storage may be required for holding packages, please ensure you have an appropriate amount of free space on your filesystem.
The package artifacts will be stored in your Minio instance by default, typically at the following location: `/hab/svc/builder-minio/data`
If you need to add additional storage, it is recommended that you create a mount at `/hab` and point it to your external storage. This is not required if you already have sufficient free space.
*Note*: If you would prefer to Artifactory instead of Minio for the object storage, please see the [Artifactory](#using-artifactory-as-the-object-store-(alpha)) section below.

## Next Steps

* [Install Builder on-prem authenticating with Chef Automate](./builder-automate.md)
* [Install Builder on-prem authenticating with another OAuth service](./builder-oauth.md)
