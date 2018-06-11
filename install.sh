#!/bin/bash

umask 0022

pushd scripts > /dev/null
sudo ./install-hab.sh
sudo ./hab-sup.service.sh
sudo ./provision.sh
popd > /dev/null
