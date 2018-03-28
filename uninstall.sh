#!/bin/bash
hab svc status | tail -n +2 | grep "^habitat\/" | awk -F'/' '{print $2}' | xargs -I{} hab svc stop habitat/{}
hab svc status | tail -n +2 | grep "^habitat\/" | awk -F'/' '{print $2}' | xargs -I{} hab svc unload habitat/{}
rm -rf /hab/pkgs/habitat
