#!/bin/bash

set -euo pipefail

install_hab() {
  type curl >/dev/null 2>&1 || { echo >&2 "curl is required for installation of habitat, but was not found. Exiting."; exit 1; }
  curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | bash
}

install_deps() {
  hab pkg path core/cacerts >/dev/null 2>&1 || hab pkg install core/cacerts
  hab pkg path core/hab-sup >/dev/null 2>&1 || hab pkg install core/hab-sup
}

type hab > /dev/null 2>&1 || install_hab
install_deps
