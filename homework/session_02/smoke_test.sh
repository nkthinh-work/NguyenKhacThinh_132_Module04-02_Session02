#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${BASE_URL:-http://localhost:8081}"
command -v curl >/dev/null || { echo 'curl is required' >&2; exit 1; }
printf '== Actuator health ==\n'
health=$(curl -fsS --max-time 10 "$BASE_URL/actuator/health")
printf '%s\n' "$health"
if [[ "$health" != *'"status":"UP"'* ]]; then
  echo 'Health is not UP; verify database connection.' >&2
  exit 1
fi
printf '\n== PostgreSQL JDBC info ==\n'
curl -fsS --max-time 10 "$BASE_URL/api/v1/users/db-info"
printf '\nSmoke test passed.\n'
