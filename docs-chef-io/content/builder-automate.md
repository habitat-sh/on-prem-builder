+++
title = "Deploy Chef Habitat Builder on-prem with Chef Automate"

[menu]
  [menu.habitat]
    title = "Chef Automate"
    identifier = "habitat/builder/on-prem/Automate"
    parent = "habitat/builder/on-prem"
    weight = 20
+++

The Chef Automate Applications Dashboard provides observability into your Chef Habitat Builder on-prem installation. For information and installation guidance, see [Setting up the Applications Dashboard](https://docs.chef.io/automate/applications_setup/).

## Chef Habitat On-Prem + Chef Automate

There are five steps to deploy Chef Habitat on-prem with Chef Automate's authentication.

1. Patch the Chef Automate configuration to recognize Chef Habitat
1. Set up the Chef Habitat Builder on-prem `bldr.env` to use Chef Automate's authentication
1. Copy your custom builder certificate files (`.crt` and `.key`) to the same location as the `./install.sh` script.
1. Install Chef Habitat Builder on-prem
1. Copy Automate's certificate to the `/hab/cache/ssl` directory

### Step One: Patch Chef Automate's Configuration

To authenticate with Chef Automate, create a patch with the Chef Automate command line:

1. From the command line, access Chef Automate, for example:

    ```bash
    ssh <AUTOMATE_HOSTNAME>
    ```

    or

    ```bash
    ssh <IP_ADDRESS>
    ```

1. Create a patch file called `patch-automate.toml`:

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

    Note that the `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` values above match the default values in the bldr.env.sample file which you will edit in the next step. You may chnge these values but they must match the `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` in your on prem builder's `bldr.env` file.

1. Apply the `patch-automate.toml` to the Chef Automate configuration from the command line:

    ```bash
    sudo chef-automate config patch patch-automate.toml
    ```

    A successful patch displays the output:

    ```shell
    Updating deployment configuration
    Applying deployment configuration
      Started session-service
    Success: Configuration patched
    ```

1. Exit Chef Automate

### Step Two: Set up `bldr.env`

1. SSH to your Chef Habitat Builder on-prem instance:

    ```bash
    ssh <builder hostname>
    #or
    ssh <ipaddress>
    ```

1. Clone the Chef Habitat Builder on-prem repository:

    ```bash
    git clone https://github.com/habitat-sh/on-prem-builder.git
    ```

1. Change to the `on-prem-builder` directory:

    ```bash
    cd on-prem-builder
    ```

1. Create a `bldr.env` file:

    ```bash
    touch bldr.env
    ```

    Or, if you need more explanations about the contents of the `bldr.env` file, copy the existing sample file:

    ```bash
    cp bldr.env.sample bldr.env
    ```

1. Edit `bldr.env`:
    * SSL must be enabled in Builder in order to authenticate against Automate, use `APP_SSL_ENABLED=true` and a `APP_URL` beginning with `https`.
    * Set `OAUTH_PROVIDER` to `chef-automate`.
    * Set the values of `OAUTH_USERINFO_URL`, `OAUTH_AUTHORIZE_URL`, and `OAUTH_TOKEN_URL` to the example values provided in the `sample.bldr.env` file substituting `<your.automate.domain>` with your Automate server or domain name.
    * Always be closing. Close the Builder addresses provided in `APP_URL` and `OAUTH_REDIRECT_URL` with a forward slash, `/`.
      * `https://chef-builder.test` will NOT work.
      * `https://chef-builder.test/` will work.

### Step Three: Put the Builder Certs with the Install Script

Rename the custom Builder certificates cert file as `ssl-certificate.crt` and the key file as `ssl-certificate.key`. Habitat recognizes only these names and will not recognize any other names. Copy the `ssl-certificate.crt` and `ssl-certificate.key` files to the same directory as the `./install.sh` script.

1. Locate the SSL certificate and key pair.
1. Copy the key pair to the same directory as the install script, which is `/on-prem-builder`, if the repository was not renamed.
1. Make the keys accessible to Habitat during the installation.
1. If you're testing this workflow, make your own key pair and copy them to `/on-prem-builder`.

  ```bash
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-certificate.key -out /etc/ssl/certs/ssl-certificate.crt
  sudo cp /etc/ssl/private/ssl-certificate.key .
  sudo cp /etc/ssl/certs/ssl-certificate.crt .
  sudo chown vagrant:vagrant ssl-certificate.*
  ```

1. You can confirm that the keys were copied:

    ```bash
    cat ./ssl-certificate.key
    cat ./ssl-certificate.crt
    ```

### Step Four: Install Builder

1. Run the install script. This installs both Chef Habitat Builder on-prem and the Chef Habitat datastore:

    ```bash
    sudo ./install.sh
    ```

1. Accept the licenses.
1. All services should report back as `up`. It make take a few minutes to come up.

    ```bash
    sudo hab svc status
    ```

    Should return something similar to:

    ```shell
    package                                        type        desired  state  elapsed (s)  pid    group
    habitat/builder-api/8473/20190830141422        standalone  up       up     595          28302  builder-api.default
    habitat/builder-api-proxy/8467/20190829194024  standalone  up       up     597          28233  builder-api-proxy.default
    habitat/builder-memcached/7728/20180929144821  standalone  up       up     597          28244  builder-memcached.default
    habitat/builder-datastore/7809/20181019215440  standalone  up       up     597          28262  builder-datastore.default
    habitat/builder-minio/7764/20181006010221      standalone  up       up     597          28277  builder-minio.default
    ```

### Step Five: Copy Automate's Certificate to Builder

1. View and copy the Chef Automate certificate. Change the server name to your Chef Automate installation FQDN:

    ```bash
    openssl s_client -showcerts -servername chef-automate.test -connect chef-automate.test:443 < /dev/null | openssl x509
    ```

    Copy the output to an accessible file.

    ```shell
    # Copy the contents including the begin and end certificate
    # -----BEGIN CERTIFICATE-----
    # Certificate content here
    #-----END CERTIFICATE-----
    ```

1. Make a file for your cert at `/hab/cache/ssl/`, such as `automate-cert.crt`.
1. Paste the Chef Automate certificate into your file, `/hab/cache/ssl/automate-cert.crt`
1. Restart builder

    ```bash
    sudo systemctl restart hab-sup
    ```

### You're Done

1. Login at

    ```bash
    https://chef-builder.test
    ```

## Related Resources

* [Chef Automate (ALPHA)](https://automate.chef.io/docs/configuration/#alpha-setting-up-automate-as-an-oauth-provider-for-habitat-builder)

## Next Steps

[Bootstrap Core Origin](./bootstrap-core.md)
