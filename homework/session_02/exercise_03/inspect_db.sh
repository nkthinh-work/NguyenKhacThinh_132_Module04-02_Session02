#!/usr/bin/env bash
set -euo pipefail
# Equivalent one-command form of docker exec -it -> psql -U postgres -> \l.
# Run this from a terminal for screenshot evidence.
docker exec -it quickbite-db psql -U postgres -c '\l'
printf '\nIf necessary, open an interactive shell: docker exec -it quickbite-db sh\n'
