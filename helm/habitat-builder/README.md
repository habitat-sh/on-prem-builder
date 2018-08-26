# On Premises Depot

The on premises depot is a self hosted version of the Habitat Builder service.

## Install Chart

To install the chart into your kubernetes cluster:

```console
helm repo add builder https://habitat-sh.github.io/on-prem-depot/helm/charts/stable/
helm install --name my-builder builder/habitat-builder
```

This deploys the chart using the default configuration.

## Uninstall Chart

To uninstall/delete the `my-builder` deployment:

```console
helm delete my-builder
```

## Configuration

The following table lists the configurable parameters of the habitat-builder chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.registry` | Image Registry | `hub.docker.com`
`image.tag` | Image Tag to be deployed | `on-prem-stable`
`datastore.superuserPassword` | Password for Postgres | None
`datastore.persistentStorage.enabled` | Use a Persistent volume for the database | `false`
`datastore.persistentStorage.size` | Size of volume to create | `32Gi`
`datastore.persistentStorage.storageClass` | Type of storage to create | `default`
`minio.secret_key` | Password for Minio datastore | `password`
`minio.persistentStorage.enabled` | Use a Persistent volume for the block storage | `false`
`minio.persistentStorage.size` | Size of volume to create | `32Gi`
`minio.persistentStorage.storageClass` | Type of storage to create | `default`
`app.ssl.enabled` | Should SSL/HTTPS be enabled | `false`
`app.ssl.crt` | The contents of the SSL certificate file | None
`app.ssl.key` | The contents of the SSL key file | None
`app.fqdn` | The FQDN for this instance of the on-prem depot | `localhost`
`api.keys.name` | The name of the service keypair | None
`api.keys.public_key` | The contents of the service public_key file | None
`api.keys.private_key` | The contents of the service priate key file | None
`oauth.provider` | OAuth provider | `github`
`oauth.authorize_url`| The OAuth User Info URL | `"https://github.com/login/oauth/authorize"`
`oauth.token_url`| The OAuth User Info URL | `"https://github.com/login/oauth/access_token"`
`oauth.client_id`| Your registered Oauth2 client id | `0123456789abcdef0123`
`oauth.client_secret`| Your registered Oauth2 client id | `0123456789abcdef0123456789abcdef01234567`
`analytics.enabled` | Should analytics data be send back | `false`
`analytics.company_name` | identifier for this on-prem builder | `""`
`service.type` | How to expose the API as a service | `LoadBalancer`
`service.loadBalancerIP` | Use a pre-allocated IP | None
`debug` | turn on service debug logs | `false`

Specify each parameter using the --set key=value[,key=value] argument to helm install. For example,

```console
helm install --name my-builder builder/habitat-builder \
  --set app.ssl.enabled=true
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
helm install --name my-builder builder/habitat-builder -f values.yaml
```

## Common Configuration Setups

### Minimal configuration

In order to have a functional depot you'll need to set the following at a minimum:

    * `app.fqdn`
    * `datastore.superuserPassword`
    * `oauth.client_id`
    * `oauith.client_secret`
    * `api.keys.name`
    * `api.keys.public_key`
    * `api.keys.private_key`

See the sections below for more details on setting each of these.

### Setting a database password

You must set a database password as `datastore.superuserPassword`.

### OAuth Setup

See [OAuth Application setup](https://github.com/habitat-sh/on-prem-builder/blob/master/README.md#oauth-application) for how to configure OAuth. [values.yaml](values.yaml) contains the correct URLs for the OAuth services that are supported.

### Setting API Keys

The API services needs a set of signing keys. You can generate these using `hab key generate` on your workstation:

```console
KEY_NAME=$(hab user key generate on-prem-bldr | grep -Po "on-prem-bldr-\\d+")
echo "Generated new builder key: $KEY_NAME"

helm install my-builder builder/habitat-builder install \
    --set api.keys.name=${KEY_NAME} \
    --set-file api.keys.public_key=$HOME/.hab/cache/keys/${KEY_NAME}.pub \
    --set-file api.keys.private_key=$HOME/.hab/cache/keys/${KEY_NAME}.box.key
```

You can also set them in a YAML `values.yaml` file, e.g.:

```yaml
api:
  keys:
    name: "bldr-20180827040405"
    public_key: |-
      BOX-PUB-1
      bldr-20180827040405

      qw9CXWK4N3yMhD6Qhya21ohDH0ZIbl0myZ8j8R4uOQk=
    private_key: |-
      BOX-SEC-1
      bldr-20180827040405

      4VT5l4yeDaG11wvIWrw/RhkEyH+dZSRo4HlCatgWwEE=
```

where `public_key` and `private_key` are the contents of the `.pub` and `.box.key` files respectively.

### Enabling SSL/HTTPS

By default the on premise depot only exposes a HTTP port. In order to allow HTTPS traffic you will need to provide SSL a certificate for the service to use. If you don't have one you can generate a self signed certificate:

```console
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl-certificate.key -out ssl-certificate.crt
```

This should provided to helm via the `--set-file` option:

```console
helm install my-builder builder/habitat-builder install \
    --set app.ssl.enabled=true \
    --set-file app.ssl.crt=./ssl-certificate.crt \
    --set-file app.ssl.key=./ssl-certificate.key
```

Alternative you can paste the contents of the two files into your `values.yaml` similar to the example above for API keys.

### Using pre-allocated IP

If you have a static IP assigned already to the service FQDN that you would like the Load Balancer to use, you can specify it via the `service.loadBalancerIP`. If you don't specify it then an IP address will be assigned and you'll need to configure DNS to point to it.

## Post-Install steps

To bootstrap the core packages origin on your depot follow the instructions at
https://github.com/habitat-sh/on-prem-builder/blob/master/README.md#depot-web-ui

## Hosting

The Helm chart repository is managed on the [`gh-pages` branch](https://github.com/habitat-sh/on-prem-builder/tree/gh-pages) and instructions for repository management can be found [here](https://github.com/habitat-sh/on-prem-builder/tree/gh-pages/helm/charts).