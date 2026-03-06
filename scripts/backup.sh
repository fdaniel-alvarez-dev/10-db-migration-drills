#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${repo_root}/artifacts/backups"
ts="$(date -u +%Y%m%dT%H%M%SZ)"
out="${repo_root}/artifacts/backups/appdb-${ts}.sql"

echo "Creating logical backup to ${out}..."
primary_id="$(docker compose ps -q postgres-primary)"
if [[ -z "${primary_id}" ]]; then
  echo "Service 'postgres-primary' is not running. Start the lab first: make up"
  exit 1
fi

docker exec -i "${primary_id}" pg_dump -U app -d appdb > "${out}"

echo "Backup created."
