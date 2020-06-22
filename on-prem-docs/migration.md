# Migrate to a Deployment of Automate Builder

Long Term Support for On-Prem Builder is provided for installations of [Builder via Chef Automate](https://automate.chef.io/docs/on-prem-builder/).
This document will guide you through the steps necessary to migrate your On-Prem Builder data into an Automate Builder.

NOTE: The migration will overwrite any existing data in Automate Builder (target) with the data from your current On-Prem (source) installation. The assumption is that the Automate Builder target node is not yet in use.

## Preparing for a Migration

The data that Builder stores is fairly lightweight and thus the migration strategy is pretty straightforward. On-Prem Builder has two types of data that will need to be migrated:

1. Minio/S3 habitat artifacts
1. PostgreSQL package and user metadata

The minio/S3 data will be copied to the Automate Builder target via minio mirroring utility.

The migration of the PostgreSQL data will be done via a `pg_dump` on the source and then restoring with `psql` on the target.

### Creating a fallback copy of Chef Automate Builder data

Since the data migration is destructive and will overwrite any previous Builder data on the target, perform a backup in case the original state needs to be restored:

```
sudo chef-automate backup create
```

### Validating Versions

It is the Builder API that runs database migrations and is responsible for making schema changes, ensuring that the PostgreSQL tables are all up to date.
Check that your target Automate Builder instance is running the same or newer Builder API version than your current On-Prem Builder (source). This is required to ensure that there are no PostgreSQL schema incompatibilities. The Builder API service on the target Automate Builder node will run any migrations necessary to update the PostgreSQL data and schemas to the correct format. Therefore the Automate Builder target must be the same or newer version.

To check the API version installed on the source and target Builder nodes run:

```
hab pkg path habitat/builder-api
```

The versions on the target must be equal or newer to the source version.

If it is not, perform an upgrade for target as follows:

* Automate Builder [upgrades](https://automate.chef.io/docs/install/#upgrades).

## Minio Artifact (.hart) Migration

Whether your source package files are in Minio or in S3, you can leverage the [minio client](https://docs.min.io/docs/minio-client-quickstart-guide.html) to perform what more or less amounts to a filesystem backup that you will then restore into the target Minio. You are going to create a copy of the Minio data on another filesystem or directory that can either be copied to or mounted on the target Automate Builder node.

### Creating a Minio Backup Copy

A simple backup process of the source Builder Minio data might look like this:

1. Shut down the API to ensure no active transactions are occurring. (Optional but preferred)

  ```
   hab svc stop habitat/builder-api`
  ```

1. Mirror the minio data to a different directory that has adequate space

   ```
   sudo mkdir /opt/data/minio_backup
   sudo ./mc mirror /hab/svc/builder-minio/data/habitat-builder-artifact-store.local /opt/data/minio_backup
   sudo tar cvf /opt/data/minio_backup.tar /opt/data/minio_backup
  ```

1. Start the API service back up if it was stopped

  ```
   hab svc start habitat/builder-api`
  ```

### Importing the Minio Backup Copy

Use the following steps in order to sync the Minio package data into the target Automate Builder. This will overwrite any existing data that is in the Automate Builder Minio depot. Create a backup first `sudo chef-automate backup create` if one does not already exist.

1. Copy the minio directory backup to the target Automate Builder node and expand the .tar

   ```
   tar xvf minio_backup.tar
   ```

1. Once the data is expanded into a directory on the target Automate Builder node use Minio client to mirror it into the Minio service directory

   ```
   sudo ./mc mirror minio_backup/ /hab/svc/automate-minio/data/depot
   ```

1. Fix the Minio data directory ownership

   ```
   sudo chown -R hab:hab /hab/svc/automate-minio/data/depot
   ```

The artifact data should now be available for use!

As mentioned before, since the Minio backup/import operation could be dramatically different for different environments, the Minio backup steps cannot be 100% prescriptive. This should give you some ideas to explore though.

## PostgreSQL Data Copy

Create a copy of the source Builder's PostgreSQL database by following these steps:

1. Shut down the API to ensure no active transactions are occurring. (Optional but preferred)

    ```
    sudo hab svc stop habitat/builder-api
    ```

1. Export the hab user's PostgreSQL password

    ```
    export PGPASSWORD=$(sudo cat /hab/svc/builder-datastore/config/pwfile)
    ```

1. Run the `pg_dump` command to create a data backup/copy

    ```
    hab pkg exec core/postgresql pg_dump --user=hab --host=127.0.0.1 --dbname=builder --clean --encoding=utf8 --if-exists | gzip > pgdump.gz
    ```

1. Start the API service and verify

    ```
    sudo hab svc start habitat/builder-api
    sudo hab svc status
    ```

1. Copy the `pgdump.gz` file to the target in preparation for an import of the data on that node

## Import the PostgreSQL Data into the Target Automate Builder

Next, import the PostgreSQL data from the `pgdump.gz` into the target Automate Builder.
Keep in mind that this will overwrite any existing data so ensure you have first created a backup via `sudo chef-automate backup create`.

Follow these steps on the target Automate Builder node:

1. Temporarily prevent the auto converge loop from restarting services

   ```
   sudo chef-automate dev stop-converge
   ```

1. Stop the Builder API

   ```
   sudo hab stop chef/automate-builder-api
   ```

1. Kill off any lingering processes still connected to PostgreSQL

  ```
  sudo pkill -9 -f "postgres: automate-builder-api"
  ```

1. Rename the old database - you can drop it later if desired.

  ```
  sudo hab pkg exec chef/automate-platform-tools pg-helper rename-if-exists automate-builder-api automate-builder-api.orig -c /hab/svc/automate-gateway/config/service.crt -k /hab/svc/automate-gateway/config/service.key -r /hab/svc/automate-gateway/config/root_ca.crt
  ```

1. Create an empty database

   ```
   sudo hab pkg exec chef/automate-platform-tools pg-helper ensure-service-database automate-builder-api automate-builder-api -c /hab/svc/automate-gateway/config/service.crt -k /hab/svc/automate-gateway/config/service.key -r /hab/svc/automate-gateway/config/root_ca.crt
   ```

1. Import the data captured from the source Builder into the target Builder. There should not be any errors from this command.

   ```
   gunzip -c pgdump.gz | sed -e "s/OWNER TO hab/OWNER TO \"automate-builder-api\"/" | sudo chef-automate dev psql automate-builder-api
   ```

1. If all went well and there were no errors, restart the converge loop to re-enable all the services:

   ```
   sudo chef-automate dev start-converge
   ```

Your database data should be restored and ready for use! Log into the web UI and verify all your origin, package and user metadata exists.

## Validation

A package download operation is an easy way to validate PostgreSQL and Minio data are valid

1. Download a package from the target Automate Builder

  ```
   hab pkg download core/acl --url https://localhost/bldr/v1 --download-directory downloads
  ```

### Troubleshooting

If you need to go into the database on the target Automate Builder node for any reason, such as perhaps to interrogate some account tables you can use the following command which will drop you into a sql shell

```
sudo chef-automate dev psql automate-builder-api
```

If you need to restore a fallback backup that you made prior to a migration you can run a restore

```
sudo chef-automate backup list
sudo chef-automate backup restore <id>
```
