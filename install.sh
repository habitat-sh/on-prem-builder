#!/bin/bash

umask 0022

sudo () {
    [[ $EUID = 0 ]] || set -- command sudo -E "$@"
    "$@"
}

type curl >/dev/null 2>&1 || { echo >&2 "curl is required for installation of habitat, but was not found. Exiting."; exit 1; }

curl https://raw.githubusercontent.com/habitat-sh/on-prem-builder/master/NOTICE
echo

license="${HAB_LICENSE:-}"

if [ "$license" == "accept" ] || [ "$license" == "accept-no-persist" ]; then
  read -r -p "Continue with installation? [y/N] " response
else
  curl https://raw.githubusercontent.com/habitat-sh/on-prem-builder/master/LICENSE-NOTICE
  echo

  read -r -p "Do you accept the terms of this license? Answering yes will proceed with the installation. [y/N] " response
fi

if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    pushd scripts > /dev/null
    sudo ./install-hab.sh
    sudo ./hab-sup.service.sh
    sudo ./provision.sh
    popd > /dev/null
fi
