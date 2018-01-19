#!/bin/bash

pushd scripts > /dev/null
./install-hab.sh
./hab-sup.service.sh
./provision.sh
popd > /dev/null
