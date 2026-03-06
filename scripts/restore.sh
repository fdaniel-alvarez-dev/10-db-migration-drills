#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

latest="$(ls -1t "${repo_root}"/artifacts/backups/*.sql 2>/dev/null | head -n 1 || true)"
if [[ -z "${latest}" ]]; then
  echo "No backups found under artifacts/backups/. Run: make backup"
  exit 1
fi

echo "Restoring latest backup: ${latest}"
primary_id="$(docker compose ps -q postgres-primary)"
if [[ -z "${primary_id}" ]]; then
  echo "Service 'postgres-primary' is not running. Start the lab first: make up"
  exit 1
fi

docker exec -i "${primary_id}" psql -U app -d appdb -c "drop schema public cascade; create schema public;"
docker exec -i "${primary_id}" psql -U app -d appdb < "${latest}"
echo "Restore complete."
