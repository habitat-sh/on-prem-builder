#!/bin/bash

umask 0022

sudo () {
    # the -E pulls in environment variables like HAB_LICENSE
    [[ $EUID = 0 ]] || set -- command sudo -E "$@"
    "$@"
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
    pushd scripts > /dev/null
    export HAB_LICENSE=accept
    sudo ./install-hab.sh
    sudo ./hab-sup.service.sh
    sudo ./provision.sh "$@"
    popd > /dev/null
fi
