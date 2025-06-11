# Builder on-prem + Minio

Managing your Minio artifact store.

[MinIO](https://min.io/) is an open source object storage server. Chef Habitat Builder on-prem uses Minio to store habitat artifacts (.harts).

## Managing Builder On-Prem Artifacts

The data that Builder stores is luckily fairly lightweight and thus the backup and DR or Warm Spare strategy is pretty straightforward. On-Prem Builder has two types of data that should be backed up case of a disaster:

1. [PostgreSQL package and user metadata](./postgres.md#postgresql-data-backups)
1. Minio habitat artifacts (.harts)

Chef Habitat Builder on-prem supports only Minio artifact repositories.

Ideally, you should coordinate the backup of the entire Builder on-prem cluster to happen together. However, the type of data that Builder stores (metadata and artifacts) permits some flexibility in the timing of your backup operations.

### Minio Artifact Backups

The process of artifact backups is quite a bit more environmentally subjective than Postgres if only because we support more than one artifact storage backend. For the sake of these docs we will focus on Minio backups.

Backing up Minio is also a bit subjective but more or less amounts to a filesystem backup. Because Minio stores its files on the filesystem (unless you're using a non-standard configuration) any filesystem backup strategy you want to use should be fine whether taking disk snapshots of some kind or data  mirroring, and rsync. Minio however also has the [minio client](https://docs.min.io/docs/minio-client-quickstart-guide.html) which provides a whole boatload of useful features and specifically allows the user to mirror a bucket to an alternative location on the filesystem or even a remote S3 bucket! Ideally you should _never_ directly/manually manipulate the files within Minio's buckets while it could be performing IO. Which means you should _always_ use the Minio client mentioned above to manipulate Minio data.

A simple backup strategy might look like this:

1. Shut down the API to ensure no active transactions are occurring. (Optional but preferred)
        `hab svc stop habitat/builder-api`
1. Mirror Minio data to an AWS S3 bucket. **
        `mc mirror <local/minio/object/dir> <AWS_/S3_bucket>`
** Another option here is to mirror to a different part of the filesystem, perhaps one that's NFS mounted or the like and then taking snapshots of it:
        `mc mirror <local/minio/object/dir> <new/local/path>

As mentioned before since this operation could be dramatically different for different environments Minio backup cannot be 100% prescriptive. But This should give you some ideas to explore.
