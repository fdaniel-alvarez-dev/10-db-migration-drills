#!/usr/bin/env bash
set -euo pipefail

echo "Checking replication status on primary..."
primary_id="$(docker compose ps -q postgres-primary)"
replica_id="$(docker compose ps -q postgres-replica)"
if [[ -z "${primary_id}" || -z "${replica_id}" ]]; then
  echo "Services are not running. Start the lab first: make up"
  exit 1
fi

docker exec -i "${primary_id}" psql -U app -d appdb -c "select application_name, state, sync_state, write_lag, flush_lag, replay_lag from pg_stat_replication;"

echo
echo "Checking replica is in recovery mode..."
docker exec -i "${replica_id}" psql -U app -d appdb -c "select pg_is_in_recovery();"
