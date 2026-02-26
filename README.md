# Chef Habitat Builder on-prem

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

## Documentation

The documentation for On-Prem Builder is located in the [on-prem-docs](docs-chef-io/content/habitat/builder/on_prem/) directory.

### Index

#### Installation

1. [Getting Started](docs-chef-io/content/habitat/builder/on_prem/install/_index.md)
1. [Builder + Automate](https://docs.chef.io/automate/on_prem_builder/) *OR* [Builder + OAuth Authentication](docs-chef-io/content/habitat/builder/on_prem/install/builder_oauth.md) (AzureAD/Github/GitLab/Okta/BitBucket)
1. [Bootstrap Core Packages](docs-chef-io/content/habitat/builder/on_prem/packages/bootstrap_core_packages.md)

#### Reference

1. [Example builder.env](docs-chef-io/content/habitat/builder/on_prem/configure/builder_config_example.md)
2. [Logging](docs-chef-io/content/habitat/builder/on_prem/configure/logs.md)
3. [Troubleshooting](docs-chef-io/content/habitat/builder/on_prem/troubleshooting.md)

#### Managing Builder On-Prem

1. [Managing the Builder On-Prem Postgres Installation](docs-chef-io/content/habitat/builder/on_prem/manage/postgres.md)
1. [Managing the Builder On-Prem Minio Installation](docs-chef-io/content/habitat/builder/on_prem/manage/minio.md)
1. [Refreshing the Builder On-Prem with New Habitat Release Packages](docs-chef-io/content/habitat/builder/on_prem/packages/update_packages.md)
1. [Using Artifactory with Builder On-Prem](docs-chef-io/content/habitat/builder/on_prem/configure/artifactory.md)
1. [High Availability / Disaster Recovery](docs-chef-io/content/habitat/builder/on_prem/configure/disaster_recovery_warm_spare.md)
1. [Scaling Frontends](docs-chef-io/content/habitat/builder/on_prem/configure/scale_frontend_nodes.md)
1. [SSL Certificate Rotation](docs-chef-io/content/habitat/builder/on_prem/manage/ssl_cert_rotation.md)

# Copyright
See [COPYRIGHT.md](./COPYRIGHT.md).
