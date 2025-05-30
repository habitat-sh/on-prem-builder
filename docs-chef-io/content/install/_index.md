+++
title = "Chef Habitat Builder on-prem install overview"

[menu]
  [menu.habitat]
    title = "Overview"
    identifier = "habitat/on-prem-builder/install/overview"
    parent = "habitat/on-prem-builder"
    weight = 10
+++

Chef Habitat Builder has the following system requirements.

## System requirements

Chef Habitat Builder has the following minimum requirements:

- Deploy Builder on a [Linux distribution supported by Habitat](https://docs.chef.io/habitat/install_habitat/#chef-habitat-for-linux).
- The Linux OS must support the `systemd` process manager.
- You can deploy it to bare metal, a VM, or a container image.
- CPU and RAM should match the deployment purpose:
  - 2 CPUs and 4 GB RAM for trial deployments.
  - 16 CPUs and 32 GB RAM for production deployments.
- Significant free disk space:
  - 2 GB for the baseline Chef Habitat Builder on-prem services,
  - 15 GB or more for the latest Chef Habitat Builder core packages,
  - 30 GB or more to download and expand the core package bootstrap in the volume containing the `/tmp` directory.

  We recommend:
  - 50 GB disk space for trial deployments.
  - 100 GB disk space for production deployments.
- Outbound network (HTTPS) connectivity to WAN is required for the initial install.
- Inbound network connectivity from LAN (HTTP/HTTPS) is required for internal clients to access Chef Habitat Builder on-prem.
- An OAuth2 authentication provider. Chef Automate v2, Azure AD, GitHub, GitHub Enterprise, GitLab, Okta, and Bitbucket (cloud) have been verified. You can request additional providers.

## Optional: Memory filesystem storage

Follow these guidelines for your filesystem storage:

- Chef Habitat Builder requires substantial storage space for packages. Ensure you have enough free space on your filesystem.
- Chef Habitat Builder stores package artifacts in a MinIO instance by default, typically in `/hab/svc/builder-minio/data`.
- If you need additional storage, create a mount at `/hab` and point it to your external storage. This isn't required if you have enough free space.
- If you want to use Artifactory instead of MinIO for object storage, see the [Habitat Builder on-prem and Artifactory](./artifactory/) documentation.

## Next step

To deploy Habitat Builder, use one of the following guides:

- [Install Builder on-prem authenticating with Chef Automate](./builder-automate.md)
- [Install Builder on-prem authenticating with another OAuth service](./builder-oauth.md)
