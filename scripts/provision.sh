#!/bin/bash

set -eou pipefail
umask 0022

# Defaults
BLDR_ORIGIN=${BLDR_ORIGIN:="habitat"}

sudo() {
  [[ $EUID = 0 ]] || set -- command sudo -E "$@"
  "$@"
}

user_toml_warn() {
  if [ -f "/hab/svc/$1/user.toml" ]; then
    mv "/hab/svc/$1/user.toml" "/hab/svc/$1/user.toml.bak"
    echo "WARNING: Previous user.toml exists in deprecated location. All user.toml"
    echo "files should be deposited into the path /hab/user/$1/config/user.toml."
    echo "Deprecated user.toml has been renamed user.toml.bak."
  fi
}

# In order to upgrade PostgreSQL via the install hook we need to be have both
# the version of PostgreSQL that we are upgrading from and the one that we are
# upgrading are available. The plan file of the version being initially
# installed or upgraded to ensures that the PostgreSQL version is available.
# However, when upgrading we need to execute hab pkg install for the previous
# version to ensure that it is available. Running hab pkg install requires root
# privileges and we cannot sudo inside the install hook because we are running
# as the hab user because the hab user isn't allowed to elevate its privileges.
install_previous_postgresql_version() {
  local -r pg_version_file='/hab/svc/builder-datastore/data/PG_VERSION'
  if [[ -f $pg_version_file ]]; then
    local -r installed_pg_ident="core/postgresql$(cat $pg_version_file | sed 's/\.//')"
    if ! hab pkg install "$installed_pg_ident"; then
      echo "Failed installing $installed_pg_ident, trying again on stable channel"
      hab pkg install "$installed_pg_ident" --channel stable
    fi
  fi
}

init_datastore() {
  install_previous_postgresql_version
  user_toml_warn builder-datastore
  mkdir -p /hab/user/builder-datastore/config
  cat <<-EOT >/hab/user/builder-datastore/config/user.toml
		max_locks_per_transaction = 128

		[superuser]
		name = 'hab'
		password = 'hab'
	EOT
}

configure() {
  export PGPASSWORD PGUSER
  if [ "${PG_EXT_ENABLED:-false}" = "true" ]; then
    PGUSER=${PG_USER:-hab}
    PGPASSWORD=${PG_PASSWORD:-hab}
  else
    PGUSER="hab"
    PGPASSWORD=""
  fi

  export ANALYTICS_ENABLED=${ANALYTICS_ENABLED:="false"}
  export ANALYTICS_COMPANY_ID
  export ANALYTICS_COMPANY_NAME
  export ANALYTICS_WRITE_KEY

  if [ "$ANALYTICS_ENABLED" = "true" ]; then
    ANALYTICS_WRITE_KEY=${ANALYTICS_WRITE_KEY:="NAwVPW04CeESMW3vtyqjJZmVMNBSQ1K1"}
    ANALYTICS_COMPANY_ID=${ANALYTICS_COMPANY_ID:="builder-on-prem"}
  else
    ANALYTICS_WRITE_KEY=""
    ANALYTICS_COMPANY_ID=""
    ANALYTICS_COMPANY_NAME=""
  fi

  export LOAD_BALANCED="false"
  if [ "${HAB_BLDR_PEER_ARG:-}" != "" ]; then
    LOAD_BALANCED="true"
  fi

  # don't write out the builder-minio user.toml if using S3 or Artifactory directly
  if [ "${S3_ENABLED:-false}" = "false" ] && [ "${ARTIFACTORY_ENABLED:-false}" = "false" ]; then
    if [ "${FRONTEND_INSTALL:-0}" != 1 ]; then
      user_toml_warn builder-minio
      mkdir -p /hab/user/builder-minio/config
      cat <<-EOT >/hab/user/builder-minio/config/user.toml
				key_id = "$MINIO_ACCESS_KEY"
				secret_key = "$MINIO_SECRET_KEY"
				bucket_name = "$MINIO_BUCKET"
			EOT
    fi
  fi

  mkdir -p /hab/user/builder-api/config
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
  user_toml_warn builder-api
  cat <<-EOT >/hab/user/builder-api/config/user.toml
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

  if [ "${OAUTH_PROVIDER}" = "chef-automate" ]; then
    ALLOW_OAUTH_ORIGIN="allow_oauth_origin = \"https://$(echo "$OAUTH_USERINFO_URL" | awk -F[/:] '{print $4}')\""
  else
    ALLOW_OAUTH_ORIGIN=""
  fi
  user_toml_warn builder-api-proxy
  mkdir -p /hab/user/builder-api-proxy/config
  cat <<-EOT >/hab/user/builder-api-proxy/config/user.toml
		log_level="info"
		enable_builder = false
		app_url = "${APP_URL}"
		load_balanced = ${LOAD_BALANCED}

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
		limit_req_zone_unknown = "\$limit_unknown zone=unknown:10m rate=30r/s"
		limit_req_unknown      = "burst=90 nodelay"
		limit_req_zone_known   = "\$http_x_forwarded_for zone=known:10m rate=30r/s"
		limit_req_known        = "burst=90 nodelay"
		$ALLOW_OAUTH_ORIGIN

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
  sudo hab svc load "${BLDR_DATASTORE_ORIGIN:=$BLDR_ORIGIN}/builder-datastore" --channel "${BLDR_DATASTORE_CHANNEL:=$BLDR_CHANNEL}" --force
}

