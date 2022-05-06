# Scaling

## Front-end Scaling
With any tiered or HA deployment of the builder services you'll likely want to horizontally scale your front-end nodes. The most common deployment pattern for this usecase is a pool of front-end nodes fronted by a load-balancer.

## Deploying New Front-ends, Minio and Datastore
The on-prem-builder install.sh script now supports scaling front-end nodes as a deployment pattern. It is required that new front-ends be deployed on a separate compute from your initial on-prem deployment. The install.sh script also supports scaling of datastore and minio server. Since builder services will now need to communicate accross your network between the frontend and backend nodes, you must open the folowing ports to these nodes in order to guarantee your on-prem builder properly functions:

* TCP 9638 - Habitat configuration gossip
* UDP 9638 - Habitat configuration gossip
* TCP 9636 - Builder API HTTP
* TCP 5432 - postgresql
* TCP 9000 - minio
* TCP 11211 - memcached
* TCP 5566 to 5568 - jobserver

### Create and update bldr.env
The bldr.env file for your single on-prem builder node contains most of the information required to bootstrap a new front-end, minio or datastore and will be used during the installation process. However, some configuration will need to change.

In the case that your on-prem-builder cluster is backed by cloud services, you will need to update the value of `OAUTH_REDIRECT_URL`. When running multiple front-end instances this value should be pointed to your load-balancer. 

In the case that you are _not_ backing your cluster with cloud services you will need to update the values of `OAUTH_REDIRECT_URL`, `POSTGRES_HOST`, and `MINIO_ENDPOINT`.

Additionally, you will need to edit (or create if it is not alreadu present) `HAB_BLDR_PEER_ARG` to include all frontend and backend nodes hosting builder services. The format is as follows:

```
--peer host1 --peer host2 --peer host3
```

#### For Connecting to Datastore
The bldr.env of the nodes have to modified in order to connect to the datastore running on a different node. Following are the fields that have to be updated onto the nodes that are trying to connect to the Datastore:

* `PG_EXT_ENABLED` has to be set to true
* `PG_USER` has to be set to `hab`
* `PG_PASSWORD` has to be correctly updated
* `POSTGRES_HOST` has to be mapped to the Node where the Datastore is running

#### For Connecting to Minio
The bldr.env of the nodes have to modified in order to connect to the minio running on a different node. Following are the fields that have to be updated onto the nodes that are trying to connect to the Minio Server:

* `MINIO_ENDPOINT` has to be mapped to the Node where the Minio server is running

### Install frontend
Run the front-end install script from each new front-end node `./install.sh --install-frontend`

### Install Datastore
Run the postgresql install script from the new datastore node `./install.sh --install-postgresql`

### Install Minio
Run the minio install script from the new node that is suppose to run the minio service to store all the artifacts `./install.sh --install-minio`
