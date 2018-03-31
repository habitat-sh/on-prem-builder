#!/bin/bash

set -eou pipefail

if [ -f ../bldr.env ]; then
  source ../bldr.env
elif [ -f /vagrant/bldr.env ]; then
  source /vagrant/bldr.env
else
  echo "bldr.env file required"
  exit 1
fi

init-datastore() {
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
  while [ ! -f /hab/svc/builder-datastore/config/pwfile ]
  do
    sleep 2
  done

  export PGPASSWORD
  PGPASSWORD=$(cat /hab/svc/builder-datastore/config/pwfile)

  mkdir -p /hab/svc/builder-api
  cat <<EOT > /hab/svc/builder-api/user.toml
log_level="info"
jobsrv_enabled = false

[depot]
jobsrv_enabled = false

["$OAUTH_PROVIDER"]
enabled = true
api_url = "$OAUTH_API_URL"
token_url = "$OAUTH_TOKEN_URL"
redirect_url = "$OAUTH_REDIRECT_URL"
client_id = "$OAUTH_CLIENT_ID"
client_secret = "$OAUTH_CLIENT_SECRET"
EOT

  mkdir -p /hab/svc/builder-api-proxy
  cat <<EOT > /hab/svc/builder-api-proxy/user.toml
log_level="info"
enable_builder = false
app_url = "${APP_URL}:9636"

[oauth]
provider = "$OAUTH_PROVIDER"
client_id = "$OAUTH_CLIENT_ID"
authorize_url = "$OAUTH_AUTHORIZE_URL"
redirect_url = "$OAUTH_REDIRECT_URL"
EOT

  mkdir -p /hab/svc/builder-originsrv
  cat <<EOT > /hab/svc/builder-originsrv/user.toml
log_level="info"

[app]
shards = [
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
  29,
  30,
  31,
  32,
  33,
  34,
  35,
  36,
  37,
  38,
  39,
  40,
  41,
  42,
  43,
  44,
  45,
  46,
  47,
  48,
  49,
  50,
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  58,
  59,
  60,
  61,
  62,
  63,
  64,
  65,
  66,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  75,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
  91,
  92,
  93,
  94,
  95,
  96,
  97,
  98,
  99,
  100,
  101,
  102,
  103,
  104,
  105,
  106,
  107,
  108,
  109,
  110,
  111,
  112,
  113,
  114,
  115,
  116,
  117,
  118,
  119,
  120,
  121,
  122,
  123,
  124,
  125,
  126,
  127
]

[datastore]
password = "$PGPASSWORD"
database = "builder_originsrv"
EOT

  mkdir -p /hab/svc/builder-sessionsrv
  cat <<EOT > /hab/svc/builder-sessionsrv/user.toml
log_level="info"
jobsrv_enabled = false

[app]
shards = [
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
  29,
  30,
  31,
  32,
  33,
  34,
  35,
  36,
  37,
  38,
  39,
  40,
  41,
  42,
  43,
  44,
  45,
  46,
  47,
  48,
  49,
  50,
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  58,
  59,
  60,
  61,
  62,
  63,
  64,
  65,
  66,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  75,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
  91,
  92,
  93,
  94,
  95,
  96,
  97,
  98,
  99,
  100,
  101,
  102,
  103,
  104,
  105,
  106,
  107,
  108,
  109,
  110,
  111,
  112,
  113,
  114,
  115,
  116,
  117,
  118,
  119,
  120,
  121,
  122,
  123,
  124,
  125,
  126,
  127
]

[datastore]
password = "$PGPASSWORD"
database = "builder_sessionsrv"
EOT
}

start-api() {
  hab svc load habitat/builder-api --bind router:builder-router.default --channel "${BLDR_CHANNEL}" --force
}

start-api-proxy() {
  hab svc load habitat/builder-api-proxy --bind http:builder-api.default --channel "${BLDR_CHANNEL}" --force
}

start-datastore() {
  hab svc load habitat/builder-datastore --channel "${BLDR_CHANNEL}" --force
}

start-originsrv() {
  hab svc load habitat/builder-originsrv --bind router:builder-router.default --bind datastore:builder-datastore.default --channel "${BLDR_CHANNEL}" --force
}

start-router() {
  hab svc load habitat/builder-router --channel "${BLDR_CHANNEL}" --force
}

start-sessionsrv() {
  hab svc load habitat/builder-sessionsrv --bind router:builder-router.default --bind datastore:builder-datastore.default --channel "${BLDR_CHANNEL}" --force
}

generate_bldr_keys() {
  keys=( $(find /hab/cache/keys -name "bldr-*.pub") )

  if [ "${#keys[@]}" -gt 0 ]; then
    KEY_NAME=$(echo $keys[0] | grep -Po "bldr-\d+")
    echo "Re-using existing builder key: $KEY_NAME"
  else
    KEY_NAME=$(hab user key generate bldr | grep -Po "bldr-\d+")
    echo "Generated new builder key: $KEY_NAME"
  fi

  hab file upload "builder-api.default" "$(date +%s)" "/hab/cache/keys/${KEY_NAME}.pub"
  hab file upload "builder-api.default" "$(date +%s)" "/hab/cache/keys/${KEY_NAME}.box.key"
}

start-builder() {
  init-datastore
  start-datastore
  configure
  start-router
  start-api
  start-api-proxy
  start-originsrv
  start-sessionsrv
  sleep 2
  generate_bldr_keys
}

if command -v useradd > /dev/null; then
  sudo -E useradd --system --no-create-home hab || true
else
  sudo -E adduser --system hab || true
fi
if command -v groupadd > /dev/null; then
  sudo -E groupadd --system hab || true
else
  sudo -E addgroup --system hab || true
fi

systemctl start hab-sup
sleep 2
start-builder
