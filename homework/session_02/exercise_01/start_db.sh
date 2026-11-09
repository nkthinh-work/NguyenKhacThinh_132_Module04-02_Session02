#!/usr/bin/env bash
set -euo pipefail
NAME='quickbite-db'
if docker container inspect "$NAME" >/dev/null 2>&1; then
    echo "Container $NAME already exists; starting it if stopped."
    echo 'NOTE: existing PostgreSQL password remains unchanged.'
    if [[ "$(docker inspect -f '{{.State.Running}}' "$NAME")" != 'true' ]]; then
        docker start "$NAME"
    fi
else
    docker run -d --name "$NAME" -p 5432:5432 \
      -e POSTGRES_PASSWORD=12345678 postgres:15-alpine
fi
printf '\n== docker ps ==\n'
docker ps --filter "name=^/${NAME}$"
printf '\n== docker images ==\n'
docker images postgres:15-alpine
printf '\nCapture: homework/session_02/exercise_01/db_status.png\n'
