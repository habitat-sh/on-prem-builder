#!/usr/bin/env bash

declare -a deps
this_script=$0
deps=('core/aws-cli' 'core/bc' 'core/coreutils')
requirements_check_failure=false
bucket_contents_file=${BUCKET_CONTENTS_FILE:-${PWD}/minio-update-bldr-bucket-objects.txt}
waypoint=${WAYPOINT:-$PWD/minio-update-bldr-bucket-objects}
declare -a opts

################################################################################
# Ancillary Functions
################################################################################

function _sudo () {
  [[ $EUID = 0 ]] || set -- command sudo -E "$@"
  "$@"
}

function _hab_exec () {
  pkg=$1; shift
  _sudo hab pkg exec $pkg -- "$@"
}

function _hab_install () {
  pkg=$1; shift
  echo ""
  echo "$pkg not installed, installing"
  if _sudo hab pkg install $pkg -- "$@"; then
    echo "$pkg install succeeded"
  else
    requirements_check_failure=true
    echo "$pkg install failed"
  fi
  echo ""
}

function aws () {
  _hab_exec 'core/aws-cli' aws $@
}

function tr() {
  _hab_exec 'core/coreutils' tr $@
}

function bc() {
  _hab_exec 'core/bc' bc $@
}

function df() {
  _hab_exec 'core/coreutils' df $@
}

function _is_hab_installed () {
  if ! command -v hab &> /dev/null; then
    echo "Please ensure that the hab binary is installed and on your path."
    echo "More information at https://docs.chef.io/habitat/install_habitat/"
    echo ""
    requirements_check_failure=true
  fi
}

function _are_dependencies_installed () {
  for x in "${deps[@]}"; do
    if ! hab pkg env $x &> /dev/null; then
      _hab_install $x
    fi
  done
}

function _prerequisites_check () {
  echo ""
  echo "-- CHECKING dependecies"
  _is_hab_installed
  $requirements_check_failure && exit || echo "The hab binary is installed"
  _are_dependencies_installed
  $requirements_check_failure && exit || echo "All dependencies are installed"
}

################################################################################
# "Private" Functions
################################################################################

function _cfg_environ () {

  source "../bldr.env"
  s3_url="s3://$MINIO_BUCKET"

  export AWS_ACCESS_KEY_ID=$MINIO_ACCESS_KEY
  export AWS_SECRET_ACCESS_KEY=$MINIO_SECRET_KEY
  declare -a src_opts
  src_opts+=( "--endpoint-url $MINIO_ENDPOINT" )
  opts=("${src_opts[@]}")
}

function _local_storage_check () {
  echo ""
  echo "-- CHECKING local storage space"
  # grab the amount of space used by objects in the bucket
  local space=$(aws ${opts[*]} s3 ls $s3_url --recursive --human-readable --summarize | grep 'Total Size:' | sed 's/.\+:\s\+//')
  x=$(tr -d -C 0-9. <<< "$space") # extract the numeric value without units
  local buffered_space_requirement=$(bc <<< "$x * 1.05") # multiply by 1.05 for a 5% increase
  local buffer="${y} ${space##* }" # add the units back on to the 5% increase
  echo "At least $space of disk space is required."
  echo "We recommend $buffered_space_requirement to allow for a small buffer"

  shopt -s extglob
  local space=$(df --human-readable --total | grep '^total' | awk '{print $4}')
  local number=${space/[[:alpha:]]/}
  local suffix=${space/+([[:digit:]])?([.])*([[:digit:]])/}iB
  echo "This system appears to have $number $suffix space available"
  if [[ $(bc <<< "$buffered_space_requirement < $number") == 1 ]]; then
    echo "You have sufficient space available"
  else
    echo "You do not have sufficient space available"
  fi
}

function _minio_check {
  echo ""
  echo "-- CHECKING MinIO"
  if [[ $(curl -s -w "%{http_code}" "$MINIO_ENDPOINT/minio/health/live") == 200 ]]; then
    echo "MinIO appears to be up and running"
  else
    echo "MinIO doesn't seem to be accessible at $MINIO_ENDPOINT"
    exit
  fi
  local output=$(aws ${opts[*]} s3 ls)
  if [[ $output =~ $MINIO_BUCKET ]]; then
    echo "MinIO credentials valid"
  else
    echo "MinIO credentials invalid"
    exit
  fi

}

