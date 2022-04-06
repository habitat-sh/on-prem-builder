#!/bin/bash

umask 0022

sudo () {
    # the -E pulls in environment variables like HAB_LICENSE
    [[ $EUID = 0 ]] || set -- command sudo -E "$@"
    "$@"
}

check_envfile() {
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
    check_envfile
    sudo ./hab-sup.service.sh
    sudo ./provision.sh "$@"
    popd > /dev/null
fi
