#!/bin/bash

set -eou pipefail

if [ -f ../bldr.env ]; then
  # shellcheck disable=SC1091
  source ../bldr.env
elif [ -f /vagrant/bldr.env ]; then
  # shellcheck disable=SC1091
  source /vagrant/bldr.env
else
  echo "ERROR: bldr.env file is missing!"
  exit 1
fi

# Defaults
BLDR_ORIGIN=${BLDR_ORIGIN:="habitat"}

sudo () {
  [[ $EUID = 0 ]] || set -- command sudo -E "$@"
  "$@"
}

init_datastore() {
  mkdir -p /hab/svc/builder-datastore
  cat <<EOT > /hab/svc/builder-datastore/user.toml
max_locks_per_transaction = 128
dynamic_shared_memory_type = 'none'

[superuser]
name = 'hab'
password = 'hab'
EOT
}

configure() {
  export PGPASSWORD PGUSER

  if [ "${RDS_ENABLED:-false}" = "false" ]; then
    while [ ! -f /hab/svc/builder-datastore/config/pwfile ]
    do
      sleep 2
    done

    PGUSER='hab'
    PGPASSWORD=$(cat /hab/svc/builder-datastore/config/pwfile)
  else
    PGUSER=${RDS_USER:-hab}
    PGPASSWORD=${RDS_PASSWORD:-hab}
  fi

  export ANALYTICS_ENABLED=${ANALYTICS_ENABLED:="false"}
  export ANALYTICS_COMPANY_ID
  export ANALYTICS_COMPANY_NAME
  export ANALYTICS_WRITE_KEY

  if [ $ANALYTICS_ENABLED = "true" ]; then
    ANALYTICS_WRITE_KEY=${ANALYTICS_WRITE_KEY:="NAwVPW04CeESMW3vtyqjJZmVMNBSQ1K1"}
    ANALYTICS_COMPANY_ID=${ANALYTICS_COMPANY_ID:="builder-on-prem"}
  else
    ANALYTICS_WRITE_KEY=""
    ANALYTICS_COMPANY_ID=""
    ANALYTICS_COMPANY_NAME=""
  fi

  # don't write out the builder-minio user.toml if using S3 or Artifactory directly
  if [ "${S3_ENABLED:-false}" = "false" ] && [ "${ARTIFACTORY_ENABLED:-false}" = "false" ]; then
    mkdir -p /hab/svc/builder-minio
    cat <<EOT > /hab/svc/builder-minio/user.toml
key_id = "$MINIO_ACCESS_KEY"
secret_key = "$MINIO_SECRET_KEY"
bucket_name = "$MINIO_BUCKET"
EOT
  fi

  mkdir -p /hab/svc/builder-api
  export S3_BACKEND="minio"
  if [ "${S3_ENABLED:-false}" = "true" ]; then
    S3_BACKEND="aws"
    MINIO_ENDPOINT=$S3_REGION
    MINIO_ACCESS_KEY=$S3_ACCESS_KEY
    MINIO_SECRET_KEY=$S3_SECRET_KEY
    MINIO_BUCKET=$S3_BUCKET
  fi
  if [ "${ARTIFACTORY_ENABLED:-false}" = "true" ]; then
    FEATURES_ENABLED="ARTIFACTORY"
  else
    FEATURES_ENABLED=""
    ARTIFACTORY_API_URL="http://localhost:8081"
    ARTIFACTORY_API_KEY="none"
    ARTIFACTORY_REPO="habitat-builder-artifact-store"
  fi
  PG_HOST=${POSTGRES_HOST:-localhost}
  PG_PORT=${POSTGRES_PORT:-5432}
  cat <<EOT > /hab/svc/builder-api/user.toml
log_level="error,tokio_core=error,tokio_reactor=error,zmq=error,hyper=error"
jobsrv_enabled = false

[http]
handler_count = 10

[api]
features_enabled = "$FEATURES_ENABLED"
targets = ["x86_64-linux", "x86_64-linux-kernel2", "x86_64-windows"]

[depot]
jobsrv_enabled = false

[oauth]
provider = "$OAUTH_PROVIDER"
userinfo_url = "$OAUTH_USERINFO_URL"
token_url = "$OAUTH_TOKEN_URL"
redirect_url = "$OAUTH_REDIRECT_URL"
client_id = "$OAUTH_CLIENT_ID"
client_secret = "$OAUTH_CLIENT_SECRET"

[s3]
backend = "$S3_BACKEND"
key_id = "$MINIO_ACCESS_KEY"
secret_key = "$MINIO_SECRET_KEY"
endpoint = "$MINIO_ENDPOINT"
bucket_name = "$MINIO_BUCKET"

[artifactory]
api_url = "$ARTIFACTORY_API_URL"
api_key = "$ARTIFACTORY_API_KEY"
repo = "$ARTIFACTORY_REPO"

[memcache]
ttl = 15

[datastore]
user = "$PGUSER"
password = "$PGPASSWORD"
connection_timeout_sec = 5
host = "$PG_HOST"
port = $PG_PORT
ssl_mode = "prefer"
EOT

mkdir -p /hab/svc/builder-api-proxy
cat <<EOT > /hab/svc/builder-api-proxy/user.toml
log_level="info"
enable_builder = false
app_url = "${APP_URL}"

[oauth]
provider = "$OAUTH_PROVIDER"
client_id = "$OAUTH_CLIENT_ID"
authorize_url = "$OAUTH_AUTHORIZE_URL"
redirect_url = "$OAUTH_REDIRECT_URL"
signup_url = "$OAUTH_SIGNUP_URL"

[nginx]
max_body_size = "2048m"
proxy_send_timeout = 180
proxy_read_timeout = 180
enable_gzip = true
enable_caching = true

[http]
keepalive_timeout = "180s"

[server]
listen_tls = $APP_SSL_ENABLED

[analytics]
enabled = $ANALYTICS_ENABLED
company_id = "$ANALYTICS_COMPANY_ID"
company_name = "$ANALYTICS_COMPANY_NAME"
write_key = "$ANALYTICS_WRITE_KEY"
EOT
}

