#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:postgresql://localhost:5432/postgres}"
export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-postgres}"
export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-12345678}"
export SERVER_PORT="${SERVER_PORT:-8081}"
cd "$REPO_ROOT/user-service"
printf 'Starting user-service on host; JDBC URL: %s\n' "$SPRING_DATASOURCE_URL"
exec ./gradlew bootRun
