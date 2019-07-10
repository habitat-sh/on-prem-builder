#!/bin/bash

set -euo pipefail

type curl >/dev/null 2>&1
if [ $? -ne 1 ]; then
  echo >&2 "curl is required for installation, but was not found. Exiting."
  exit 1
fi

curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | bash
${HAB_CMD} pkg install core/cacerts
${HAB_CMD} pkg install core/hab-sup
