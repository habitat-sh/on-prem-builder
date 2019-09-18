# Install Chef Habitat Builder On-Premises

The Habitat 0.85.0 release simplifies custom certificate management. Habitat now looks for custom certificates in its `~/.hab/cache/ssl` directory (or `/hab/cache/ssl` if running as root). You can copy over Multiple certificates--for example, a self-signed certificate and a custom certificate authority certificate--to the cache directory and they are automatically available for use by the Habitat client.

## System Requirements

The following are minimum requirements for the Chef Habitat On-Prem Builder:

* Linux OS system with 64-bit architecture with kernel 2.6.32 or later
* `systemd` process manager
* CPU / RAM for trial deployments: minimum 2 CPU/4 GB RAM (corresponding to AWS T3.medium or better) or better
* CPU / RAM for production deployments: minimum 16 CPU/32 GB RAM (corresponding to AWS M4.4xlarge) or better
* Disk space for trial deployments: Minimum 2GB free disk space the baseline installation with only the packages required to run the Builder Services
* Disk space for production deployments: Minimum 5GB+ of disk space for the full installation including the latest versions of core packages
* Services should be deployed single-node - scale out is not yet supported
* Outbound network (HTTPS) connectivity to WAN is required for the initial installation
* Inbound network connectivity from LAN (HTTP/HTTPS) is required for internal clients to access the Builder
* SSL Certificate
* Oauth 2
* Port 80 or 443

## Authentication

Chef Habitat Builder on-prem supports Oauth authentication for:

