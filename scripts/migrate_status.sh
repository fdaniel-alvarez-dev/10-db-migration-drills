#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
migrations_dir="${repo_root}/migrations"

primary_id="$(docker compose ps -q postgres-primary)"
if [[ -z "${primary_id}" ]]; then
  echo "Service 'postgres-primary' is not running. Start the lab first: make up"
  exit 1
fi

echo "Applied migrations:"
docker exec -i "${primary_id}" psql -U app -d appdb -v ON_ERROR_STOP=1 -c \
  "create table if not exists public.schema_migrations (id text primary key, applied_at timestamptz not null default now());"
docker exec -i "${primary_id}" psql -U app -d appdb -v ON_ERROR_STOP=1 -c \
  "select id, applied_at from public.schema_migrations order by id;"

echo
echo "Pending migrations:"
shopt -s nullglob
up_files=("${migrations_dir}"/*.up.sql)
shopt -u nullglob
IFS=$'\n' sorted=($(printf "%s\n" "${up_files[@]}" | sort))
unset IFS

for file in "${sorted[@]}"; do
  base="$(basename -- "${file}")"
  id="${base%.up.sql}"
  applied="$(
    docker exec -i "${primary_id}" psql -U app -d appdb -tA -v ON_ERROR_STOP=1 -c \
      "select 1 from public.schema_migrations where id='${id}' limit 1;"
  )"
  if [[ "${applied}" != "1" ]]; then
    echo "- ${id}"
  fi
done

