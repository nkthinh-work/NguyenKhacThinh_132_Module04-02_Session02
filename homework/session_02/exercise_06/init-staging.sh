#!/usr/bin/env bash
set -euo pipefail

NAME='quickbite-db'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

fail() {
    printf '%bERROR: %s%b\n' "$RED" "$1" "$NC" >&2
    exit 1
}

printf '%b[1/4] Clean up old staging DB (data may be deleted)%b\n' "$YELLOW" "$NC"
if docker container inspect "$NAME" >/dev/null 2>&1; then
    if [[ "$(docker inspect -f '{{.State.Running}}' "$NAME")" == 'true' ]]; then
        docker stop "$NAME" >/dev/null
    fi
    docker rm "$NAME" >/dev/null
fi
printf 'Clean up completed.\n'

printf '[2/4] Fail-fast port 5432 check...\n'
if command -v ss >/dev/null 2>&1; then
    if [[ -n "$(ss -H -ltn '( sport = :5432 )')" ]]; then
        fail 'Port 5432 is in use. Stop the conflicting local service/container before continuing.'
    fi
elif command -v lsof >/dev/null 2>&1; then
    if lsof -nP -iTCP:5432 -sTCP:LISTEN >/dev/null 2>&1; then
        fail 'Port 5432 is in use. Stop the conflicting service before continuing.'
    fi
else
    # Bash TCP check is best-effort only; docker run remains the definitive port check.
    if (echo >/dev/tcp/127.0.0.1/5432) >/dev/null 2>&1; then
        fail 'Port 5432 is in use on localhost.'
    fi
    printf 'ss/lsof not found, using best-effort IPv4 port check.\n'
fi
printf 'Port 5432 is free.\n'

printf '[3/4] Start PostgreSQL 15-alpine...\n'
if ! docker run -d --name "$NAME" -p 5432:5432 \
    -e POSTGRES_PASSWORD=12345678 postgres:15-alpine; then
    fail 'docker run failed. Review Docker daemon, image or port configuration.'
fi

printf '[4/4] Waiting for PostgreSQL readiness (5 attempts, sleep 5s)...\n'
for attempt in 1 2 3 4 5; do
    sleep 5
    if docker exec "$NAME" pg_isready -U postgres >/dev/null 2>&1; then
        printf '%bDATABASE STAGING KHỞI TẠO THÀNH CÔNG!%b\n' "$GREEN" "$NC"
        printf 'Status: '
        docker ps --filter "name=^/${NAME}$" --format '{{.Names}} {{.Status}} {{.Ports}}'
        exit 0
    fi
    printf 'Waiting... (%d/5)\n' "$attempt"
done

printf '%bDatabase did not become ready. Last 20 log lines:%b\n' "$RED" "$NC" >&2
docker logs --tail 20 "$NAME" >&2 || true
exit 1