* [Chef Automate v2 (ALPHA)](https://automate.chef.io/docs/configuration/#alpha-setting-up-automate-as-an-oauth-provider-for-habitat-builder)
* [Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-protocols-oauth-code)
* [GitHub](https://developer.github.com/apps/building-oauth-apps/authorization-options-for-oauth-apps/)
* [GitLab](https://docs.gitlab.com/ee/integration/oauth_provider.html)
* [Okta](https://developer.okta.com/authentication-guide/implementing-authentication/auth-code)
* [Atlassian BitBucket](https://confluence.atlassian.com/bitbucket/oauth-on-bitbucket-cloud-238027431.html)

## Chef Habitat On-Prem + Chef Automate

Configuring Chef Habitat On-Prem to use Chef Automate's Authentication takes five steps:

1. Patch the Chef Automate `automate-credentials.toml` to recognize Chef Habitat
1. Set up Builder On-Prem's `bldr.env` to use Chef Automate's OAuth
1. Copy the any custom certificate `.crt` and `.key` files to the same location as the `./install.sh` script.
1. Install Chef Habitat Builder On-Prem
1. Copy Automate's certificate to the `/hab/cache/ssl` directory

### Step One: Patch Chef Automate's Configuration

For example, to authenticate with Chef Automate, create a patch with the Chef Automate command line:

1. From the command line, access Chef Automate, for example:

    ```bash
    ssh <automate hostname>
    #or
    ssh <ipaddress>
    ```

1. Create the file `patch-automate.toml`:

    ```bash
    touch patch-automate.toml
    ```

1. Edit the `patch-automate.toml`:

    ```toml
    [session.v1.sys.service]
    bldr_signin_url = "https://chef-builder.test/"

    # OAUTH_CLIENT_ID
    bldr_client_id = "0123456789abcdef0123"

    # OAUTH_CLIENT_SECRET
    bldr_client_secret = "0123456789abcdef0123456789abcdef01234567"
    ```

1. Apply the `patch-automate.toml` to the Chef Automate configuration from the command line:

    ```bash
    sudo chef-automate config patch patch-automate.toml
    ```

    A successful patch displays the output:

    ```output
    Updating deployment configuration

    Applying deployment configuration
      Started session-service
    Success: Configuration patched
    ```

1. Exit Chef Automate

### Step Two: Set up `bldr.env`

1. From the command line, access the location where you will install Chef Habitat Builder on-prem:

    ```bash
    ssh <builder hostname>
    #or
    ssh <ipaddress>
    ```i

1. From Builder host command line, install Chef Habitat Builder on-prem package:

    ```bash
    git clone https://github.com/habitat-sh/on-prem-builder.git
    ```

1. Change to the `on-prem-builder` directory:

    ```bash
    cd on-prem-builder
    ```

1. Create a `bldr.env` file:

    To create an empty file:

    ```bash
    touch bldr.env
    ```

    Or, if you need more explanations about the contents of the `bldr.env` file, copy the existing sample file:

    ```bash
    cp bldr.env.sample bldr.env
    ```

1. Edit `bldr.env`:

      * The `APP_SSL_ENABLED` configuration must correspond with the type of hypertext transfer protocol named in `APP_URL`.

        * To disable SSL, use `APP_SSL_ENABLED=false` and the `APP_URL` starts with `http`.
        * To enable SSL, use `APP_SSL_ENABLED=true` and the `APP_URL` starts with `https`.

      * Always be closing. Close the Builder addresses provided in `APP_URL` and `OAUTH_REDIRECT_URL` with a forward slash, `/`.

        * `https://chef-builder.test` will NOT work.
        * `https://chef-builder.test/` will work.


  This `bldr.env` example shows an on-prem SSL-enabled Habitat Builder authenticating using Chef Automate's OAuth.
  `APP_SSL_ENABLED=true` and the `APP_URL` starts with `https`.

    ```bash
    #!/bin/bash

    # The endpoint, key and secret for your Minio instance (see README)
    # Change these before the first install if needed
    export MINIO_ENDPOINT=http://localhost:9000
    export MINIO_BUCKET=habitat-builder-artifact-store.local
    export MINIO_ACCESS_KEY=depot
    export MINIO_SECRET_KEY=password

    # APP settings
    export APP_SSL_ENABLED=true
    export APP_URL=https://chef-builder.test/

    # The OAUTH_PROVIDER values for Chef-Automate
    export OAUTH_PROVIDER=chef-automate
    export OAUTH_USERINFO_URL=https://chef-automate.test/session/userinfo
    export OAUTH_AUTHORIZE_URL=https://chef-automate.test/session/new
    export OAUTH_TOKEN_URL=https://chef-automate.test/session/token
    export OAUTH_SIGNUP_URL=https://github.com/join

    # The OAUTH_REDIRECT_URL is the registered OAuth2 redirect
    # IMPORTANT: If SSL is enabled, the redirect URL should be https
    # IMPORTANT: don't forget the `/` at the end of the URL
    export OAUTH_REDIRECT_URL=https://chef-builder.test/

    # The OAUTH_CLIENT_ID is the registered OAuth2 client id
    export OAUTH_CLIENT_ID=0123456789abcdef0123

    # The OAUTH_CLIENT_SECRET is the registered OAuth2 client secret
    export OAUTH_CLIENT_SECRET=0123456789abcdef0123456789abcdef01234567

    # Modify these only if there is a specific need, otherwise leave as is
    export BLDR_CHANNEL=on-prem-stable
    export BLDR_ORIGIN=habitat
    export HAB_BLDR_URL=https://bldr.habitat.sh

    # Help us make Habitat better! Opt into analytics by changing the ANALYTICS_ENABLED
    # setting below to true, then optionally provide your company name. (Analytics is
    # disabled by default. See our privacy policy at https://www.habitat.sh/legal/privacy-policy/.)
    export ANALYTICS_ENABLED=false
    export ANALYTICS_COMPANY_NAME=""
    ```

This `bldr.env` example shows an on-prem SSL-enabled Habitat Builder authenticating using GitHub's OAuth.
`APP_SSL_ENABLED=true` and the `APP_URL` starts with `https`.

    ```bash
    #!/bin/bash

    # The endpoint, key and secret for your Minio instance (see README)
    # Change these before the first install if needed
    export MINIO_ENDPOINT=http://localhost:9000
    export MINIO_BUCKET=habitat-builder-artifact-store.local
    export MINIO_ACCESS_KEY=depot
    export MINIO_SECRET_KEY=password

    # APP settings
    export APP_SSL_ENABLED=true
    export APP_URL=https://chef-builder.test/

    # Whether SSL is enabled for the on-prem depot
    export APP_SSL_ENABLED=true

    # The OAUTH_PROVIDER values GitHub
    # See https://api.github.com/ for endpoints
    export OAUTH_PROVIDER=github
    export OAUTH_USERINFO_URL=https://github.com/users
    export OAUTH_AUTHORIZE_URL=https://github.com/login/oauth/authorize
    export OAUTH_TOKEN_URL=https://https://github.com/login/oauth/access_token
    export OAUTH_SIGNUP_URL=https://github.com

    # The OAUTH_REDIRECT_URL is the registered OAuth2 redirect
    # IMPORTANT: If SSL is enabled, the redirect URL should be https
    # IMPORTANT: don't forget the `/` at the end of the URL
    export OAUTH_REDIRECT_URL=http://chef-builder.test/

    # The OAUTH_CLIENT_ID is the registered GitHub ClientID
    export OAUTH_CLIENT_ID=0123456789abcdef0123

    # The OAUTH_CLIENT_SECRET is the registered GitHub client secret
    export OAUTH_CLIENT_SECRET=0123456789abcdef0123456789abcdef01234567

    # Modify these only if there is a specific need, otherwise leave as is
    export BLDR_CHANNEL=on-prem-stable
    export BLDR_ORIGIN=habitat
    export HAB_BLDR_URL=https://bldr.habitat.sh

    # Help us make Habitat better! Opt into analytics by changing the ANALYTICS_ENABLED
    # setting below to true, then optionally provide your company name. (Analytics is
    # disabled by default. See our privacy policy at https://www.habitat.sh/legal/privacy-policy/.)
    export ANALYTICS_ENABLED=false
    export ANALYTICS_COMPANY_NAME=""
    ```

### Step Three: Put the Certs with the Install Script

Copy the any custom certificate `.crt` and `.key` files to the same location as the `./install.sh` script.

1. Locate the SSL certificate and key pair.
1. Copy the key pair to the same directory as the install script, which is `/on-prem-builder`, if the repository was not renamed.
1. Make the keys accessible to Habitat during the installation.
1. If you're testing this workflow, make your own key pair and copy them to `/on-prem-builder`. This example uses a Vagrant VM:

    ```bash
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-certificate.key -out /etc/ssl/certs/ssl-certificate.crt %>

    sudo cp /etc/ssl/private/ssl-certificate.key .
    sudo cp /etc/ssl/certs/ssl-certificate.crt .
    sudo chown vagrant:vagrant ssl-certificate.*
    ````

1. You can confirm that the keys were copied:

    ```bash
    cat ./ssl-certificate.key
    cat ./ssl-certificate.crt
    ```

### Step Four: Install Builder

1. Run the install script. This installs both Chef Habitat Builder on-prem and the Chef Habitat datastore:

    ```bash
    bash ./install.sh
    ```

1. Accept both licenses.
1. All services should report back as `up`. It make take a few minutes to come up.

    ```bash
    sudo hab svc status
    ```

    Should return something similar to:

    ```output
    package                                        type        desired  state  elapsed (s)  pid    group
    habitat/builder-api/8473/20190830141422        standalone  up       up     595          28302  builder-api.default
    habitat/builder-api-proxy/8467/20190829194024  standalone  up       up     597          28233  builder-api-proxy.default
    habitat/builder-memcached/7728/20180929144821  standalone  up       up     597          28244  builder-memcached.default
    habitat/builder-datastore/7809/20181019215440  standalone  up       up     597          28262  builder-datastore.default
    habitat/builder-minio/7764/20181006010221      standalone  up       up     597          28277  builder-minio.default
    ```

### Step Five: Copy Automate's Certificate to the `/hab/cache/ssl` Directory

1. View and copy the Chef Automate certificate. Change the server name to your Chef Automate installation FQDN:

    ```bash
    openssl s_client -showcerts -servername chef-automate.test -connect chef-automate.test:443 < /dev/null | openssl x509
    ```

    Copy the output to an accessible file.

    ```output
    # Copy the contents including the begin and end certificate
    # -----BEGIN CERTIFICATE-----
    # Certificate content here
    #-----END CERTIFICATE-----
    ```

1. Make a file for you cert at `/hab/cache/ssl/`, such as `automate-cert.crt`. For a `.pem` file, `automate-cert.pem`. Overwriting `cert.pem` will cause your Builder installation to fail.
1. Paste the Chef Automate certificate into your file, `/hab/cache/ssl/automate-cert.crt`
1. Restart builder

   ```bash
   sudo systemctl restart hab-sup
   ``` %>

### You're Done!

1. Login at `https://chef-builder.test`

## Troubleshooting

### Memory Filesystem Storage

Preparing your filesystem (Optional)

Since substantial storage may be required for holding packages, please ensure you have an appropriate amount of free space on your filesystem.

The package artifacts will be stored in your Minio instance by default, typically at the following location: `/hab/svc/builder-minio/data`

If you need to add additional storage, it is recommended that you create a mount at `/hab` and point it to your external storage. This is not required if you already have sufficient free space.

*Note*: If you would prefer to Artifactory instead of Minio for the object storage, please see the [Artifactory](#using-artifactory-as-the-object-store-(alpha)) section below.

### Network access / proxy configuration

1. Check that you have outgoing connectivity:

    ```bash
    ping raw.githubusercontent.com`
    ping bldr.habitat.sh`
    ```

1. Confirm that HTTPS_PROXY is set correctly in your environment.

    ```bash
    http_proxy="http://PROXY_SERVER:PORT"
    https_proxy="https://PROXY_SERVER:PORT"
    ```

1. Confirm that _inbound_ port **80** is open if SSL is disabled or port **443** if SSL is enabled.

### Finding origin keys

On Linux OS:

    ```bash
    # Linux/MacOS
    ls -la /hab/cache/keys
    ls -la $HOME/.hab/cache.keys
    ```

On Windows:

    ```PS
    # Windows (Powershell 5+)
    ls C:\hab\cache\keys
    ```

## Errors

### Unable to retrieve OAuth token

You were able to sign in to Chef Automate, but Chef Automate was unable to authenticate Chef Habitat's OAuth token.

Open the `bldr.env` and verify that:

* **APP_URL** ends with "\"
* **OAUTH_REDIRECT_URL** ends with "\"
* **OAUTH_CLIENT_ID** is complete and correct
* **OAUTH_CLIENT_SECRET** is complete and correct

Apply changes to the to apply changes to the `bldr.env`

    ```bash
    bash ./install.sh
    ```

Restart the Chef Habitat services:

    ```bash
    sudo systemctl restart hab-sup
    ```

### Connection refused (os error 111)

If the proxy was configured for the local session during installation, but you are still seeing connection refusal errors, you may want to configure your proxy with the `/etc/environment` file or something similar. Work with your enterprise network admin to ensure the appropriate firewall rules are configured for network access.

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

## Logging

## Logging Levels

The recognized values for logging are: `error`, `warn`, `info`, `debug`, and `trace`.
For a more detailed explanation of logging in Chef Habitat, see the [Supervisor Log Configuration Reference](https://www.habitat.sh/docs/reference/#supervisor-log-configuration-reference) and the [Supervisor Log Key](https://www.habitat.sh/docs/reference/#supervisor-log-key) documentation.

### Basic Logging

To turn on and examine the services debug logging in your Habitat installation:

1. Edit the `sudo /hab/svc/builder-api/user.toml` file
1. On the first line, change the log_level from **error** to **debug**

  ```tomlß
  log_level="debug,tokio_core=error,tokio_reactor=error,zmq=error,hyper=error"
  RUST_LOG=debug RUST_BACKTRACE=1
  jobsrv_enabled = false
  ```

1. Save and close the file
1. Restart Habitat with `sudo systemctl restart hab-sup` to restart the habitat.
1. Use `journalctl -fu hab-sup` to view the logs.
1. Reset `/hab/svc/builder-api/user.toml` file to the default `log_level=error` and restart the services with `sudo systemctl restart hab-sup` to stop debug-level logging.

### RUST_LOG

Use **RUST_LOG=debug RUST_BACKTRACE=1** to see a command's debug and backtrace.

  ```bash
	# Linux/MacOS
  # replace "hab sup run" with your command
	RUST_LOG=debug RUST_BACKTRACE=1 hab sup run
  ```
