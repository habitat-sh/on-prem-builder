# Chef Habitat Builder on-prem

**Umbrella Project**: [Chef Habitat](https://github.com/habitat-sh/habitat)

**Project State**: [Active](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#active)

**Issues Response SLA**: 5 business days

**Pull Request Response SLA**: 5 business days

## Introduction

This repository contains scripts and documentation to install Chef Habitat Builder on-prem services. The Chef Habitat Builder on-prem services allow privately hosting Chef Habitat packages and associated artifacts such as keys on-premise. Chef Habitat clients, such as the `hab` cli, Supervisors and Studios, can be pointed to the Chef Habitat Builder on-prem to allow for development, execution, and management without depending on the public Chef Habitat services.

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
* Chef recommends:
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

## Documentation

The documentation for Builder on-prem is located in the [on-prem-docs](on-prem-docs/getting-started.md) directory.

### Index

#### Installation

1. [Getting Started](on-prem-docs/getting-started.md)
1. [Builder + Automate](on-prem-docs/builder-automate.md) *OR* [Builder + OAuth Authentication](on-prem-docs/builder-oauth.md) (AzureAD/Github/GitLab/Okta/BitBucket)
1. [Bootstrap Core Packages](on-prem-docs/bootstrap-core.md)

#### Reference

1. [Example builder.env](on-prem-docs/builder-example.md)
2. [Logging](on-prem-docs/logs.md)
3. [License](on-prem-docs/license.md)
4. [Troubleshooting](on-prem-docs/troubleshooting.md)

#### Managing Builder On-Prem

1. [Managing the Builder On-Prem Postgres Installation](on-prem-docs/postgres.md)
1. [Managing the Builder On-Prem Minio Installation](on-prem-docs/minio.md)
1. [Using Artifactory with Builder On-Prem](on-prem-docs/artifactory.md)
1. [High Availability / Disaster Recovery](on-prem-docs/warm-spare.md)
1. [Scaling Frontends](on-prem-docs/scaling.md)

#### Data Migration to Chef Automate deployed Builder

1. [Data migration](on-prem-docs/migration.md)
