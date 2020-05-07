#!/bin/bash

echo "WARNING: This will uninstall all Builder Services. All data will be preserved."
read -p "Proceed? [y|n]" -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi
echo
echo "Uninstalling.."
systemctl stop hab-sup
rm -rf /hab/sup/default/specs/builder-*
rm -rf /hab/pkgs/habitat
echo
