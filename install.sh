#!/bin/bash

umask 0022

# Resolve paths relative to this script's location (not $PWD) so
# check_envfile works regardless of the caller's current directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

sudo() {
  if [[ $EUID = 0 ]]; then
    command sudo "$@"
    return
  fi

  # Newer sudo defaults (e.g. Ubuntu 26.04) no longer support "-E", and many
  # sudoers configs disable the SETENV tag, which is what `sudo VAR=val cmd`
  # relies on. Forwarding the variables as arguments to `env` instead avoids
  # needing any special sudo privilege, since sudo just sees "env" as the
  # command being run and the assignments as plain arguments to it. This also
  # forwards everything scripts/hab-sup.service.sh and scripts/provision.sh
  # need (proxy settings, HAB_BLDR_URL/PEER_ARG), not just the auth token and
  # license.
  local -a forward_env=()
  local var
  for var in HAB_AUTH_TOKEN HAB_LICENSE HAB_BLDR_URL HAB_BLDR_PEER_ARG \
    HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy \
    SSL_CERT_FILE; do
    if [[ -n "${!var:-}" ]]; then
      forward_env+=("${var}=${!var}")
    fi
  done
  command sudo env "${forward_env[@]}" "$@"
}

check_envfile() {
  if [ -f "${SCRIPT_DIR}/bldr.env" ]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/bldr.env"
  elif [ -f /vagrant/bldr.env ]; then
    # shellcheck disable=SC1091
    source /vagrant/bldr.env
  else
    echo "ERROR: bldr.env file is missing!"
    exit 1
  fi
}

cat NOTICE
echo

license="${HAB_LICENSE:-}"
declare response

if [ "$license" == "accept" ] || [ "$license" == "accept-no-persist" ]; then
  echo "INFO: Detected HAB_LICENSE=${HAB_LICENSE}"
  echo "Continuing with installation"
  response="y"
else
  cat LICENSE-NOTICE
  echo

  read -r -p "Do you accept the terms of this license? Answering yes will proceed with the installation. [y/N] " response
fi

if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  pushd scripts >/dev/null || exit
  export HAB_LICENSE=accept
  check_envfile
  sudo ./install-hab.sh
  sudo ./hab-sup.service.sh
  sudo ./provision.sh "$@"
  popd >/dev/null || exit
fi
