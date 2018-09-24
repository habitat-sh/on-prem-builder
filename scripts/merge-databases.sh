#!/bin/bash
# The purpose of this script is a one time data migration from
# builder_originsrv, builder_sessionsrv and builder_jobsrv -> builder

set -euo pipefail

usage() {
  echo "Usage: merge-databases.sh"
  exit 1
}

if [ -z "${PGPASSWORD:-}" ]; then
  echo "Please ensure that PGPASSWORD is exported in your environment and run this script again."
  exit 1
fi

echo "This script will take all of the data that's currently in builder_originsrv and builder_sessionsrv"
echo "and merge them into a brand new database called builder."
echo "Please ensure that you have completed a full database backup before running this script."
echo

read -rp "Do you want to proceed? [y/n] " answer
clean_answer=$(echo "$answer" | xargs | tr '[:upper:]' '[:lower:]')

if [ "${clean_answer::1}" != "y" ]; then
  echo "Aborting"
  exit 1
fi

execute_sql() {
  local database="$1"
  local sql="$2"
  local port=${PORT:-5432}

  hab pkg exec core/postgresql psql -t -U hab -h 127.0.0.1 -p "${port}" -c "${sql}" -d "${database}" -X
}

# before we do anything, let's check to see if this has already been done
echo "Checking to see if the shard migration has already happened"
if ! execute_sql "builder_originsrv" "SELECT shard_migration_complete FROM flags;" | grep -q 't'; then
echo "The flags table is not present in the database, which is required for this script to run."
echo "It's possible something is amiss with your Builder database migrations."
exit 1
fi

# before we do anything part 2, let's check to see if this has already been done
echo "Checking to see if the db migration has already happened"
if [ "$(execute_sql "builder" "SELECT count(*) from origins;")" -gt 0 ]; then
echo "Looks like the db migration has already happened"
echo "It's possible something is amiss with your Builder database migrations."
exit 1
fi

# before we do anything part 3, let's check to see if anyone has logged in mid-migration
echo "Checking to see if the db migration has already happened"
if [ "$(execute_sql "builder" "SELECT count(*) from accounts;")" -gt 0 ]; then
echo "Looks like the db migration has already happened"
echo "It's possible somebody logged in mid-migration."
echo "If this is the case, stop all builder services, delete the builder database, recreate it, start all services and retry this script."
exit 1
fi


# This is a bit of a special case since we deleted a column
execute_sql builder_originsrv "\\copy origins (id, name, owner_id, created_at, updated_at, default_package_visibility) to stdout" | \
    execute_sql builder "\\copy origins from stdin"

execute_sql builder_originsrv "\\copy origin_invitations (id, origin_id, origin_name, account_id, account_name, owner_id, ignored, created_at, updated_at) to stdout" | \
    execute_sql builder "\\copy origin_invitations from stdin"

# Order matters in these lists
sessionsrv_tables=(accounts account_tokens)
originsrv_tables=(
    audit_package audit_package_group origin_channels origin_integrations
    origin_members origin_packages origin_channel_packages origin_private_encryption_keys
    origin_projects origin_project_integrations origin_public_encryption_keys origin_public_keys
    origin_secret_keys origin_secrets
)


for table in "${sessionsrv_tables[@]}"; do
    echo "Copying ${table} from builder_sessionsrv to builder"
    execute_sql builder_sessionsrv "\\copy ${table} to stdout" | execute_sql builder "\\copy ${table} from stdin"
done

for table in "${originsrv_tables[@]}"; do
    echo "Copying ${table} from builder_originsrv to builder"
    if [ "${table}" == "origin_packages" ]; then
        execute_sql builder_originsrv "\\copy ${table} to stdout" | \
        execute_sql builder "\\copy ${table} (id, origin_id, owner_id, name, ident, checksum, manifest, config, target, deps, tdeps, exposes, scheduler_sync, created_at, updated_at, visibility) from stdin"
    else
        execute_sql builder_originsrv "\\copy ${table} to stdout" | execute_sql builder "\\copy ${table} from stdin"
    fi
done

execute_sql builder "UPDATE origin_packages SET ident_array=regexp_split_to_array(ident, '/');"
