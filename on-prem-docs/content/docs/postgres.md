+++
title = "Postgres Migration"
description = "Updating your Postgres Installation"
draft = false
bref = ""
toc = true
+++

## Merging Database Shards

This section is for installations of On-Premise Depot that were done *prior* to
August 17th 2018. If you re-install or upgrade to a newer version of the
On-Premise Depot, you will be required to also merge your database shards into
the `public` Postgres database schema. Please follow the steps below.

### Shard Migration Pre-requisites

1. The password to your Postgres database. By default, this is located at
   `/hab/svc/builder-datastore/config/pwfile`
1. A fresh backup of the two databases present in the On-Premise Depot,
   `builder_sessionsrv` and `builder_originsrv`. You can create such a backup
   with `pg_dump`:

   ```shell
   PGPASSWORD=$(sudo cat /hab/svc/builder-datastore/config/pwfile) hab pkg exec core/postgresql pg_dump -h 127.0.0.1 -p 5432 -U hab builder_originsrv > builder-originsrv.sql
   ```

### Shard Migration

1. Uninstall existing services by running `sudo -E ./uninstall.sh`
1. Install new services by running `./install.sh`
1. If you check your logs at this point, you will likely see lines like this:
   `Shard migration hasn't been completed successfully` repeated over and over
   again, as the supervisor tries to start the new service, but the service
   dies because the migration hasn't been run.
1. Optionally, if you want to be extra sure that you're in a good spot to perform the
   migration, log into the Postgres console and verify that you have empty
   tables in the `public` schema. A command to do this might look like:

   ```shell
   PGPASSWORD=$(sudo cat /hab/svc/builder-datastore/config/pwfile) hab pkg exec core/postgresql psql -h 127.0.0.1 -p 5432 -U hab builder_originsrv
   ```

   That should drop you into a prompt where you can type `\d` and hopefully see
   a list of tables where the schema says `public`. If you try to select data
   from any of those tables, they should be empty. Note that this step is
   definitely not required, but can be done if it provides you extra peace of
   mind.
1. Now you are ready to migrate the data itself. The following command will do
   that for `builder-originsrv`:

   ```shell
   PGPASSWORD=$(sudo cat /hab/svc/builder-datastore/config/pwfile) ./scripts/merge-shards.sh originsrv migrate
   ```

   After confirming that you have fresh database backups, the script
   should run and at the end, you should see several notices that everything is
   great, row counts check out, and your database has been marked as migrated.
1. Do the same migration for `builder-sessionsrv`.

   ```shell
   PGPASSWORD=$(sudo cat /hab/svc/builder-datastore/config/pwfile) ./scripts/merge-shards.sh sessionsrv migrate
   ```

1. Double check the logs for `builder-originsrv` and `builder-sessionsrv` to
   make sure things look normal again. If there are still errors, restart the
   services.
1. At this point, all data is stored in the `public` schema. All of the other
   schemas, from `shard_0` up to `shard_127` will still be present in your
   database, and the data in them will remain intact, but the services will no
   longer reference those shards.

## Merging Databases

This section is for installations of On-Premise Depot that were done *after*
the database shard migration listed above. If upgrade to a newer version of the
On-Premise Depot, you will be required to also merge databases into
the `builder` Postgres database. Please follow the steps below.

### Database Merge Pre-requisites

1. The password to your Postgres database. By default, this is located at
   `/hab/svc/builder-datastore/config/pwfile`
1. A fresh backup of the two databases present in the On-Premise Depot,
   `builder_sessionsrv` and `builder_originsrv`. You can create such a backup
   with `pg_dump`:

   ```shell
   PGPASSWORD=$(sudo cat /hab/svc/builder-datastore/config/pwfile) hab pkg exec core/postgresql pg_dump -h 127.0.0.1 -p 5432 -U hab builder_originsrv > builder-originsrv.sql
   ```

### Database Merge Migration

1. With all services running your *current* versions, execute the following command from the root of the repo directory:

   ```shell
   PGPASSWORD=$(sudo cat /hab/svc/builder-datastore/config/pwfile) ./scripts/merge-databases.sh
   ```

   After confirming that you have fresh database backups, the script
   should run and create a new 'builder' database, and then migrate the data.
1. At this point, all data is stored in the `builder` database. Both of the other
   databases (`builder_originsrv` and `builder_sessionsrv`) will still be present,
   and the data in them will remain intact, but new services will no
   longer reference those databases.
1. Now, stop and uninstall the existing services by running `sudo -E ./uninstall.sh`
1. Install new services by running `./install.sh`
1. Once the new services come up, you should be able to log back into the depot UI and confirm that everything is as expected.
