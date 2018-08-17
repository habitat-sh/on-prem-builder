#!/bin/bash

umask 0022

type curl >/dev/null 2>&1 || { echo >&2 "curl is required for installation of habitat, but was not found. Exiting."; exit 1; }

curl https://raw.githubusercontent.com/habitat-sh/on-prem-builder/master/NOTICE

echo
read -r -p "Continue with installation? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    pushd scripts > /dev/null
    sudo -E ./install-hab.sh
    sudo -E ./hab-sup.service.sh
    sudo -E ./provision.sh
    popd > /dev/null
fi
