#!/bin/bash

# The purpose of this script is to download the latest version of every package in
# the core-plans repo (via hab pkg install) and then upload the resulting hab
# artifact cache. Note that this does not support air-gapped environments.
#
# Also note that if you run this on a machine that already has a populated hab
# artifact cache, you will likely be uploading more packages than you think.
# In practice, this will probably not be an issue.

set -eo pipefail

exists() {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}

check_tools() {
  local ref=$1[@]

  for tool in ${!ref}
  do
    if ! exists "$tool"; then
      echo "Please install $tool and run this script again."
      exit 1
    fi
  done
}

check_vars() {
  local ref=$1[@]

  for var in ${!ref}
  do
    if [ -z "${!var}" ]; then
      echo "Please ensure that $var is exported in your environment and run this script again."
      exit 1
    fi
  done
}

help() {
  echo "Usage: on-prem-install.sh <ON_PREM_DEPOT_URL>"
}

if [ -z "$1" ]; then
  help
  exit 1
fi

required_tools=( git hab )
required_vars=( HAB_AUTH_TOKEN )

check_tools required_tools
check_vars required_vars

core_tmp=$(mktemp -d)
core="$core_tmp/core-plans"
artifact_cache="/hab/cache/artifacts"

mkdir -p "$artifact_cache"

git clone https://github.com/habitat-sh/core-plans.git "$core"
pushd "$core"
dir_list=$(find . -type f -name "plan.sh" -printf "%h\n" | sed -r "s|^\.\/||" | sort -u)
total=$(echo "$dir_list" | wc -l)
count="0"

for p in $dir_list
do
  count=$((count+1))
  echo ""
  echo "[$count/$total] Installing latest version of core/$p"

  hab pkg install core/$p || true # if this fails, it's likely because of a mismatched platform and we don't want to completely abort
done
popd

pushd "$artifact_cache"
harts=$(find . -type f -name "*.hart")
total=$(echo "$harts" | wc -l)
count="0"

for hart in $harts
do
  count=$((count+1))
  echo ""
  echo "[$count/$total] Uploading $hart to the depot at $1"
  hab pkg upload --url $1 --channel stable $hart || true # again, don't abort the whole process if an upload fails - just keep going.
done

echo "Package uploads finished."
popd

rm -fr "$core_tmp"

echo "Done."
