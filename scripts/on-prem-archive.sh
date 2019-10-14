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
#
# HAB_ON_PREM_BOOTSTRAP_KEEP_ARCHIVE_FILE: Sometimes you don't want to delete the
# archive file you just spent many minutes creating. Setting this keeps the file.
#
# HAB_ON_PREM_BOOTSTRAP_NO_UPLOAD: This controls whether the script will upload
# the archive file to AWS S3 bucket.  Very handy when your company does not have
# access to AWS.
#
# Additionally, if you're using this script to populate an existing depot, and you
# don't have network connectivity to download a tarball from S3, you can pass the
# path to your existing tarball as the third argument and that will be used to
# upload packages instead. Note that this script expects the tarball passed to be
# in the same format as the one that this script generates - it can't have any
# random internal structure.

set -euo pipefail

usage() {
  echo "Usage: on-prem-archive.sh {create-archive | populate-depot <DEPOT_URL> [PATH_TO_EXISTING_TARBALL] | download-archive | upload-archive <PATH_TO_EXISTING_TARBALL>} | sync-packages <DEPOT_URL> [base-plans]"
  exit 1
}

exists() {
  if command -v "$1" >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}

s3_cp() {
  hab pkg exec core/aws-cli aws s3 cp --acl=public-read "${1}" "${2}" >&2
}

check_root(){
  if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
  fi
}

install_tools() {
  for tool
  do
    echo "Installing ${tool} from Habitat package."
    if [[ "$tool" == "jq" ]]; then
        HAB_AUTH_TOKEN="" hab pkg install core/jq-static
    elif [[ "$tool" == "aws" ]]; then
        HAB_AUTH_TOKEN="" hab pkg install core/aws-cli
    elif [[ "$tool" == "b2sum" ]]; then
        HAB_AUTH_TOKEN="" hab pkg install core/coreutils
    elif [[ "$tool" == "xzcat" ]]; then
        HAB_AUTH_TOKEN="" hab pkg install core/xz
    else
        HAB_AUTH_TOKEN="" hab pkg install core/"${tool}"
    fi
  done
  
  CURL_CMD="hab pkg exec core/curl curl"
  JQ_CMD="hab pkg exec core/jq-static jq"
  B2SUM_CMD="hab pkg exec core/coreutils b2sum"
  GIT_CMD="hab pkg exec core/git git"
  XZCAT_CMD="hab pkg exec core/xz xzcat"
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

      if [ -z "${HAB_ON_PREM_BOOTSTRAP_KEEP_ARCHIVE_FILE:-}" ] && [ -f "${tar_file:-}" ]; then
        rm "$tar_file"
      fi
    fi

    echo "Done."
}

download_latest_archive() {
  ${CURL_CMD} -O "$s3_root_url/$marker"
}

trap cleanup EXIT

download_hart_if_missing() {
  local local_file=$1
  local slash_ident=$2
  local status_line=$3
  local target=$4

  if [ -f "$local_file"  ]; then
    echo "$status_line $slash_ident is already present in our local directory. Skipping download."
    return 1
  else
    echo "$status_line Downloading $slash_ident"
    ${CURL_CMD} -s -S --retry 6 --retry-delay 10 -H "Accept: application/json" -o "$local_file" "$upstream_depot/v1/depot/pkgs/$slash_ident/download?target=$target"
  fi
}

latest_ident() {
  local pkg_name_=$1
  local target_=$2
  local latest_
  local raw_ident_

  latest_=$(${CURL_CMD} -s -H "Accept: application/json" "$upstream_depot/v1/depot/channels/core/stable/pkgs/$pkg_name_/latest?target=$target_")
  set +e
  raw_ident_=$(echo "$latest_" | ${JQ_CMD} ".ident")
  retVal=$?
  if [ $retVal -ne 0 ]; then
    echo "-1"
  else
    echo "$raw_ident_"
  fi
  set -e
}

