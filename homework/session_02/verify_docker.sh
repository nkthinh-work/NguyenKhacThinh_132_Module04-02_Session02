#!/usr/bin/env bash
set -euo pipefail
printf '== docker --version ==\n'
docker --version
printf '\n== docker info ==\n'
docker info
