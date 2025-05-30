+++
title = "Chef Habitat Builder on-prem install overview"

[menu]
  [menu.habitat]
    title = "Overview"
    identifier = "habitat/on-prem-builder/install/overview"
    parent = "habitat/on-prem-builder"
    weight = 10
+++

## System requirements

Chef Habitat Builder has the following minimum requirements:

- Deploy Builder on a [Linux distribution supported by Habitat](https://docs.chef.io/habitat/install_habitat/#chef-habitat-for-linux).
- The Linux OS must support the `systemd` process manager.
- It can be deployed to bare metal, a VM, or a container image.
- CPU / RAM should be appropriate for the deployment purpose:
  - 2 CPUs and 4 GB RAM for trial deployments.
  - 16 CPUs and 32 GB RAM for production deployments.
- Significant free disk space:
  - 2GB for the baseline Chef Habitat Builder on-prem services.
  - 15GB+ for the latest Chef Habitat Builder core packages.
  - 30GB+ to download and expand the core package bootstrap in the volume containing the `/tmp` directory.

  We recommend:
  - 50 GB disk space for trial deployments.
  - 100 GB disk space for production deployments.
- Outbound network (HTTPS) connectivity to WAN is required for the _initial_ install.
- Inbound network connectivity from LAN (HTTP/HTTPS) is required for internal clients to access the Chef Habitat Builder on-prem.
- An OAuth2 authentication provider. Chef Automate v2, Azure AD, GitHub, GitHub Enterprise, GitLab, Okta and Bitbucket (cloud) have been verified. Additional providers may be added on request.

## Optional: Memory filesystem storage

Review the following guidelines for your filesystem storage:

- Chef Habitat Builder requires substantial storage space for packages. Ensure you have an appropriate amount of free space on your filesystem.
- Chef Habitat Builder stores package artifacts in a MinIO instance by default, typically in `/hab/svc/builder-minio/data`.
- If you need additional storage, create a mount at `/hab` and point it to your external storage. This is not required if you have sufficient free space.
- If you would prefer to Artifactory instead of MinIO for the object storage, see the [Habitat Builder on-prem and Artifactory](./artifactory/) documentation.

## Next step

After you've prepared your system, use one of the following guides to deploy Habitat Builder:

- [Install Builder on-prem authenticating with Chef Automate](./builder-automate.md)
- [Install Builder on-prem authenticating with another OAuth service](./builder-oauth.md)
