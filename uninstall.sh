#!/bin/bash
systemctl stop hab-sup
rm -rf /hab/sup/default/specs/builder-*
rm -rf /hab/pkgs/habitat
