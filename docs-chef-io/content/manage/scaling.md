+++
title = "Frontend scaling"

[menu]
  [menu.habitat]
    title = "Frontend scaling"
    identifier = "habitat/builder/on-prem/frontend scaling"
    parent = "habitat/builder/on-prem"
    weight = 20
+++

With any tiered or HA deployment of the builder services you'll likely want to horizontally scale your frontend nodes. The most common deployment pattern for this use case is a pool of frontend nodes fronted by a load balancer.

## Deploy new frontend nodes

## Deploy new Front-ends

### System Recommendations
The hardware requirement for an API node is low, however your node-count and usage statistics might alter our recommendation. For our live builder SaaS we are using compute optimized 36vcpu machines with 60Gbs of ram. This is obviously for a live running SaaS service with many thousands of supervisors checking in at any given time. Our disk space does not matter on a new api node as disk is not a resource the API should ever put into contention outside of possibly logging.

It's worth mentioning these are only recommendations and we don't make promises on performance at these scales. However, the intention is for these nodes to be run in a pool behind a load-balancer.

For a small deployment (tens of nodes):
CPU: 2vcpu
RAM: 4Gb
DISK: 20Gb

For a mid-sized deployment (hundreds of nodes):
CPU: 8vcpu
Ram: 16Gb
DISK: 20Gb

For a large deployment (thousands of nodes):
CPU: 16+vcpu
RAM: 32+Gb
DISK: 20Gb

## Deploying New Front-ends
The on-prem-builder install.sh script now supports scaling front-end nodes as a deployment pattern. It is required that new front-ends be deployed on a separate compute from your initial on-prem deployment. Since builder services will now need to communicate accross your network between the frontend and backend nodes, you must open the folowing ports to these nodes in order to guarantee your on-prem builder properly functions:

* TCP 9638 - Habitat configuration gossip
* UDP 9638 - Habitat configuration gossip
* TCP 9636 - Builder API HTTP
* TCP 5432 - PostgreSQL
* TCP 9000 - MinIO
* TCP 11211 - memcached

### Create and update bldr.env

The `bldr.env` file for your single on-prem Habitat Builder node contains most of the information required to bootstrap a new frontend and is used during the installation process. However, some configuration will need to change.

Update the values of `OAUTH_REDIRECT_URL`, `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` as per the on-premises OAuth2 provider.

If your on-prem Habitat Builder cluster is backed by cloud services and you are running multiple frontend instances, set `OAUTH_REDIRECT_URL` to your load balancer URL.

In the case that you are _not_ backing your cluster with cloud services you will need to update the values of `POSTGRES_HOST`, and `MINIO_ENDPOINT`.

Additionally, you will need to edit (or create if it is not already present) `HAB_BLDR_PEER_ARG` to include all frontend and backend nodes hosting builder services. The format is as follows:

```shell
--peer host1 --peer host2 --peer host3
```

### Install frontend

Run the frontend install script from each new frontend node `./install.sh --install-frontend`
