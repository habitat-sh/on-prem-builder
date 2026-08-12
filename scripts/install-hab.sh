#!/bin/bash

set -euo pipefail

install_hab() {
  type curl >/dev/null 2>&1 || { echo >&2 "curl is required for installation of habitat, but was not found. Exiting."; exit 1; }
  curl -fsSL https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | bash -s -- -v 1.6.1245
}

install_deps() {
  hab pkg path core/cacerts >/dev/null 2>&1 || hab pkg install core/cacerts
  hab pkg path chef/hab-sup >/dev/null 2>&1 || hab pkg install chef/hab-sup
}

hab pkg path chef/hab >/dev/null 2>&1 || install_hab
type hab > /dev/null 2>&1 || install_hab
install_deps
