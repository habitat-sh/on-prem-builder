+++
title = "Configure Chef Habitat Builder disaster recovery or warm spare"

[menu]
  [menu.habitat]
    title = "Disaster recovery"
    identifier = "habitat/builder/on-prem/disaster recovery"
    parent = "habitat/builder/on-prem"
    weight = 20
+++

<!---

Move this elsewhere

# High Availability

Currently, the only supported HA solution is by using SaaS backend services (AWS RDS, AWS S3).
There is no other fully on-prem supported solution for providing highly available Builder services.

--->

How create a disaster recover or warm spare configuration

To quickly recover from an outage or perform planned upgrades or maintenance, you can use a warm spare or disaster recovery installation.

The following architecture diagram shows the data synchronization process that increases the availability of the Builder API and backend for disaster recovery and warm spare scenarios.

![onprem architecture](../images/builder_architecture.png)

## Synchronize components

To enable the disaster recovery or warm spare deployment, you need to provision an equal number of frontend and backend systems as your primary location. These systems will serve as your disaster recovery or warm spare environment. For disaster recovery, they should exist in a separate availability zone with separate storage.

The data that Builder stores is lightweight, so the backup and disaster recovery or warm spare strategy is straightforward. Habitat Builder has two types of data that you should back up in case of a disaster or workload transfer to a warm spare:

- PostgreSQL package and user metadata
- Habitat artifacts (.harts)

Back up or replicate all data using highly available storage subsystems as described in the following sections.

Coordinate the entire Builder on-prem cluster backup to happen together.
However, the type of data that Builder stores (metadata and artifacts) allows some flexibility in the timing of your backup operations. In the worst case, if a package's metadata is missing from PostgreSQL, you can repopulate it by re-uploading the package with the `--force` flag. For example: `hab pkg upload <PATH_TO_HART_FILE> -u <ON_PREM_URL> --force`.

### PostgreSQL

If you are using AWS RDS, take periodic snapshots of the RDS instance.
For disaster recovery, you can use a Multi-AZ RDS deployment.

For non-RDS deployments, back up the PostgreSQL data as described in the [Builder PostgreSQL configuration](./postgres.md#postgresql-data-backups) documentation.

You should periodically restore the backups into the disaster recovery or warm spare environment using a scheduled automated process, such as a crontab script. You can run the restore remotely from the same host that created the backup. The Builder database is relatively small, likely only tens of megabytes.

### Habitat artifacts

Habitat artifacts are stored in one of two locations:

- MinIO
- S3 bucket

If your backend uses MinIO for artifact storage and retrieval, it should be backed by highly available storage.
Back up MinIO data as described [Habitat Builder MinIO](./minio.md#managing-builder-on-prem-artifacts) documentation.
If you choose a warm spare deployment in the same availability zone or data center and the filesystem is a network-attached filesystem, you can also attach it to the warm spare.
However, make sure that only one Builder cluster is accepting live traffic when sharing the same filesystem.
For disaster recovery, replicate the filesystem to the alternate availability zone or data center.

If artifacts are stored directly in an S3 bucket, you can use the same bucket for a warm spare in the same availability zone or data center.
For disaster recovery, replicate the S3 bucket to the alternate availability zone or data center.
For AWS S3, this replication is already built into the service.

If you are not re-attaching the MinIO filesystem to the warm spare, periodically restore the backups into the disaster recovery or warm spare environment using a scheduled automated process, such as a crontab script.