start_api() {
  sudo hab svc load "${BLDR_ORIGIN}/builder-api" --bind memcached:builder-memcached.default --channel "${BLDR_CHANNEL}" --force
}

start_api_proxy() {
  sudo hab svc load "${BLDR_ORIGIN}/builder-api-proxy" --bind http:builder-api.default --channel "${BLDR_CHANNEL}" --force
}

start_datastore() {
  sudo hab svc load "${BLDR_ORIGIN}/builder-datastore" --channel "${BLDR_CHANNEL}" --force
}

start_minio() {
  sudo hab svc load "${BLDR_ORIGIN}/builder-minio" --channel "${BLDR_CHANNEL}" --force
}

start_memcached() {
  sudo hab svc load "${BLDR_ORIGIN}/builder-memcached" --channel "${BLDR_CHANNEL}" --force
}

generate_bldr_keys() {
  mapfile -t keys < <(find /hab/cache/keys -name "bldr-*.pub")

  if [ "${#keys[@]}" -gt 0 ]; then
    KEY_NAME=$(echo "${keys[0]}" | grep -Po "bldr-\\d+")
    echo "Re-using existing builder key: $KEY_NAME"
  else
    KEY_NAME=$(hab user key generate bldr | grep -Po "bldr-\\d+")
    echo "Generated new builder key: $KEY_NAME"
  fi

  hab file upload "builder-api.default" "$(date +%s)" "/hab/cache/keys/${KEY_NAME}.pub"
  hab file upload "builder-api.default" "$(date +%s)" "/hab/cache/keys/${KEY_NAME}.box.key"
}

upload_ssl_certificate() {
  if [ "${APP_SSL_ENABLED}" = "true" ]; then
    echo "SSL enabled - uploading certificate files"
    if ! [ -f "../ssl-certificate.crt" ] || ! [ -f "../ssl-certificate.key" ]; then
      pwd
      echo "ERROR: Certificate file(s) not found!"
      exit 1
    fi
    hab file upload "builder-api-proxy.default" "$(date +%s)" "../ssl-certificate.crt"
    hab file upload "builder-api-proxy.default" "$(date +%s)" "../ssl-certificate.key"
  fi
}

start_init() {
    create_users
    sudo systemctl start hab-sup
    sleep 2
}

start_frontend() {
  start_memcached
  start_api
  start_api_proxy
}

start_builder() {
  if [ "${RDS_ENABLED:-false}" = "false" ]; then
    init_datastore
    start_datastore
  fi
  configure
  if [ "${ARTIFACTORY_ENABLED:-false}" = "false" ] && [ "${S3_ENABLED:-false}" = "false" ]; then
    start_minio
  fi
  start_frontend
  sleep 2
  generate_bldr_keys
  upload_ssl_certificate
}


gen_frontend_bootstrap_bundle() {
  echo "Generating frontend bootstrap bundle"
  mkdir -p /hab/bootstrap_bundle/keys /hab/bootstrap_bundle/certs /hab/bootstrap_bundle/configs

  cp /hab/svc/builder-api/files/*.pub /hab/bootstrap_bundle/keys
  cp /hab/svc/builder-api/files/*.box.key /hab/bootstrap_bundle/keys

  for cert in /hab/svc/builder-api-proxy/files/*; do
    cp "${cert}" /hab/bootstrap_bundle/certs
  done

  cp /hab/svc/builder-api/user.toml /hab/bootstrap_bundle/configs

  type tar  > /dev/null 2>&1 || install_tar

  tar -cvf /hab/bootstrap_bundle.tar /hab/bootstrap_bundle && echo "saved: /hab/bootstrap_bundle.tar"
}

install_frontend_from_bootstrap_bundle() {
  if [ ! -f /hab/boostrap_bundle.tar ]; then
    echo "ERROR: /hab/bootstrap_bundle.tar does not exist! hint: run './install.sh --gen-bootstrap' \
      from any other functioning node running the builder-api service"
    exit 1
  fi
}

install_tar() {
  hab pkg path core/tar >/dev/null 2>&1 || hab pkg install core/tar -b
}

Help() {
  # Display Help
  echo
  echo "Habitat Builder Service Provisioning Script"
  echo ""
  echo "Syntax: provision [--help] [--frontend] [-h|-f]"
  echo "options:"
  echo "h, --help     Print this Help."
  echo "f, --frontend Provision only a front-end/API."
  echo

}

create_users() {
  if command -v useradd > /dev/null; then
    sudo useradd --system --no-create-home hab || true
  else
    sudo adduser --system hab || true
  fi
  if command -v groupadd > /dev/null; then
    sudo groupadd --system hab || true
  else
    sudo addgroup --system hab || true
  fi
}

for arg in "$@:-default"
do
  if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
    Help
  elif [ "$arg" == "--gen-bootstrap" ]; then
    gen_frontend_bootstrap_bundle
  elif [ "$arg" == "--install-frontend" ]; then
    install_frontend_from_bootstrap_bundle
  elif [ "$arg" == "--frontend" ] || [ "$arg" == "-f" ]; then
    start_init
    start_frontend
  # default, when no args are passed
  else
    start_init
    start_builder
    gen_frontend_bootstrap_bundle
  fi
done
