#!/bin/bash

# The purpose of this script is to download the latest stable version of every
# package in the core-plans repo, tar them up, and upload to S3. It also supports
# downloading the archive from S3, extracting it, and uploading to a new depot.
#
# There are some environment variables you can set to control the behavior of this
# script:
#
# HAB_ON_PREM_BOOTSTRAP_BUCKET_NAME: This controls the name of the S3 bucket where
# the archive is placed. The default is habitat-on-prem-builder-bootstrap
#
# HAB_ON_PREM_BOOTSTRAP_S3_ROOT_URL: This controls the domain name for S3 where the
# files will be downloaded from. The default is https://s3-us-west-2.amazonaws.com
#
# HAB_ON_PREM_BOOTSTRAP_DONT_CLEAN_UP: This controls whether the script cleans up
# after itself by deleting the intermediate files that were created during its run.
# Setting this variable to any value will cause the cleanup to be skipped. By
# default, the script will clean up after itself.

set -euo pipefail

usage() {
  echo "Usage: on-prem-archive.sh {create-archive|populate-depot <DEPOT_URL>}"
  exit 1
}

exists() {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}

s3_cp() {
  aws s3 cp --acl=public-read ${1} ${2} >&2
}

check_tools() {
  for tool
  do
    if ! exists "$tool"; then
      echo "Please install $tool and run this script again."
      exit 1
    fi
  done
}

check_vars() {
  for var
  do
    if [ -z "${!var:-}" ]; then
      echo "Please ensure that $var is exported in your environment and run this script again."
      exit 1
    fi
  done
}

cleanup() {
    if [ "${HAB_ON_PREM_BOOTSTRAP_DONT_CLEAN_UP:-}" ]; then
      echo "Cleanup skipped."
    else
      echo "Cleaning up."

      if [ -d "${tmp_dir:-}" ]; then
        rm -fr "$tmp_dir"
      fi

      if [ -d "${core_tmp:-}" ]; then
        rm -fr "$core_tmp"
      fi

      if [ -f "${tar_file:-}" ]; then
        rm "$tar_file"
      fi
    fi

    echo "Done."
}

trap cleanup EXIT

download_hart_if_missing() {
  local local_file=$1
  local slash_ident=$2
  local status_line=$3

  if [ -f "$local_file"  ]; then
    echo "$status_line $slash_ident is already present in our local directory. Skipping download."
    return 1
  else
    echo "$status_line Downloading $slash_ident"
    curl -s -H "Accept: application/json" -o "$local_file" "$upstream_depot/v1/depot/pkgs/$slash_ident/download"
  fi
}

bucket="${HAB_ON_PREM_BOOTSTRAP_BUCKET_NAME:-habitat-on-prem-builder-bootstrap}"
marker="LATEST.tar.gz"

