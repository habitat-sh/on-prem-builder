#!/bin/bash

sudo hab svc status | tail -n +2 | grep "^habitat\/" | awk -F'/' '{print $2}' | xargs -I{} hab svc unload habitat/{}
sudo rm -rf /hab/pkgs/habitat
