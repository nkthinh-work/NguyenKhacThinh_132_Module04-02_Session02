#!/usr/bin/env bash
set -euo pipefail
printf 'Following quickbite-db logs. Use Ctrl+C to stop viewing.\n'
exec docker logs -f quickbite-db
