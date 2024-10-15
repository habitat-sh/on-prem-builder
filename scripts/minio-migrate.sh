set -eou pipefail

CHANNEL="LTS-2024"
install_minio() {
  
  sudo hab pkg install core/minio -c $CHANNEL
  echo "MinIO installation completed."
}

check_and_install_minio() {
  if ! hab pkg path core/minio >/dev/null 2>&1; then
    echo "MinIO is not installed. Installing MinIO..."
    install_minio
  else
    echo "MinIO is already installed."
  fi
}

get_installed_minio_version() {
  installed_version=$(hab pkg path core/minio | cut -d '/' -f6)
  echo "$installed_version"
}

get_latest_minio_version() {
  latest_version=$(curl --silent "https://bldr.habitat.sh/v1/depot/channels/core/$CHANNEL/pkgs/minio/latest" | jq -r '.ident.version')
  if [[ -z "$latest_version" ]]; then
    echo "Failed to fetch the latest MinIO version."
    exit 1
  fi
  echo "$latest_version"
}

compare_versions() {
  local v1=$1
  local v2=$2
  echo "Comparing versions..."
  echo "Installed version: $v1"
  echo "Latest version: $v2"

  if [ "$v1" = "$v2" ]; then
    return 1
  elif [[ "$v1" < "$v2" ]]; then
    echo "Installed version is older."
    return 0
  else
    echo "Installed version is newer or equal."
    return 1
  fi
}

detect_migration() {
  installed_version=$(get_installed_minio_version)
  latest_version=$(get_latest_minio_version)

  compare_versions "$installed_version" "$latest_version"
  compare_result=$?

  if [[ $compare_result -eq 0 ]]; then
    echo "Older version of MinIO detected. Migration required."
    return 0
  elif [[ $compare_result -eq 1 ]]; then
    echo "MinIO is up to date. No migration required."
    return 1
  else
    echo "Unexpected result from version comparison."
    exit 1
  fi
}

check_and_install_minio

installed_version=$(get_installed_minio_version)
echo "Installed MinIO version: $installed_version"

detect_migration
detect_migration_result=$?

case "$detect_migration_result" in
  0)
    echo "Migrating MinIO"
    install_minio
    ;;
  1)
    echo "No migration needed."
    ;;
  *)
    echo "An unexpected error occurred during MinIO version check."
    exit 1
    ;;
esac
