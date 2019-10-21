# Chef Habitat Builder on-prem

**Umbrella Project**: [Chef Habitat](https://github.com/habitat-sh/habitat)

**Project State**: [Active](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#active)

**Issues Response SLA**: 5 business days

**Pull Request Response SLA**: 5 business days

## IMPORTANT NOTICE

Please see the [Migrating Package Artifacts to Minio](minio-migration.md) if your existing Chef Habitat Builder on-prem was installed *prior* to June 15th 2018. The package artifacts are now stored in a Minio instance, and running a migration script will be required in order to properly transition over to newer versions of Chef Habitat Builder on-prem.

Please see the [Merging database shards](postgres.md#merging-database-shards) section if
your existing Chef Habitat Builder on-prem was installed *prior* to August 17th 2018. All
of the database schemas and data are now stored in the Postgres `public`
schema, instead of spread across various shard schemas.

Please see the [Merging databases](postgres.md#merging-databases) section if
your existing Chef Habitat Builder on-prem was installed *prior* to September 24th 2018. All
data is now stored in a single Postgres database `builder` instead of spread across
multiple databases.

## Introduction

This repository contains scripts to install Chef Habitat Builder on-prem services. These services (referred to as the Chef Habitat Builder on-prem) allow privately hosting Chef Habitat packages (and associated artifacts such as keys) on-premise. Chef Habitat clients (such as the `hab` cli, Supervisors and Studios) can be pointed to the Chef Habitat Builder on-prem and allow for development, execution and management without depending on the public Chef Habitat services.

## Audience

This repository is intended for use by any one who wishes to host Chef Habitat packages in their own infrastructure. Users should be prepared to actively update their installations to benefit from continued improvements and updates.

## Requirements

The following are minimum requirements for installation/deployment of the Chef Habitat Builder on-prem:

* Services should be deployed on a Chef Habitat supported [Linux OS](https://www.habitat.sh/docs/install-habitat/)
* OS should support `systemd` process manager
* Deployment to bare-metal, VM or container image
* CPU / RAM should be appropriate for the deployment purpose:
  * 2 CPU/4 GB RAM for trial deployments
  * 16 CPU/32 GB RAM for production deployments
* Significant free disk space
  * 2GB for the baseline Chef Habitat Builder on-prem services
  * 15GB+ for the latest Chef Habitat Builder core packages
  * 30GB+ for downloading and expanding the core package bootstrap in the volume containing the `/tmp` directory
* We recommend:
  * 20 GB disk space for trial deployments
  * 100 GB disk space for production deployments
* Deploy services single-node - scale out is not yet supported
* Outbound network (HTTPS) connectivity to WAN is required for the _initial_ install
* Inbound network connectivity from LAN (HTTP/HTTPS) is required for internal clients to access the Chef Habitat Builder on-prem
* OAuth2 authentication provider (Chef Automate v2, Azure AD, GitHub, GitHub Enterprise, GitLab, Okta and Bitbucket (cloud) have been verified - additional providers may be added on request)

## Functionality

Once installed, the following functionality will be available to users:

* Logging into the Chef Habitat Builder on-prem web site
* Creation of origins, keys, access tokens, etc
* Invitation of users to origins
* Upload and download of Chef Habitat packages
* Promotion and demotion of Chef Habitat packages to channels
* Normal interactions of the `hab` client with the Chef Habitat Builder API
* Package builds using the `hab` client and Chef Habitat Studio
* Ability to import core packages from the upstream Chef Habitat Builder

The following Chef Habitat Builder on-prem functionalities are *NOT* currently available:

* Automated package builds using Chef Habitat Builder on-prem
* Automated package exports using Chef Habitat Builder on-prem

## Pre-Requisites

Prior to starting the install, please ensure you have reviewed all the items
in the Requirements section, and have a location for the installation that
meets all the requirements.

Note that the initial install will require _outgoing_ network connectivity.

Your Chef Habitat Builder on-prem instance will need to have the following _inbound_ port open:

* Port 80 (or 443 if you plan to enable SSL)

You may need to work with your enterprise network admin to enable the appropriate firewall rules.

### OAuth Application

We currently support Chef Automate v2, Azure AD (OpenId Connect), GitHub, GitLab (OpenId Connect), Okta (OpenId Connect) and Atlassian Bitbucket (cloud) OAuth providers for authentication. You will need to set up an OAuth application for the instance of the Chef Habitat Builder on-prem you are setting up.

Refer to the steps that are specific to your OAuth provider to create and configure your OAuth application. The below steps illustrate setting up the OAuth application using Github as the identity provider:

1. Create a new OAuth Application in your OAuth Provider - for example, [GitHub](https://github.com/settings/applications/new)
1. Set the homepage url value of `APP_URL` to `http://${BUILDER_HOSTNAME_OR_IP}/`, or `https://${BUILDER_HOSTNAME_OR_IP}/` if you plan to enable SSL.
1. Set the callback url value of `OAUTH_REDIRECT_URL` to `http://${BUILDER_HOSTNAME_OR_IP}/` (The trailing `/` is *important*). Specify `https` instead of `http` if you plan to enable SSL.
1. Record the the Client Id and Client Secret. These will be used for the `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` environment variables in the section below.

For the configuration below, you will also need to know following *fully qualified* end-points:

* Authorization Endpoint (example: `https://github.com/login/oauth/authorize`)
* Token Endpoint (example: `https://github.com/login/oauth/access_token`)
* API Endpoint (example: `https://api.github.com/user`)

For more information, please refer to the developer documentation of these services:

* [Chef Automate (ALPHA)](https://automate.chef.io/docs/configuration/#alpha-setting-up-automate-as-an-oauth-provider-for-habitat-builder)
* [Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-protocols-oauth-code)
* [GitHub](https://developer.github.com/apps/building-oauth-apps/authorization-options-for-oauth-apps/)
* [GitLab](https://docs.gitlab.com/ee/integration/oauth_provider.html)
* [Okta](https://developer.okta.com/authentication-guide/implementing-authentication/auth-code)
* [BitBucket](https://confluence.atlassian.com/bitbucket/oauth-on-bitbucket-cloud-238027431.html)

For further information on OAuth endpoints, see the Internet Engineering Task Force (IETF) RFC 6749, [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749), page 21.

### Preparing your filesystem (Optional)

Since substantial storage may be required for holding packages, please ensure you have an appropriate amount of free space on your filesystem.

The package artifacts will be stored in your Minio instance by default, typically at the following location: `/hab/svc/builder-minio/data`

If you need to add additional storage, it is recommended that you create a mount at `/hab` and point it to your external storage. This is not required if you already have sufficient free space.

*Note*: If you would prefer to use Artifactory instead of Minio for the object storage, please see the [Artifactory](artifactory.md) documentation.

### Procuring SSL certificate (Recommended)

By default, the Chef Habitat Builder on-prem will expose the web UI and API via http. Though it allows for easier setup and is fine for evaluation purposes, for a secure and more permanent installation it is recommended that you enable SSL on the Chef Habitat Builder endpoints.

In order to prepare for this, you should procure a SSL certificate. If needed, you may use a self-signed certificate - however if you do so, you will need to install the certificate in the trusted chain on client machines (ones that will use the Chef Habitat Builder UI or APIs). You may use the `SSL_CERT_FILE` environment variable to also point to the certificate on client machines when invoking the `hab` client, for example:

```bash
SSL_CERT_FILE=ssl-certificate.crt hab pkg search -u https://localhost <search term>
```

Below is a sample command to generate a self-signed certificate with OpenSSL:

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-certificate.key -out /etc/ssl/certs/ssl-certificate.crt
```

*Important*: Make sure that the certificate files are named exactly `ssl-certificate.key` and `ssl-certificate.crt`. If you have procured the certificate from a different source, rename them to the prescribed filenames, and ensure that they are located in the same folder as the `install.sh` script. They will get uploaded to the Chef Habitat supervisor during the install.

### Airgapped Installation (Recommended prep work, if airgapped)

In order to install the on-prem Chef Habitat Builder in an airgapped (no direct Internet access) environment, the following preparatory steps are helpful:

1. Download the [Zip archive](https://github.com/habitat-sh/on-prem-builder/archive/master.zip) of the on-prem-builder repo
1. Download the Chef Habitat [cli tool](https://api.bintray.com/content/habitat/stable/linux/x86_64/hab-%24latest-x86_64-linux.tar.gz?bt_package=hab-x86_64-linux)
1. Create the Habitat Builder starter kit bundle and download it

     ```bash
     git clone https://github.com/habitat-sh/on-prem-builder.git
     cd on-prem-builder
     hab pkg download --target x86_64-linux --channel stable --file quickstart_lists/builder_x86_64-linux_stable --download-directory ${HOME}/builder_starter_kit`
     ```

1. Create any additional starter kit Builder bootstrap bundles as documented in the [Bootstrap Builder](https://github.com/habitat-sh/on-prem-builder/tree/master#bootstrap-builder-with-habitat-packages) section of this README. You can specify `--download-directory ${HOME}/builder_bootstrap` argument to the download command in order to consolidate all bootstrap packages in a single directory
1. Zip up all the above, transfer and unzip on the Linux system where Builder will be deployed
1. From the zip archive, install the `hab` binary somewhere in $PATH and ensure it has execute permissions:

     ```bash
     sudo chmod 755 /bin/hab
     ```

1. Import the public package signing keys from the downloaded Builder starter kit:

     ```bash
     for file in $(ls builder_starter_kit/keys/*pub); do cat $file | sudo hab origin key import; done
     ```

1. Create a Habitat artifact cache directory, place the Builder starter kit .hart packages into that directory and then pre-install the Builder Services:

     ```bash
     sudo mkdir -p /hab/cache/artifacts
     sudo mv builder_start_kit/artifacts/*hart /hab/cache/artifacts
     sudo hab pkg install /hab/cache/artifacts/habitat-builder*hart
     ```

1. Pre-install the Habitat Supervisor and its dependencies:

     ```bash
     sudo hab pkg install --binlink --force /hab/cache/artifacts/core-hab-*hart
     ```

## Setup

1. Clone this repo (or unzip the archive you have downloaded from the Github release page) at the desired machine where you will stand up the Chef Habitat Builder on-prem
1. `cd ${SRC_ROOT}`
1. `cp bldr.env.sample bldr.env`
1. Edit `bldr.env` with a text editor and replace the values appropriately. Consider helping us to improve Chef Habitat as well by changing the `ANALYTICS_ENABLED` setting to `true` and providing an optional company name.
1. `./install.sh`

If everything goes well, you should see output similar to the following showing that the Chef Habitat Builder on-prem services are loaded:

```output
hab-sup(AG): The habitat/builder-datastore service was successfully loaded
hab-sup(AG): The habitat/builder-minio service was successfully loaded
hab-sup(AG): The habitat/builder-memcached service was successfully loaded
hab-sup(AG): The habitat/builder-api service was successfully loaded
hab-sup(AG): The habitat/builder-api-proxy service was successfully loaded
```

Do a `hab svc status` to check the status of all the services. They may take a few seconds to all come up.

If things don't work as expected (eg, if all the services are not in the `up` state), please see the Troubleshooting section below.

## Minio Web UI

The Chef Habitat Builder on-prem stores package artifacts in [Minio](https://github.com/minio/minio). By default, the Minio instance will be available on port 9000 (or whatever port you specified in your `bldr.env`). Please confirm that the Minio UI is available, and that you can log in with the credentials that were specified in your `bldr.env` file. There should already be a bucket created in which to host the artifacts.

## Chef Habitat Builder on-prem Web UI

Once the services are running successfully, the Chef Habitat Builder on-prem UI will become available at the configured hostname or IP address.

Navigate to `http://${BUILDER_HOSTNAME_OR_IP}/#/sign-in` to access the Chef Habitat Builder on-prem UI.

At that point you should be able to log in using your configured OAuth provider.

### Create an Origin

Create a `core` origin for an initial set of base packages. Uploads will fail unless you first populate your Chef Habitat Builder on-prem with the upstream `core` upstream origin.

Once you are logged in to the Chef Habitat Builder on-prem UI, select the `New Origin` button and enter in `core` as the origin name.

### Generate a Personal Access Token

Next, generate a Personal Access Token for bootstrapping the `core` packages, as well as for performing authenticated operations using the `hab` client.

Select your Gravatar icon on the top right corner of the Chef Habitat Builder on-prem web page, and then select **Profile**. This will take you to a page where you can generate your access token. Make sure to save it securely.

## Bootstrap Builder with Habitat Packages

Chef Habitat Builder on-prem has no pre-installed package sets. You must populate your Builder instance by uploading packages.
With Habitat *0.88.0*, two new commands were introduced to assist in bootstrapping an on-prem Builder instance with a set of stable packages:

1. *hab pkg download*
1. *hab pkg bulkupload*

As you can see from the commands above, the package Bootstrap flow is comprised of two main phases: a download from the public [SaaS Builder](https://bldr.habitat.sh) followed by a bulkupload to your on-prem Builder instance(s). Historically, we bootstraped on-prem-builders by downloading all the packages in 'core' for all targets. That amounted to ~15GB and was both too much and too little, in that many of the packages weren't needed, and for many patterns (effortless) other origins were needed.

The [new bootstrap process flow](https://forums.habitat.sh/t/populating-chef-habitat-builder-on-prem/1228) allows you to easily customize your Bootstrap package set or use pre-populated [Starter Kit](https://github.com/habitat-sh/on-prem-builder/tree/master/quickstart_lists) files.

The following section illustrates the steps required to bootstrap the on-prem Builder with the [Effortless Linux](https://github.com/habitat-sh/on-prem-builder/blob/master/quickstart_lists/effortless_x86_64-linux_stable) starter kit. Simply repeat the following download/bulkupload flow for the starter kits you think you will need to have in your on-prem Builder, or even create your own custom starter kit file:

1. Phase 1: download

    ```bash
    export HAB_AUTH_TOKEN=<your _public_ Builder instance token>
    cd on-prem-builder
    hab pkg download --target x86_64-linux --channel stable --file quickstart_lists/effortless_x86_64-linux_stable --download-directory builder_bootstrap
    ```

1. Phase 2: bulkupload

     **Important**: Inspect the contents of the `builder_bootstrapi/artifacts` directory created from the download command above. For each of the origins (`core`, `effortless`, etc),  create a matching origin name if one doesn't exist already in the on-prem Builder UI before starting the bulkupload.

    ```bash
    export HAB_AUTH_TOKEN=<your _on-prem_ Builder instance token>
    hab pkg bulkupload --url https://your-builder.tld --channel stable builder_bootstrap/
    ```

## Configuring a user workstation

Configuring a user's workstation to point to the Chef Habitat Builder on-prem should be fairly straightforward.

The following environment variables should be configured as needed:

1. `HAB_BLDR_URL` - this is the main (and most important) configuration. It should point to the instance of Chef Habitat Builder on-prem that you have set up.
2. `HAB_AUTH_TOKEN` - this is the user's auth token that will be needed for private packages (if any), or for operations requiring privileges, for example, package uploads. The user will need to create their auth token and set/use it appropriately.
3. `SSL_CERT_FILE` - if the Chef Habitat Builder on-prem is configured with SSL and uses a self-signed or other certificate that is not in the trusted chain, then this environment variable can be used on the user's workstation to point the `hab` client to the correct certificate to use when connecting to Chef Habitat Builder on-prem.

## Upgrading

Currently, Chef Habitat Builder on-prem services are not set to auto-upgrade. When you wish to upgrade the services, there is a simple uninstall script you can use to stop and unload the services, and remove the services. In order to uninstall, you may do the following:

1. `cd ${SRC_ROOT}`
1. `sudo ./uninstall.sh`

Once the services are uninstalled, you may re-install them by running `./install.sh` again.

*IMPORTANT*: Running the uninstall script will *NOT* remove any user data, so you can freely uninstall and re-install the services.

### Backing up Builder Data

The data that Builder stores is luckily fairly lightweight and thus the backup and DR strategy is pretty straightforward. With On-Prem Builder we have two types of data that a user may want to restore in the case of a disaster. First, the package and user metadata, which gets stored in a PostgreSQL instance and second, habitat artifacts (.harts) which get stored in whichever artifact storage backend you've chosen to use (Minio, S3, Artifactory).

Ideally backups of the Builder cluster would be performed in lock-step however, due to the nature of the data that Builder stores there is very little concern with the timing of this operation. In the worst case if a package's metadata is missing from PostgreSQL, it can easily be repopulated by re-uploading the package with the `--force` flag like so `hab pkg upload <path to hartfile> -u <on-prem_url> --force`

#### Database Backups

Backing up Builder's PostgreSQL database is the same as for any PostgreSQL database. The process is a [pg_dump](https://www.postgresql.org/docs/11/app-pgdump.html). If you have a backup strategy for other production instances of PostgreSQL, then apply your backup pattern to the `builder` database. To backup your `builder` database manually, follow these steps:

1. Shut down the API to ensure no active transactions are occuring. (Optional but preferred)
        `hab svc stop habitat/builder-api`
1. Switch to user `hab`
        `sudo su - hab`
1. Find your Postgres password
        `sudo cat /hab/svc/builder-api/config/config.toml`
1. Export as envvar
        `export PGPASSWORD=<pw>`
1. Run pgdump
        `/hab/pkgs/core/postgresql/<version>/<release>/bin/pg_dump --file=builder.dump --format=custom --host=<ip_of_pg_host> --dbname=builder`
1. Start the api and verify
        `sudo hab svc start habitat/builder-api`

Once the backup finishes,  your will find it as the `builder.dump` file on your filesystem. Move and store this file according to your local policies. We recommend storing it remotely--either physically or virtually--so it will be useable in a worst-case scenario. For most, storing the dump file in an AWS bucket or Azure storage is enough, but you should follow the same strategy for all database backups.

#### Database Restore

Restoring a `builder` database is exactly like restoring any other database--which is to say, there is no magical solution. If you already have a restoration strategy in place at your organization, follow that to restore your `builder` database.  To restore your  data `builder` database manually, follow these steps:

1. Switch to user `hab`
        `sudo su - hab`
1. Find your Postgres password
        `sudo cat /hab/svc/builder-api/config/config.toml`
1. Export as envvar
        `export PGPASSWORD=<pw>`
1. Create the new builder database *
        `/hab/pkgs/core/postgresql/<version>/<release>/bin/createdb -w -h <url_of_pg_host> -p <configured_pg_port> -U hab builder`
1. Verify connectivity to the new database instance
        `/hab/pkgs/core/postgresql/<version>/<release>/bin/psql --host=<url_of_pg_host> --dbname=builder`
1. Restore the dump into the new DB
        `/hab/pkgs/core/postgresql/<version>/<release>/bin/pg_restore --host=<url_of_pg_host> --dbname=builder builder.dump`
1. Start the on-prem Builder services

    > note: In some cases your version of Postgres might not have a createdb binary in which case you'll want to connect to database to run the create db command.

Just like that, your database data should be restored and ready for new transactions!

#### Artifact Backups

The process of artifact backups is quite a bit more environmentally subjective than Postgres if only because we support more than one artifact storage backend. For the sake of these docs we will focus on Minio backups.

Backing up Minio is also a bit subjective but more or less amounts to a filesystem backup. Because Minio stores its files on the filesystem  (unless you're using a non-standard configuration) any filesystem backup strategy you want to use should be fine whether thats disk snapshotting of some kind or data  mirroring, and rsync. Minio however also has the [minio client](https://docs.min.io/docs/minio-client-quickstart-guide.html) which provides a whole boatload of useful features and specifically allows the user to mirror a bucket to an alternative location on the filesystem or even a remote S3 bucket! Ideally you should _never_ directly/manually manipulate the files within Minio's buckets while it could be performing IO. Which means you should _always_ use the Minio client mentioned above to manipulate Minio data.

A simple backup strategy might look like this:

1. Shut down the API to ensure no active transactions are occuring. (Optional but preferred)
        `hab svc stop habitat/builder-api`
1. Mirror Minio data to an AWS S3 bucket. **
        `mc mirror <local/minio/object/dir> <AWS_/S3_bucket>`
** Another option here is to mirror to a different part of the filesystem, perhaps one that's NFS mounted or the like and then snapshotting it:
        `mc mirror <local/minio/object/dir> <new/local/path>

As mentioned before since this operation could be dramatically different for different environments Minio backup cannot be 100% prescriptive. But This should give you some ideas to explore.

What's more, in the case that you're using Artifactory as the artifact store we would highly recommend reading [Artifactory's thoughts on back-ups](https://jfrog.com/whitepaper/best-practices-for-artifactory-backups-and-disaster-recovery/)

## Troubleshooting

### Network access / proxy configuration

If the initial install fails, please check that you have outgoing connectivity, and that you can successfully ping the following:

* `raw.githubusercontent.com`
* `bldr.habitat.sh`

If you have outgoing access via a proxy, please ensure that HTTPS_PROXY is set correctly in your environment.

You also will need to have the following _inbound_ port open for your instance:

* Port 80

In the case that you have configured your proxy for the local session while installing but are still receiving connection refusal errors like the one below, you may want to configure your proxy with the `/etc/environment` file or similar.

```output
-- Logs begin at Mon 2019-06-10 09:02:13 PDT. --
Jun 10 09:35:15 <TargetMachine> hab[13161]: ∵ Missing package for core/hab-launcher
Jun 10 09:35:15 <TargetMachine> hab[13161]: » Installing core/hab-launcher
Jun 10 09:35:15 <TargetMachine> hab[13161]: ☁ Determining latest version of core/hab-launcher in the 'stable' channel
Jun 10 09:35:15 <TargetMachine> hab[13161]: ✗✗✗
Jun 10 09:35:15 <TargetMachine> hab[13161]: ✗✗✗ Connection refused (os error 111)
Jun 10 09:35:15 <TargetMachine> hab[13161]: ✗✗✗
Jun 10 09:35:15 <TargetMachine> systemd[1]: hab-sup.service: Main process exited, code=exited, status=1/FAILURE
Jun 10 09:35:15 <TargetMachine> hab[13171]: Supervisor not started.
Jun 10 09:35:15 <TargetMachine> systemd[1]: hab-sup.service: Unit entered failed state.
Jun 10 09:35:15 <TargetMachine> systemd[1]: hab-sup.service: Failed with result 'exit-code'
```

Please work with your enterprise network admin to ensure the appropriate firewall rules are configured for network access.

### Authentication failure when logging in

If you are not able to log in, please double check the settings that you have configured your OAuth application with, as well as the URLs that you have specified in your `bldr.env` file.

### Unable to retrieve OAuth token

You were able to sign in to the authentication provider, but unable to authenticate with Chef Habitat's OAuth token.

Open the `bldr.env` and verify that:

* **APP_URL** ends with "/\"
* **OAUTH_REDIRECT_URL** ends with "/\"
* **OAUTH_CLIENT_ID** is complete and correct
* **OAUTH_CLIENT_SECRET** is complete and correct

Apply changes to the `bldr.env` by running the install script:

```bash
bash ./install.sh
```

Restart the Chef Habitat services:

```bash
sudo systemctl restart hab-sup
```

### Self-signed cert files do not exist

The latest version of the Chef Habitat Builder on-prem services looks certificates in the `/hab/cache/ssl` directory. Copy your self-signed certificates directory if they are missing. Follow the naming pattern `appname-cert.cert` or `appname-cert.pem`, for example `automate-cert.cert` or `automate-cert.pem`. Do not use `cert.pem`, which is reserved for the Chef Habitat system. Overwriting this file will cause Chef Habitat Builder to fail.

Restart the Chef Habitat services:

```bash
sudo systemctl restart hab-sup
```

### Error "sorry, too many clients already"

If the hab services don't come up as expected, use `journalctl -fu hab-sup` to check the service logs (also see below for turning on Debug Logging).

If you see a Postgresql error "sorry, too many clients already", you may need to increase the number of configured connections to the database.

In order to do that, run the following:

`echo 'max_connections=200' | hab config apply "builder-datastore.default" $(date +%s)`

Wait for a bit for the datastore service to restart. If the service does not restart on it's own, you can do a 'sudo systemctl restart hab-sup' to restart things.

### Error "Too many open files"

If you see this error message in the supervisor logs, that may indicate that you need to increase the file ulimit on your system. The Chef Habitat Builder on-prem systemd configuration includes an expanded file limit, however some distributions (eg, on CentOS 7) may require additional system configuration.

For example, add the following to the end of your `/etc/security/limits.conf` file, and restart your system.

```text
* soft nofile 65535
* hard nofile 65535
```

### Error "Text file busy"

Occasionally you may get an error saying "Text file too busy" during install.
If you get this, please re-try the install step again.

### Error when bootstrapping core packages

You may see the following error when bootstrapping the core packages using the script above. If this happens, the bootstrap process will continue re-trying, and the upload will eventually succeed. Be patient and let the process continue until successful completion.

```output
✗✗✗
✗✗✗ Pooled stream disconnected
✗✗✗
```

If some packages do not upload, you may try re-uploading them manually via the `hab pkg upload` command.

This may also be an indication that your installation may not have sufficient CPU, RAM or other resources, and you may want to either allocate additional resources (eg, if on a VM) or move to a more scaled-up instance.

### Error uploading large packages

By default, the installed services configuration will set a 2GB limit for packages that can be uploaded to the Chef Habitat Builder on-prem. If you need to change the limit, you can do so by injecting an updated config to the Chef Habitat Builder on-prem services.

For example, to change the limit to 3GB, you could do the following:

Create a file called `config.toml` with the following content:

```toml
[nginx]
max_body_size = "3072m"
proxy_send_timeout = 360
proxy_read_timeout = 360

[http]
keepalive_timeout = "360s"
```

Then, issue the following command:

```bash
hab config apply builder-api-proxy.default $(date +%s) config.toml
```

After the config is successfully applied, re-try the upload.

If you have any issues, you may also need to adjust the timeout configuration on the Chef Habitat client.
You can do that via an environment variable: `HAB_CLIENT_SOCKET_TIMEOUT`. The value of this environment variable is a timeout in seconds. So for example, you could do something like this when uploading a file:

```bash
HAB_CLIENT_SOCKET_TIMEOUT=360 hab pkg upload -u http://localhost -z <your auth token> <file>
```

### Package shows up in the UI and `hab pkg search`, but `hab pkg install` fails

If you run into a situation where you have a package populated in the Chef Habitat Builder on-prem, but it is failing to install with a `Not Found` status, it is possible that there was a prior problem with populating the Minio backend with the package artifact.

If you have the package artifact on-disk (for example, in the `hab/cache/artifacts` directory), you can try to upload the missing package again with the following command (update the parameters as appropriate):

```bash
hab pkg upload -u http://localhost -z <your auth token> --force <package hart file>
```

Note: the --force option above is only available in versions of the `hab` client greater than 0.59.

### on-prem-archive.sh Fails during `populate-depot` with `403` error during core package uploads

When populating your Chef Habitat Builder on-prem with upstream core packages, you may run into an error that looks like this:

```output
Uploading hart files.

[1/958] Uploading ./core-img-0.5.4-20190201011741-x86_64-linux.hart to the depot at https://your.awesome.depot
  75 B / 75 B | [=========================================] 100.00 % 384 B/s
✗✗✗
✗✗✗ [403 Forbidden]
✗✗✗
```

And repeats for every package. Check to make sure you've created the `core` origin and then try again, if you haven't, then the upload will fail.

## Logs

### Log Rotation

The `builder-api-proxy` service will log (via Nginx) all access and errors to log files in your service directory. Since these files may get large, you may want to add a log rotation script. Below is a sample logrotate file that you can use as an example for your needs:

```bash
/hab/svc/builder-api-proxy/logs/host.access.log
/hab/svc/builder-api-proxy/logs/host.error.log
{
        rotate 7
        daily
        missingok
        notifempty
        delaycompress
        compress
        postrotate
                /bin/kill -USR1 `cat /hab/svc/builder-api-proxy/var/pid 2>/dev/null` 2>/dev/null || true
        endscript
}
```

### Debug Logging

If you want to turn on and examine the services debug logging, you can do so by doing the following on your install location:

Edit the `/hab/svc/builder-api/user.toml` file and update the `log_level` entry to start with `debug`

After making the edit, restart the hab services with `sudo systemctl restart hab-sup`, or just stop and start the builder-api service with `hab svc stop habitat/builder-api` and `hab svc start habitat/builder-api`.

Once the logging is enabled, you can examine it via `journalctl -fu hab-sup`

When you are done with debugging, you can set the logging back to the default setting by modifying the user.toml and restarting the services.

## License

Copyright (c) 2018 Chef Software Inc. and/or applicable contributors

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0) at `http://www.apache.org/licenses/LICENSE-2.0)`
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Support

You can also post any questions or issues on the [Habitat Forum](https://forums.habitat.sh/), on our [Slack channel](https://habitat-sh.slack.com), or file issues directly at the [Github repo](https://github.com/habitat-sh/on-prem-builder/issues).