case "${1:-}" in
  create-archive)
    check_tools aws git curl jq xzcat
    check_vars AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY

    core_tmp=$(mktemp -d)
    upstream_depot="https://bldr.habitat.sh"
    core="$core_tmp/core-plans"
    bootstrap_file="on-prem-bootstrap-$(date +%Y%m%d%H%M%S).tar.gz"
    tar_file="/tmp/$bootstrap_file"
    tmp_dir=$(mktemp -d)

    # we need to store both harts and keys because hab will try to upload public keys
    # when it uploads harts and will panic if the key that a hart was built with doesn't
    # exist.
    mkdir -p "$tmp_dir/harts"
    mkdir -p "$tmp_dir/keys"

    # download keys first
    keys=$(curl -s -H "Accept: application/json" "$upstream_depot/v1/depot/origins/core/keys" | jq ".[] | .location")
    for k in $keys
    do
      key=$(tr -d '"' <<< $k)
      release=$(cut -d '/' -f 5 <<< $key)
      curl -s -H "Accept: application/json" -o "$tmp_dir/keys/$release.pub" "$upstream_depot/v1/depot$key"
    done

    git clone https://github.com/habitat-sh/core-plans.git "$core"
    cd "$core"
    dir_list=$(find . -type f -name "plan.sh" -printf "%h\n" | xargs basename -a | sort -u)
    pkg_total=$(echo "$dir_list" | wc -l)
    pkg_count="0"

    for p in $dir_list
    do
      pkg_count=$((pkg_count+1))
      echo
      echo "[$pkg_count/$pkg_total] Resolving latest stable version of core/$p"
      latest=$(curl -s -H "Accept: application/json" "$upstream_depot/v1/depot/channels/core/stable/pkgs/$p/latest")
      raw_ident=$(echo "$latest" | jq ".ident")

      if [ "$raw_ident" = "null" ]; then
        echo "Failed to find a latest version. Skipping."
        continue
      fi

      slash_ident=$(jq '"\(.origin)/\(.name)/\(.version)/\(.release)"' <<< $raw_ident | tr -d '"')
      target=$(jq ".target" <<< $latest | tr -d '"')

      # check to see if we have this file before fetching it again
      local_file="$tmp_dir/harts/$(tr '/' '-' <<< $slash_ident)-$target.hart"

      if download_hart_if_missing "$local_file" "$slash_ident" "[$pkg_count/$pkg_total]"; then
        # now extract the target and tdeps and download those too
        local_tar=$(basename "$local_file" .hart).tar
        tail -n +6 "$local_file" | unxz > "$local_tar"

        if tar tf "$local_tar" --no-anchored TARGET TDEPS > /dev/null 2>&1; then
          target=$(tail -n +6 $local_file | xzcat | tar xfO - --no-anchored TARGET)
          tdeps=$(tail -n +6 $local_file | xzcat | tar xfO - --no-anchored TDEPS)
          dep_total=$(echo "$tdeps" | wc -l)
          dep_count="0"

          echo "[$pkg_count/$pkg_total] $slash_ident has the following $dep_total transitive dependencies:"
          echo
          echo "$tdeps"
          echo
          echo "Processing dependencies now."
          echo

          for dep in $tdeps
          do
            dep_count=$((dep_count+1))
            file_to_check="$tmp_dir/harts/$(echo $dep | tr '/' '-')-$target.hart"
            download_hart_if_missing "$file_to_check" "$dep" "[$pkg_count/$pkg_total] [$dep_count/$dep_total]" || true
          done
        else
          echo "[$pkg_count/$pkg_total] $slash_ident either has no TARGET or no TDEPS file. Skipping processing of dependencies."
        fi
      fi
    done

    cd /tmp
    tar zcvf $tar_file -C $tmp_dir .
    echo "Uploading tar file to S3."
    s3_cp $tar_file s3://$bucket/
    s3_cp s3://$bucket/$bootstrap_file s3://$bucket/$marker
    echo "Upload to S3 finished."

    ;;
  populate-depot)
    if [ -z "${2:-}" ]; then
      usage
    fi

    depot_url=$2

    check_tools curl
    check_vars HAB_AUTH_TOKEN

    s3_root_url="${HAB_ON_PREM_BOOTSTRAP_S3_ROOT_URL:-https://s3-us-west-2.amazonaws.com}/$bucket"
    tmp_dir=$(mktemp -d)

    cd "$tmp_dir"
    echo "Fetching latest package bootstrap file."
    curl -O "$s3_root_url/$marker"
    tar zxvf $marker

    echo
    echo "Importing keys"
    keys=$(find . -type f -name "*.pub")
    key_total=$(echo "$keys" | wc -l)
    key_count="0"

    for key in $keys
    do
      key_count=$((key_count+1))
      echo
      echo "[$key_count/$key_total] Importing $key"
      hab origin key import < $key
    done

    echo
    echo "Uploading hart files."

    harts=$(find . -type f -name "*.hart")
    hart_total=$(echo "$harts" | wc -l)
    hart_count="0"

    for hart in $harts
    do
      hart_count=$((hart_count+1))
      echo
      echo "[$hart_count/$hart_total] Uploading $hart to the depot at $depot_url"

      # Retry this operation up to 5 times before aborting
      for _ in {1..5}
      do
        hab pkg upload --url "$depot_url" --channel stable "$hart" && break
        echo "Upload failed. Sleeping 5 seconds and retrying."
        sleep 5
      done
    done

    echo "Package uploads finished."

    ;;
  *)
    usage
esac
