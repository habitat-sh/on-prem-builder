#!/bin/bash

set -eou pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

export HAB_ORIGIN=habitat
hab origin key download "$HAB_ORIGIN"
hab origin key download --auth "$HAB_AUTH_TOKEN" --secret "$HAB_ORIGIN"

pushd "$dir" > /dev/null
hab pkg build .
popd > /dev/null

rm "$dir/pkg-tool"