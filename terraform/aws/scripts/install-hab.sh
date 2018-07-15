#!/bin/bash

set -euo pipefail

type curl >/dev/null 2>&1 || { echo >&2 "curl is required for installation of habitat, but was not found. Exiting."; exit 1; }
curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | bash
hab pkg install core/cacerts
hab pkg install core/hab-sup
