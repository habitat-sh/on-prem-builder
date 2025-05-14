+++
title = "Separate backend services (minio/postgresql)"

[menu]
  [menu.habitat]
    title = "Separating backend services"
    identifier = "habitat/builder/on-prem/Separating backend services"
    parent = "habitat/builder/on-prem"
    weight = 20
+++

The on-prem [Habitat Builder `install.sh` script](https://github.com/habitat-sh/on-prem-builder/blob/main/install.sh) allows you to separate the backend components (the datastore and MinIO server) onto different nodes.
You can setup PostgreSQL service on one node and MinIO on another.
Both can be configured to communicate with other nodes running the frontend services.

## Configure Habitat Builder

The `bldr.env` file contains all of the information required to setup MinIO and PostgreSQL and will be used during the installation process.

1. If your node has already had an older instance of on-prem Builder components on it, run the [`uninstall.sh` script](https://github.com/habitat-sh/on-prem-builder/blob/main/uninstall.sh) on your node to clean up your environment:

  ```bash
  ./uninstall.sh
  ```

1. Create a copy of the [`bldr.env.sample` file](https://github.com/habitat-sh/on-prem-builder/blob/main/bldr.env.sample) and save it to `bldr.env`:

    ```bash
    cp bldr.env.sample bldr.env
    ```

1. Modify the `bldr.env` file with the following settings:

   1. Make sure that `S3_ENABLED` and `ARTIFACTORY_ENABLED` are set to `false`.

      MinIO server can't be used if you are using S3 or Artifactory directly.

   1. Set `PG_EXT_ENABLED` to `false`.

      The datastore node can't have an externally hosted PostgreSQL. For example on AWS RDS or Azure Database for PostgreSQL.

      See [scaling documentation](./scaling.md#deploying-new-front-ends) for detailed information regarding opening the ports.

   1. Set `HAB_BLDR_PEER_ARG` to include all frontend and backend nodes hosting builder services. The format is as follows:

      ```shell
      --peer <host1> --peer <host2> --peer <host3>
      ```

## Separate MinIO Server

MinIO is an open source object storage server.
Chef Habitat Builder on-prem uses MinIO to store Habitat artifact files (`.harts`).

1. On the new node that will run the MinIO service, install MinIO by running the MinIO install script:

    ```bash
    ./install.sh --install-minio
    ```

1. Connect to the MinIO server node by setting the `MINIO_ENDPOINT` in the `bldr.env` file to the node where the MinIO server is running.


## Separate PostgreSQL

The backend datastore can also be setup to run on a separate node.

1. Install PostgreSQL by running the PostgreSQL install script on the node:

    ```bash
    ./install.sh --install-postgresql
    ```

1. Connect to datastore node

The value of `POSTGRES_HOST` in the `bldr.env` file on the frontend nodes must be mapped to the Node where the Datastore service is running in order to connect to it.

## More information

For setting up and scaling the frontend, see the [Habitat Builder scaling](./scaling.md) documentation.
