+++
title = "Scale frontend nodes"

[menu]
  [menu.habitat]
    title = "Frontend scaling"
    identifier = "habitat/on-prem Habitat Builder/frontend scaling"
    parent = "habitat/on-prem Habitat Builder"
    weight = 20
+++

With any tiered or high-availability deployment of Habitat Builder services, you'll likely want to scale your frontend nodes horizontally.
The most common deployment pattern for this use case is a pool of frontend nodes behind a load balancer.

## System recommendations for multiple frontend nodes

The hardware requirement for an API node is low.
However, your node count and usage statistics might change this recommendation.
For example, Chef's Habitat Builder SaaS uses compute-optimized machines with 36 vCPUs and 60 GB of RAM.
This setup supports a live SaaS service with thousands of supervisors checking in at any time.
Disk space doesn't matter on a new API node because the API shouldn't put disk resources into contention, except possibly for logging.

These are only recommendations, and we can't guarantee performance at these scales.
You should run these nodes in a pool behind a load balancer.

For a small deployment (tens of nodes):

- CPU: 2 vCPUs
- RAM: 4 GB
- Disk: 20 GB

For a mid-sized deployment (hundreds of nodes):

- CPU: 8 vCPUs
- RAM: 16 GB
- Disk: 20 GB

For a large deployment (thousands of nodes):

- CPU: 16 or more vCPUs
- RAM: 32 GB or more
- Disk: 20 GB

## Configure node ports

The on-prem Habitat Builder `install.sh` script supports scaling frontend nodes as a deployment pattern.
You must deploy new frontend nodes on separate compute resources from your initial on-prem deployment.
Because Habitat Builder services need to communicate across your network between the frontend and backend nodes, you need to open the following ports to these nodes to ensure your on-prem Habitat Builder works correctly:

- TCP 9638 - Habitat configuration gossip
- UDP 9638 - Habitat configuration gossip
- TCP 9636 - Builder API HTTP
- TCP 5432 - PostgreSQL
- TCP 9000 - MinIO
- TCP 11211 - Memcached

### Create and update bldr.env

The `bldr.env` file for your single on-prem builder node contains most of the information you need to bootstrap a new frontend and will be used during installation.
However, you need to update some configuration.

Update the values of `OAUTH_REDIRECT_URL`, `OAUTH_CLIENT_ID`, and `OAUTH_CLIENT_SECRET` to match your on-premises OAuth2 provider.

If your on-prem Habitat Builder cluster uses cloud services and you run multiple frontend instances, set `OAUTH_REDIRECT_URL` to your load balancer.

If you don't use cloud services, update the values of `POSTGRES_HOST` and `MINIO_ENDPOINT`.

You also need to edit (or create, if it isn't already present) `HAB_BLDR_PEER_ARG` to include all frontend and backend nodes hosting builder services.
Use the following format:

```shell
--peer host1 --peer host2 --peer host3
```

### Install frontend

To install a new frontend node, run the frontend install script from each new frontend node:

```shell
./install.sh --install-frontend
```
