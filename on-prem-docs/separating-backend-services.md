# Separating Backend Services (minio/postgresql)

The on-prem-builder install.sh script now supports separation of the backend components i.e datastore and minio server onto different nodes.
You can now have a setup where the postgresql service runs on one node and minio runs on another. Both can be designed to communicate to one another and to a third or more nodes running the front-end services. 

## Pre-requisites
The bldr.env file for your single on-prem builder node contains most of the information required setup minio and postgresql on it and will be used during the installation process.

For the setting up the minio server on a separate node, make sure that `S3_ENABLED` and `ARTIFACTORY_ENABLED` in the bldr.env are set to `false`.
This must be ensured as minio server can not be used if you are using S3 or Artifactory directly.

For the setting up the datastore on a separate node, make sure that `PG_EXT_ENABLED` in the bldr.env is set to `false`.
This must be ensured as the Datastore node cannot have externally hosted PostgreSQL(RDS, Azure Database for PostgreSql etc).

Please refer our [scaling documentation](./scaling.md#deploying-new-front-ends) for detailed information regarding opening the ports.

Additionally, you will need to edit (or create if it is not already present) `HAB_BLDR_PEER_ARG` to include all frontend and backend nodes hosting builder services. The format is as follows:

```
--peer host1 --peer host2 --peer host3
```

## Separating MinIO Server
MinIO is an open source object storage server. Chef Habitat Builder on-prem uses Minio to store habitat artifacts (.harts).

### Install Minio
Run the minio install script from the new node that will run the minio service to store all the artifacts 
```bash
./install.sh --install-minio
```

### Connecting to Minio server node
Now that your Minio server is up and running on its own node, it is crucial to know how to connect your other backend and frontend nodes to it.
The `MINIO_ENDPOINT` in the bldr.env file has to be mapped to the Node where the Minio server is running.
You can then access the Minio UI using the `MINIO_ENDPOINT` URL.

## Separating postgresql
The backend datastore can also be setup to run on a separate node.

### Install postgresql
Run the postgresql install script from the the node
```bash
./install.sh --install-postgresql
```

### Connecting to Datastore node
The bldr.env of the nodes have to modified in order to connect to the datastore running on a different node. Following are the fields that have to be updated onto the nodes that are trying to connect to the Datastore:

* `PG_EXT_ENABLED` has to be set to true
* `POSTGRES_HOST` has to be mapped to the Node where the Datastore is running

#### NOTE: Please refer this [documentat](./scaling.md) for setting up and scaling the front end.