populate_packages() {
  local dir_list=$1

  for p in $dir_list
  do
    IFS='~' read -ra parts <<< "$p"
    pkg_name=${parts[0]}
    plan_name=${parts[1]}
    actual_pkg_name=$(grep -m 1 pkg_name "$pkg_name/$plan_name" | cut -d = -f 2 | tr -d ' "' | tr '[:upper:]' '[:lower:]')
    packages+=("$actual_pkg_name~$plan_name")
  done

  # re-sort and unique the array, otherwise we end up with dupes
  IFS=" " read -ra packages <<< "$(echo "${packages[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')"
}

upload_archive() {
  local archive=$1
  local bs_file

  if [ "${HAB_ON_PREM_BOOTSTRAP_NO_UPLOAD:-}" ]; then
    echo "Uploading skipped."
  else
    echo "Uploading $archive"

    bs_file=$(basename "$1")
    echo "Uploading tar file to S3."
    s3_cp "$archive" "s3://$bucket/"
    s3_cp "s3://$bucket/$bs_file" "s3://$bucket/$marker"
    echo "Upload to S3 finished."
  fi
}

populate_dirs() {
  core_tmp=$(mktemp -d)
  upstream_depot="https://bldr.habitat.sh"
  core="$core_tmp/core-plans"
  habitat="$core_tmp/habitat"
  win_svc="$core_tmp/windows-service"
  bootstrap_file="on-prem-bootstrap-$(date +%Y%m%d%H%M%S).tar.gz"
  tar_file="/tmp/$bootstrap_file"
  tmp_dir=$(mktemp -d)

  # we need to store both harts and keys because hab will try to upload public keys
  # when it uploads harts and will panic if the key that a hart was built with doesn't
  # exist.
  mkdir -p "$tmp_dir/harts"
  mkdir -p "$tmp_dir/keys"

  # download keys first
  keys=$(${CURL_CMD} -s -H "Accept: application/json" "$upstream_depot/v1/depot/origins/core/keys" | ${JQ_CMD} ".[] | .location")
  for k in $keys
  do
    key=$(tr -d '"' <<< "$k")
    release=$(cut -d '/' -f 5 <<< "$key")
    ${CURL_CMD} -s -H "Accept: application/json" -o "$tmp_dir/keys/$release.pub" "$upstream_depot/v1/depot$key"
  done

  ${GIT_CMD} clone --depth 1 https://github.com/habitat-sh/core-plans.git "$core"
  cd "$core"

  # we want both the directory name and the file name here
  cp_dir_list=$(find . -type f -name "plan.*" -printf "%h~%f\\n" | sort -u)
  populate_packages "$cp_dir_list"

  # We should also pull in the windows-service component
  ${GIT_CMD} clone --depth 1 https://github.com/habitat-sh/windows-service.git "$win_svc"
  cd "$win_svc"

  win_dir_list=$(find . -type f -name "plan.ps1" -printf "%h~%f\\n" | sort -u)
  populate_packages "$win_dir_list"

 # # let's also pull in any hab components that might have a hart file
  ${GIT_CMD} clone --depth 1 https://github.com/habitat-sh/habitat.git "$habitat"
  cd "$habitat/components"

  hb_dir_list=$(find . \( \( -type f -a -name "plan.sh" \) -o \
                       \( -name "plan.ps1" \) \
                       \) -not -path "./core/*" -printf "%h~%f\\n" | sort -u)
  populate_packages "$hb_dir_list"

  pkg_total=${#packages[@]}
  pkg_count="0"
}

read_base_plans() {
  base_plans=()
  cd "$core"
  while read -r line
  do
    first=( $line )
    base_plans+=(${first##*/})
  done < base-plans.txt
}

read_hab_plans() {
    hab_plans=( "hab-sup" "hab-launcher" "windows-service" )
}

upload_keys() {
    echo
    echo "Uploading keys to ${depot_url}"

    cd "$tmp_dir/keys"
    keys=$(find . -type f -name "*.pub")
    key_total=$(echo "$keys" | wc -l)
    key_count="0"

    for key in $keys
    do
      key_count=$((key_count+1))
      echo
      echo "[$key_count/$key_total] Uploading $key"
      hab origin key upload -u ${depot_url} --pubfile "$key"
    done
}

  _pkg_ident_of_hart() {
      declare full_path_to_hart="${1}"
      local full_path_of_embedded_IDENT=$(tail -n +6 "${full_path_to_hart}" | xzcat | tar --include="*\/IDENT$" -tf -)
      tail -n +6 "${full_path_to_hart}" | xzcat | tar -xOf - "${full_path_of_embedded_IDENT}"
  }

  _get_target_from_hart() {
      declare full_path_to_hart="${1}"
      local full_path_of_embedded_TARGET=$(tail -n +6 "${full_path_to_hart}"  | xzcat | tar --include="*\/TARGET$" -tf -)
      tail -n +6 "${full_path_to_hart}" | xzcat | tar -xOf - "${full_path_of_embedded_TARGET}"
  }

bucket="${HAB_ON_PREM_BOOTSTRAP_BUCKET_NAME:-habitat-on-prem-builder-bootstrap}"
s3_root_url="${HAB_ON_PREM_BOOTSTRAP_S3_ROOT_URL:-https://s3-us-west-2.amazonaws.com}/$bucket"
marker="LATEST.tar.gz"
declare -a packages

case "${1:-}" in
  create-archive)
    check_root
    install_tools git curl jq xzcat

    if [ -z "${HAB_ON_PREM_BOOTSTRAP_NO_UPLOAD:-}" ]; then
      install_tools aws
      check_vars AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
    fi

    populate_dirs

    for p in "${packages[@]}"
    do
      IFS='~' read -ra parts <<< "$p"
      pkg_name=${parts[0]}
      plan_name=${parts[1]}
      pkg_count=$((pkg_count+1))

      if [ "$plan_name" == "plan.sh" ]; then
        targets=("x86_64-linux" "x86_64-linux-kernel2")
      elif [ "$plan_name" == "plan.ps1" ]; then
        targets=("x86_64-windows")
      else
        echo "Unsupported plan: $plan_name"
        exit 1
      fi

      for target in "${targets[@]}"
      do
        echo
        echo "[$pkg_count/$pkg_total] Resolving latest stable version of core/$pkg_name for $target"

        raw_ident=$(latest_ident "$pkg_name" "$target")

        if [ "$raw_ident" = "" ]; then
          echo "Failed to find a latest version. Skipping."
          continue
        fi

        if [ "$raw_ident" = "-1" ]; then
          echo "Failed to parse the response for $pkg_name. Skipping."
          continue
        fi

        slash_ident=$(${JQ_CMD} '"\(.origin)/\(.name)/\(.version)/\(.release)"' <<< "$raw_ident" | tr -d '"')

        # check to see if we have this file before fetching it again
        local_file="$tmp_dir/harts/$(tr '/' '-' <<< "$slash_ident")-$target.hart"

        if download_hart_if_missing "$local_file" "$slash_ident" "[$pkg_count/$pkg_total]" "$target"; then
          # now extract the tdeps and download those too
          local_tar=$(basename "$local_file" .hart).tar
          tail -n +6 "$local_file" | unxz > "$local_tar"

          if tar tf "$local_tar" --no-anchored TDEPS > /dev/null 2>&1; then
            tdeps=$(tail -n +6 "$local_file" | ${XZCAT_CMD} | tar xfO - --no-anchored TDEPS)
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
              # Windows TDEPs will have carriage returns, which we need to remove
              dep_fixed=`echo $dep | sed 's/\\r//g'`
              dep_count=$((dep_count+1))
              file_to_check="$tmp_dir/harts/$(tr '/' '-' <<< "$dep_fixed")-$target.hart"
              download_hart_if_missing "$file_to_check" "$dep_fixed" "[$pkg_count/$pkg_total] [$dep_count/$dep_total]" "$target" || true
            done
          else
            echo "[$pkg_count/$pkg_total] $slash_ident has no TDEPS file. Skipping processing of dependencies."
          fi
        fi
      done
    done

    # done downloading stuff. let's package it up.
    cd /tmp
    tar zcvf "$tar_file" -C "$tmp_dir" .

    upload_archive "$tar_file"

    ;;

  sync-packages)
    if [ -z "${2:-}" ]; then
      usage
    fi

    depot_url=$2
    check_root
    install_tools git curl jq b2sum
    check_vars HAB_AUTH_TOKEN
    populate_dirs
    read_base_plans
    read_hab_plans
    upload_keys

    for p in "${packages[@]}"
    do
      IFS='~' read -ra parts <<< "$p"
      pkg_name=${parts[0]}
      plan_name=${parts[1]}
      pkg_count=$((pkg_count+1))

      if [ "${3:-}" == "base-plans" ]; then
        if ! [[ " ${base_plans[@]} " =~ " ${pkg_name} " ]] &&  ! [[ " ${hab_plans[@]} " =~ " ${pkg_name} " ]]; then
          echo "[$pkg_count/$pkg_total] ${pkg_name} is not a base plan. Skipping."
          continue
        fi
      fi

      if [ "$plan_name" == "plan.sh" ]; then
        targets=("x86_64-linux" "x86_64-linux-kernel2")
      elif [ "$plan_name" == "plan.ps1" ]; then
        targets=("x86_64-windows")
      else
        echo "Unsupported plan: $plan_name"
        exit 1
      fi

      for target in "${targets[@]}"
      do
        echo
        echo "[$pkg_count/$pkg_total] Checking upstream version of core/$pkg_name for $target"

        raw_ident=$(latest_ident "$pkg_name" "$target")

        if [ "$raw_ident" = "" ]; then
          echo "[$pkg_count/$pkg_total] Failed to find a latest stable version on upstream. Skipping."
          continue
        fi

        if [ "$raw_ident" = "-1" ]; then
          echo "[$pkg_count/$pkg_total] Failed to parse the response for $pkg_name. Skipping."
          continue
        fi

        slash_ident=$(${JQ_CMD} '"\(.origin)/\(.name)/\(.version)/\(.release)"' <<< "$raw_ident" | tr -d '"')

        # get the latest version in the local depot
        echo "[$pkg_count/$pkg_total] Checking local version of core/$pkg_name for $target"
        latest_local=$($CURL_CMD -s -H "Accept: application/json" "${depot_url}/v1/depot/channels/core/stable/pkgs/$pkg_name/latest?target=$target")
        raw_ident_local=$(echo "$latest_local" | ${JQ_CMD} ".ident")
        if [ "$raw_ident_local" != "" ]; then
          slash_ident_local=$(${JQ_CMD} '"\(.origin)/\(.name)/\(.version)/\(.release)"' <<< "$raw_ident_local" | tr -d '"')
          release=$(echo ${raw_ident} | ${JQ_CMD} -r '.release')
          release_local=$(echo ${raw_ident_local} | ${JQ_CMD} -r '.release')

          if (( "$release" <= "$release_local" )); then
            echo "[$pkg_count/$pkg_total] Upstream has an older or equal release timestamp. Skipping."
            continue
          fi
        fi

        # check to see if we have this file before fetching it again
        local_file="$tmp_dir/harts/$(tr '/' '-' <<< "$slash_ident")-$target.hart"

        if download_hart_if_missing "$local_file" "$slash_ident" "[$pkg_count/$pkg_total]" "$target"; then
          echo "[$pkg_count/$pkg_total] Uploading ${slash_ident} to local depot"

          # first, upload the package to 'unstable' channel
          hab pkg upload "${local_file}" --url "${depot_url}" --channel unstable --auth "${HAB_AUTH_TOKEN}" 

          # then, promote the package to 'stable'.  Why? 
          # Because doing an all-in-one upload/promotion fails for many packages hab assumes 
          # every package is linux x86_64-linux.  Windows and kernel2 packages fail to promote
          # unless the $target is specified on promotion
          hab pkg promote "${slash_ident}" 'stable' "${target}"
        fi
      done
    done
    ;;

  populate-depot)
    if [ -z "${2:-}" ]; then
      usage
    fi

    depot_url=$2
    check_root
    install_tools curl
    check_vars HAB_AUTH_TOKEN

    tmp_dir=$(mktemp -d)

    if [ -f "${3:-}" ]; then
      echo "Skipping S3 download and using existing file $3 instead."
      cp "$3" "$tmp_dir/$marker"
      cd "$tmp_dir"
    else
      echo "Fetching latest package bootstrap file."
      cd "$tmp_dir"
      download_latest_archive
    fi

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
      hab origin key import < "$key"
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
      hab pkg upload --url "$depot_url" --channel unstable "$hart" --auth "${HAB_AUTH_TOKEN}"
      hab pkg promote "$(_pkg_ident_of_hart ${hart})" 'stable' "$(_target_of_hart ${hart})"
    done

    echo "Package uploads finished."

    ;;
  download-archive)
    download_latest_archive
    ;;
  upload-archive)
    if [ -z "${2:-}" ]; then
      usage
    fi

    upload_archive "$2"
    ;;
  *)
    usage
esac
