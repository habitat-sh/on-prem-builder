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

The following Chef Habitat Builder on-prem functionality is *NOT* currently available:

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

*Note*: When setting Chef Automate as your OAuth provider, you will need to add your Automate instance's TLS certificate (found at the `load_balancer.v1.sys.frontend_tls` entry in your Chef Automate `config.toml` file), to your Chef Habitat Builder on-prem instance's list of accepted certs. This can be done by copying the certificate to the `\hab\cache\ssl` folder on the Chef Habitat Builder on-prem instance (supported by the latest version of the Chef Habitat Builder on-prem), or alternatively by modifying the `core/cacert` package and appending the cert to the cert.pem file at the following location: `$(hab pkg path core/cacerts)/ssl/cert.pem`.

### Preparing your filesystem (Optional)

Since substantial storage may be required for holding packages, please ensure you have an appropriate amount of free space on your filesystem.

The package artifacts will be stored in your Minio instance by default, typically at the following location: `/hab/svc/builder-minio/data`

If you need to add additional storage, it is recommended that you create a mount at `/hab` and point it to your external storage. This is not required if you already have sufficient free space.

*Note*: If you would prefer to Artifactory instead of Minio for the object storage, please see the [Artifactory](artifactory.md) documentation.

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

*Important*: If you get authentication failures with a self-signed cert, you may need to either update the cert package that the Chef Habitat on-prem services are using (in the `/etc/systemd/system/hab-sup.service` file), or modify the hab `core/cacerts` package (in the `/hab/pkgs/core/cacerts/...` folder) to add your self-signed cert chain to the `cert.pem` file. Restart the hab services with `systemctl restart hab-sup` after updating the cert file. The latest version of the Chef Habitat Builder on-prem services will also look for certificates in the `/hab/cache/ssl` directory - you may copy any self-signed certificates to that directory if needed.

## Setup

1. Clone this repo (or unzip the archive you have downloaded from the Github release page) at the desired machine where you will stand up the Chef Habitat Builder on-prem
1. `cd ${SRC_ROOT}`
1. `cp bldr.env.sample bldr.env`
1. Edit `bldr.env` with a text editor and replace the values appropriately. Consider helping us to improve Chef Habitat as well by changing the `ANALYTICS_ENABLED` setting to `true` and providing an optional company name.
1. `./install.sh`

If everything goes well, you should see output similar to the following showing that the Chef Habitat Builder on-prem services are loaded:

```output
hab-sup(MN): The habitat/builder-datastore service was successfully loaded
hab-sup(MN): The habitat/builder-router service was successfully loaded
hab-sup(MN): The habitat/builder-api service was successfully loaded
hab-sup(MN): The habitat/builder-api-proxy service was successfully loaded
hab-sup(MN): The habitat/builder-originsrv service was successfully loaded
hab-sup(MN): The habitat/builder-sessionsrv service was successfully loaded
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

Once you are logged in, you should be able to create an origin by clicking on the 'Create Origin' button.

**NOTE** _You will need to at least create a `core` origin for an initial set of base packages (see section below). Go ahead and create a new origin now, and type in `core` as the origin name. It's important to do this prior to populating your Chef Habitat Builder on-prem with the `core` upstream packages, or else the upload will fail._

### Generate a Personal Access Token

In order to bootstrap a set of `core` package, as well as perform authenticated operations using the `hab` client, you will need to generate a Personal Access Token.

Click on your Gravatar icon on the top right corner of the Chef Habitat Builder on-prem web page, and then select Profile. This will take you to a page where you can generate your access token. Make sure to save it away securely.

## Bootstrap `core` packages

*Important*: Please make sure you have created a `core` origin before starting this process.

The freshly installed Chef Habitat Builder on-prem does not contain any packages. In order to bootstrap a set of stable `core` origin packages (refer to the [core-plans repo](https://github.com/habitat-sh/core-plans)), you can do the following:

1. Export your Personal Access Token as `HAB_AUTH_TOKEN` to your environment (e.g, `export HAB_AUTH_TOKEN=<your token>`)
1. `sudo -E ./scripts/on-prem-archive.sh populate-depot http://${BUILDER_HOSTNAME_OR_IP}`, passing the root URL of your new Chef Habitat Builder on-prem as the last argument (Replace `http` with `https` in the URL if SSL is enabled)

This is quite a lengthy process, so be patient. It will download a *large* (~ 13GB currently) archive of the latest stable core plans, and then install them to your Chef Habitat Builder on-prem.

Please ensure that you have plenty of free drive space available, for hosting the `core` packages as well as your own packages.

## Synchronizing 'core' packages from an upstream

*Important*: Please make sure you have created a `core` origin before starting this process.

It is possible to also use the 'on-prem-archive.sh' script to synchronize the Chef Habitat Builder on-prem using the public Chef Habitat Builder site as an 'upstream'.

This allows new stable core packages from the upstream to get created in the Chef Habitat Builder on-prem instance automatically.

If your Chef Habitat Builder on-prem instance will have continued outgoing internet connectivity, you may wish to periodically run the script to check for updates.

1. Export your Personal Access Token as `HAB_AUTH_TOKEN` to your environment (e.g, `export HAB_AUTH_TOKEN=<your token>`)
1. `sudo -E ./scripts/on-prem-archive.sh sync-packages http://${BUILDER_HOSTNAME_OR_IP} base-plans`, passing the root URL of your new Chef Habitat Builder on-prem as the last argument. Replace `http` with `https` in the URL if SSL is enabled.

The 'base-plans' parameter restricts the sync to a smaller subset of the core packages. If you wish to synchronize all core packages, omit the 'base-plans' parameter from the script. Note that it will take much longer for the synchronization of all packages. Generally, it will only take a few minutes for base packages to synchronize.

You can also run the sync-packages functionality to initially populate the local Chef Habitat Builder on-prem.

*NOTE*: This functionality is being provided as an alpha - please log any issues found in the on-prem-builder repo.

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

## Troubleshooting

### Network access / proxy configuration

If the initial install fails, please check that you have outgoing connectivity, and that you can successfully ping the following:

* `raw.githubusercontent.com`
* `bldr.habitat.sh`

If you have outgoing access via a proxy, please ensure that HTTPS_PROXY is set correctly in your environment.

You also will need to have the following _inbound_ port open for your instance:

* Port 80

In the case that you have configured your proxy for the local session while installing but are still receiving connection refusal errors like the one below, you may want to configure your proxy with the `/etc/environment` file or similar.

IMPORTANT: During installation, if any values are found in the environment for `HTTP_PROXY`, `HTTPS_PROXY`, or `NO_PROXY`, they will be written into the hab-sup systemd service file.  If these values need to change, you can update `/etc/systemd/system/hab-sup.service`.

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

You can also turn on debug logging (section below) and check to see that the authenticate endpoint is getting called at the Chef Habitat Builder API backend, and whether there is any additional information in the logs that may be helpful.

The OAuth Token and API endpoints must be reachable from the Chef Habitat Builder on-prem install point.

*Important*: If you change any settings in your `bldr.env` file, you will need to do the following steps after making the changes:

1. Re-run the install script (`./install.sh`)
2. Restart the services (`sudo systemctl restart hab-sup`)

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
