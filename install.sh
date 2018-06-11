#!/bin/bash

umask 0022

pushd scripts > /dev/null
sudo -E ./install-hab.sh
sudo -E ./hab-sup.service.sh
sudo -E ./provision.sh
popd > /dev/null
