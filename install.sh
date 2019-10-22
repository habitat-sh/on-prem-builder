#!/bin/bash

umask 0022

sudo () {
    [[ $EUID = 0 ]] || set -- command sudo -E "$@"
    "$@"
}

cat NOTICE
echo

license="${HAB_LICENSE:-}"

if [ "$license" == "accept" ] || [ "$license" == "accept-no-persist" ]; then
  read -r -p "Continue with installation? [y/N] " response
else
  cat LICENSE-NOTICE
  echo

  read -r -p "Do you accept the terms of this license? Answering yes will proceed with the installation. [y/N] " response
fi

if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    pushd scripts > /dev/null
    export HAB_LICENSE=accept
    # use -E to pull in the HAB_LICENSE Env variable
    sudo -E ./install-hab.sh
    sudo ./hab-sup.service.sh
    sudo ./provision.sh
    popd > /dev/null
fi