start_minio() {
  sudo hab svc load "${BLDR_MINIO_ORIGIN:=$BLDR_ORIGIN}/builder-minio" --channel "${BLDR_MINIO_CHANNEL:=$BLDR_CHANNEL}" --force
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
  echo
  echo "Starting Habitat Supervisor"
  create_users
  sudo systemctl start hab-sup
  sleep 2
}

start_frontend() {
  echo
  echo "Starting Builder Frontend Services"
  start_memcached
  start_api
  start_api_proxy
}

set_pg_password() {
  while [ ! -f /hab/svc/builder-datastore/config/pwfile ]; do
    sleep 2
  done
  local pg_pass
  pg_pass=$(cat /hab/svc/builder-datastore/config/pwfile)
  cat <<-EOT >pg_pass.toml
		[datastore]
		password = "$pg_pass"
	EOT
  hab config apply builder-api.default "$(date +%s)" pg_pass.toml
}

start_builder() {
  echo
  echo "Starting Builder Services"
  if [ "${PG_EXT_ENABLED:-false}" = "false" ]; then
    init_datastore
    start_datastore
    set_pg_password
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

install_frontend() {
  #Check if api and datastore services are already configures or installed.
  if sudo hab svc status habitat/builder-api >/dev/null 2>/dev/null; then
    echo "ERROR: ${BLDR_ORIGIN}/builder-api is already running on this node!"
    echo "This script is only intended to be run on nodes that do not already"
    echo "have builder-api installed or configured. This process could be"
    echo "data destructive if performed on a pre-existing builder api node."
    echo
    echo "To proceed, unload ${BLDR_ORIGIN}/builder-api and its svc directory."
    return
  fi

  if sudo hab svc status habitat/builder-datastore >/dev/null 2>/dev/null; then
    echo "ERROR: ${BLDR_ORIGIN}/builder-datastore is running on this node!"
    echo "This script is only intended to be run on nodes that do not already"
    echo "have builder services installed, --install-frontend should not be used "
    echo "on a node running habitat/builder-datastore"
    echo
    return
  fi

  start_init
  configure
  start_frontend
  sleep 4

  local key_retry=0
  while ! ls /hab/svc/builder-api/files/*.pub &>/dev/null; do
    if [ $key_retry -eq 5 ]; then
      echo "builder key never showed up on ring...generating."
      generate_bldr_keys
      upload_ssl_certificate
      break
    fi
    echo "waiting for builder key..."
    key_retry=$((++key_retry))
    sleep 5
  done
}

install_postgresql() {
  #Check if externally hosted PostgreSQL is enabled
  if [ "${PG_EXT_ENABLED:-false}" = "true" ]; then
    echo "ERROR: --install-postgresql can not be used if you are using"
    echo "externally hosted PostgreSQL(RDS, Azure Database for PostgreSql etc)."
    echo "Set PG_EXT_ENABLED=false to fix this error."
    echo
    return
  fi

  start_init
  init_datastore
  start_datastore
  set_pg_password
  configure
  sleep 4
}

install_minio() {
  #Check if using S3 or Artifactory directly
  if [ "${S3_ENABLED:-false}" = "true" ] || [ "${ARTIFACTORY_ENABLED:-false}" = "true" ]; then
    echo "ERROR: --install-minio can not be used if you are using S3 or Artifactory directly."
    echo "Set S3_ENABLED=false and ARTIFACTORY_ENABLED=false to fix this error."
    echo
    return
  fi

  start_init
  configure
  start_minio
  sleep 4
}

install_tar() {
  hab pkg path core/tar >/dev/null 2>&1 || hab pkg install core/tar -b
}

Help() {
  # Display Help
  cat <<-EOF
		Habitat Builder Service Provisioning Script
		The default action, when no argument are passed, is to provision a node with Frontend and Backend services.

		Syntax: $0 <SUBCOMMAND>

		options:

		  -h, --help            Print this Help.

		  --install-frontend    Provision a Frontend/API only.

		  --install-postgresql  Provision the datastore only.

		  --install-minio       Provision the minio server only.

	EOF
}

create_users() {
  if command -v useradd >/dev/null; then
    sudo useradd --system --no-create-home hab || true
  else
    sudo adduser --system hab || true
  fi
  if command -v groupadd >/dev/null; then
    sudo groupadd --system hab || true
  else
    sudo addgroup --system hab || true
  fi
}

install_options() {
  if [ "${FRONTEND_INSTALL:-0}" = 1 ]; then
    if [[ "${POSTGRESQL_INSTALL:-0}" = 1 || "${MINIO_INSTALL:-0}" = 1 ]]; then
      echo "ERROR: --install-frontend can not not be used along with -install-postgresql or --install-minio "
      echo
      exit 1
    else
      install_frontend
    fi
  else
    if [ "${POSTGRESQL_INSTALL:-0}" = 1 ]; then
      install_postgresql
    fi
    if [ "${MINIO_INSTALL:-0}" = 1 ]; then
      install_minio
    fi
  fi
}

if [ "$#" -eq 0 ]; then
  start_init
  start_builder
else
  for arg in "$@"; do
    if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
      Help
    elif [ "$arg" == "--install-frontend" ]; then
      export FRONTEND_INSTALL=1
    elif [ "$arg" == "--install-postgresql" ]; then
      export POSTGRESQL_INSTALL=1
    elif [ "$arg" == "--install-minio" ]; then
      export MINIO_INSTALL=1
    else
      echo "ERROR: Invalid argument provided"
      echo "Use -h or --help to view the available options."
      exit 1
    fi
  done
  install_options
fi