function _print_var {
  echo "$1=${!1}"
}

################################################################################
# "command" functions
################################################################################

function usage () {
  cat <<- USAGE

	  usage:
	    This documentation

	  print_env:
	    Print environment variables of consequence from bldr.env

	  preflight_checks:
	    Checks to ensure proper functioning

	  download:
	    Download objects from the MinIO bucket to the local filesystem

	  upgrade:
	    Upgrade from on-prem-stable channel to bldr-2620307099961720832

	  downgrade:
	    Upgrade from bldr-2620307099961720832 to on-prem-stable channel

	USAGE
}

function print_env() {
  echo ""
  echo "ENVIROMENT VARIABLES of Consequence"
  echo ""
  echo "-- FROM env.bldr"
  _print_var "MINIO_ENDPOINT"
  _print_var "MINIO_BUCKET"
  _print_var "MINIO_ACCESS_KEY"
  _print_var "MINIO_SECRET_KEY"
  _print_var "BLDR_MINIO_CHANNEL"
  echo ""
  echo "-- FROM this script ($this_script)"
  _print_var "waypoint"
  echo "  export WAYPOINT to change"
  _print_var "bucket_contents_file"
  echo "  export BUCKET_CONTENTS_FILE to change"
  echo ""
}

function _enumerate_bucket_objects () {
  aws ${opts[*]} s3 ls $s3_url \
    --recursive --human-readable --summarize \
    > $bucket_contents_file
  echo ""
  echo "A list of the bucket contents was written to ${bucket_contents_file#$PWD/}"
  echo "Review this file to ensure that what will be downloaded is what you expect"
}

function review_local_storage_needs () {
  echo "-- REVIEWING local storage needs"
  _report_space_needed
  _report_space_available
}

function _ensure_bucket_exists () {
  if ! aws ${opts[*]} s3 ls $MINIO_BUCKET &> /dev/null; then
    aws ${opts[*]} s3 mb $s3_url
  fi
}

function upload_bucket_objects () {
  _ensure_bucket_exists
  aws ${opts[*]} s3 sync $waypoint $s3_url
}

function minio_migration_rollback () {
    sudo cp -a /hab/svc/builder-minio/data-bkp/. /hab/svc/builder-minio/data/
    sudo hab svc load "${BLDR_ORIGIN}/builder-minio" --channel "stable" --force
}

function preflight_checks () {
  _prerequisites_check
  _minio_check
  _local_storage_check
  _enumerate_bucket_objects
  echo ""
}

function download_bucket_objects () {
  aws ${opts[*]} s3 sync $s3_url $waypoint
}

function upgrade_minio () {
  echo UPGRADING
  export HAB_LICENSE=accept
  if [[ "$BLDR_MINIO_CHANNEL" != "bldr-2620307099961720832" ]]; then
    echo "you must export BLDR_MINIO_CHANNEL='bldr-2620307099961720832' in bldr.env"
    exit
  fi
  pushd .. > /dev/null
  sudo ./uninstall.sh
  sudo sh -c "find /hab/svc/builder-minio/data/ -maxdepth 1 -mindepth 1 -type d | xargs rm -rf"
  sudo ./install.sh
  popd > /dev/null
  upload_bucket_objects
}

function downgrade_minio () {
  export HAB_LICENSE=accept
  if [[ "$BLDR_MINIO_CHANNEL" != "on-prem-stable" ]]; then
    echo "you must export BLDR_MINIO_CHANNEL='on-prem-stable' in bldr.env"
    exit
  fi
  echo DOWNGRADING
  pushd .. > /dev/null
  sudo -E ./uninstall.sh
  sudo sh -c "find /hab/svc/builder-minio/data/ -maxdepth 1 -mindepth 1 -type d | xargs rm -rf"
  sudo -E ./install.sh
  popd > /dev/null
  upload_bucket_objects
}

################################################################################
# "main function"
################################################################################

_cfg_environ

case "${1}" in
  usage ) usage ;;
  print_env ) print_env ;;
  preflight_checks ) preflight_checks ;;
  download ) download_bucket_objects ;;
  upgrade ) upgrade_minio ;;
  downgrade ) downgrade_minio ;;
  upload ) upload_bucket_objects ;;
  minio_rollback ) minio_migration_rollback ;;
  * ) usage ;;
esac

