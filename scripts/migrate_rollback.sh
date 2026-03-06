#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
migrations_dir="${repo_root}/migrations"

primary_id="$(docker compose ps -q postgres-primary)"
if [[ -z "${primary_id}" ]]; then
  echo "Service 'postgres-primary' is not running. Start the lab first: make up"
  exit 1
fi

docker exec -i "${primary_id}" psql -U app -d appdb -v ON_ERROR_STOP=1 -c \
  "create table if not exists public.schema_migrations (id text primary key, applied_at timestamptz not null default now());"

last_id="$(
  docker exec -i "${primary_id}" psql -U app -d appdb -tA -v ON_ERROR_STOP=1 -c \
    "select id from public.schema_migrations order by id desc limit 1;"
)"

if [[ -z "${last_id}" ]]; then
  echo "No applied migrations to roll back."
  exit 0
fi

down_file="${migrations_dir}/${last_id}.down.sql"
if [[ ! -f "${down_file}" ]]; then
  echo "No down migration found for ${last_id}: ${down_file}"
  echo "Rollback refused."
  exit 1
fi

echo "ROLLBACK ${last_id}"
docker exec -i "${primary_id}" psql -U app -d appdb -v ON_ERROR_STOP=1 -c "begin;"
docker exec -i "${primary_id}" psql -U app -d appdb -v ON_ERROR_STOP=1 -f "/dev/stdin" < "${down_file}"
docker exec -i "${primary_id}" psql -U app -d appdb -v ON_ERROR_STOP=1 -c \
  "delete from public.schema_migrations where id='${last_id}';"
docker exec -i "${primary_id}" psql -U app -d appdb -v ON_ERROR_STOP=1 -c "commit;"
echo "Rollback complete."

