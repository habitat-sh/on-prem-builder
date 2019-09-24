# Migrating Package Artifacts to Minio

This section is for installations of On-Premise Depot that were done *prior* to June 15, 2018. If you re-install or upgrade to a newer version of the On-Premise Depot, you will be required to also migrate your package artifacts to a local instance of Minio (the new object store we are using). Please follow the steps below.

## Pre-requisites
1. Install the following Habitat packages:
```
hab pkg install -b core/aws-cli
hab pkg install -b core/jq-static
hab pkg install -b habitat/s3-bulk-uploader
```
If you are running in an "air-gapped" environment, you may need to download the hart files and do a `hab pkg install -b <HART FILE>` instead.  Don't forget the `-b` parameter to binlink the binaries into your path.
1. Please make sure that you have appropriate values for Minio in your `bldr.env`.  Check the 'bldr.env.sample' for the new required values.

## Migration
1. Run the `install.sh` script so that Minio is appropriately configured
1. Check that you can log into your Minio instance at the URL specified in the `bldr.env`
1. If all looks good, run the artifact migration script: `sudo ./scripts/s3migrate.sh minio`

Once the migration script starts, you will be presented with some questions to specify the Minio instance, the credentials, and the Minio bucket name to migrate your package artifacts to. The script will attempt to automatically detect all of these from the running service, so you can usually just accept the defaults. Please refer to your `bldr.env` file if you need to explicitly type in any values.

The migration script may take a while to move over the artifacts into Minio. During the script migration, the Depot services will continue to run as normal, however packages will not be downloadable until the artifacts are migrated over to Minio.

Once the migration is complete, you will be presented with an option to remove the files in your `hab/svc/builder-api/data/pkgs` directory. You may want to preserve the files until you have verified that all operations are completing successfully.
