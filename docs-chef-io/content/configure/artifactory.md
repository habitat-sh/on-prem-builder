+++
title = "Chef Habitat Builder on-prem and Artifactory"

[menu]
  [menu.habitat]
    title = "Artifactory"
    identifier = "habitat/on-prem-builder/artifactory"
    parent = "habitat/on-prem-builder"
    weight = 20
+++

If you are interested in using an existing instance of Artifactory as your object store instead of MinIO,
we are providing this capability as an early preview/alpha for testing.

Before you begin, you will need the following:

- The URL to the Artifactory instance.
- An API key to authenticate to the instance.
- A repository for the Habitat artifacts.

Once you have the above:

1. Modify the your `bldr.env` based on the same config in `bldr.env.sample` in order to enable Artifactory.

1. Install Habitat Builder on-prem normally using the `install.sh` script.

1. Optional: Log into Habitat Builder and create an origin, then upload some packages and check your Artifactory instance to ensure that they are present in the repository you specified.

If you run into any issues, see the support section below.

## Test a local Artifactory instance

If you just want to do a quick test, you can run a local Artifactory instance. To do that, run the following command:

```bash
sudo hab svc load core/artifactory
```

This spins up a local Artifactory instance, which you can view at: `http://localhost:8081/artifactory/webapp/#/home`

## Manage Builder artifacts on Artifactory

If you use Artifactory for your Habitat Builder on-prem artifact store, we recommend reading about [Artifactory's best practices for disaster recovery](https://jfrog.com/whitepaper/best-practices-for-artifactory-backups-and-disaster-recovery/).
