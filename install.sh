#!/bin/bash

umask 0022

sudo () {
  [[ $EUID = 0 ]] || set -- command sudo -E "$@"
  "$@"
}

type curl >/dev/null 2>&1 || { echo >&2 "curl is required for installation, but was not found. Exiting."; exit 1; }

source license.sh

cat NOTICE
read -r -p "Continue with installation? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  source settings.env
  pushd scripts > /dev/null
  sudo ./install.sh
  sudo ./sup.service.sh
  sudo ./provision.sh
  popd > /dev/null
fi
