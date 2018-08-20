#!/bin/bash
# The purpose of this script is a one time data migration from all of our 128
# schemas into the public schema.

set -euo pipefail

usage() {
  echo "Usage: merge-shards.sh <SERVER> [migrate]"
  echo "Valid servers are: jobsrv, originsrv, sessionsrv"
  exit 1
}

if [ -z "${PGPASSWORD:-}" ]; then
  echo "Please ensure that PGPASSWORD is exported in your environment and run this script again."
  exit 1
fi

echo "This script will take all of the data that's currently spread across 127 shards and consolidate all of that down into the public Postgres schema."
echo "Please ensure that you have completed a full database backup before running this script."
echo

read -rp "Do you want to proceed? [y/n] " answer
clean_answer=$(echo "$answer" | xargs | tr '[:upper:]' '[:lower:]')

if [ "${clean_answer::1}" != "y" ]; then
  echo "Aborting"
  exit 1
fi

execute_sql() {
  local sql="$1"
  local server="$2"

  hab pkg exec core/postgresql psql -t -U hab -h 127.0.0.1 -p 5432 -c "$sql" "builder_$server"
}

process_shards() {
  local upper_bound="$1"
  local server="$2"
  local do_it="$3"
  local flag_record_present="0"

  # before we do anything, let's check to see if this has already been done
  echo "Checking to see if the shard migration has already happened"
  if flag=$(execute_sql "SELECT shard_migration_complete FROM flags;" "$server" | xargs); then
    if [ -n "$flag" ]; then
      flag_record_present="1"
    fi

    if [ "$flag" == "t" ]; then
      echo "This shard migration has already completed. Running it a second time is not supported. Aborting."
      exit 1
    fi
  else
    echo "The flags table is not present in the database, which is required for this script to run."
    echo "It's possible something is amiss with your Builder database migrations."
    exit 1
  fi

  declare -A count_map

  mapfile -t shards < <(seq 0 "$upper_bound")

  for shard in "${shards[@]}"
  do
    current_schema="shard_$shard"
    # ordering by table_name descending gets us the "origins" table first, which is a pre-req for all the other tables due to foreign key constraints
    if [ "$server" == "originsrv" ]; then
      tables="origins origin_secrets origin_secret_keys origin_public_keys origin_public_encryption_keys origin_projects origin_integrations origin_project_integrations origin_private_encryption_keys origin_packages origin_members origin_invitations origin_channels origin_channel_packages audit_package_group audit_package audit"
    else
      tables=$(execute_sql "SELECT table_name FROM information_schema.tables WHERE table_schema='$current_schema' AND table_type='BASE TABLE' ORDER BY table_name DESC;" "$server")
    fi

    echo "current schema = $current_schema"

    for table in $tables
    do
      # migrations will run automatically for the public schema, so we don't need to transfer any data there.
      if [ "$table" == "__diesel_schema_migrations" ] || [ "$table" == "builder_db_migrations" ]; then
        continue
      fi

      count=$(execute_sql "SELECT COUNT(*) FROM $current_schema.$table;" "$server" | xargs)
      echo "Count for $current_schema.$table = $count"

      if [ -z "${count_map[$table]:-}" ]; then
        count_map[$table]="$count"
      else
        new_total=$((count_map["$table"] + count))
        count_map[$table]="$new_total"
      fi

      if [ "$do_it" == "migrate" ]; then
        execute_sql "INSERT INTO public.$table SELECT * FROM $current_schema.$table;" "$server"
      fi
    done
  done

  # double check that our counts are correct
  if [ "$do_it" == "migrate" ]; then
    errors=0
    public_tables=$(execute_sql "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" "$server")
    for table in $public_tables
    do
      if [ "$table" == "__diesel_schema_migrations" ] || [ "$table" == "flags" ]; then
        continue
      fi

      public_count=$(execute_sql "SELECT COUNT(*) FROM public.$table;" "$server" | xargs)

      if [ -z "${count_map[$table]:-}" ]; then
        echo "*** PANIC ***. There is no accumulated record total for the $table table. There should be. The total for the $table table in the public schema is $public_count."
        errors=$((errors+1))
      elif [ "${count_map[$table]}" -ne "$public_count" ]; then
        echo "*** PANIC ***. The accumulated record total for the $table table across all shards is ${count_map[$table]}. That does not match the total record count in the public schema, which is $public_count."
        errors=$((errors+1))
      else
        echo "The accumulated record count for the $table table matches the total record count in the public schema. All good."
      fi
    done

    if [ "$errors" -eq 0 ]; then
      echo "The entire shard migration completed without errors. Updating db flag."

      if [ "$flag_record_present" == "1" ]; then
        execute_sql "UPDATE public.flags SET shard_migration_complete='t', updated_at=now();" "$server"
      else
        execute_sql "INSERT INTO public.flags (shard_migration_complete) VALUES ('t');" "$server"
      fi
    fi
  fi
}

case "${1:-}" in
  jobsrv)
    process_shards 0 "$1" "${2:-}"
    ;;
  originsrv|sessionsrv)
    process_shards 127 "$1" "${2:-}"
    ;;
  *)
    usage
esac
