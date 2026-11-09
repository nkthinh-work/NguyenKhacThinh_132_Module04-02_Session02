#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

printf 'Checking Bash syntax...\n'
while IFS= read -r -d '' file; do
    bash -n "$file"
    printf 'OK: %s\n' "$file"
done < <(find homework tests -type f -name '*.sh' -print0)
sh -n user-service/gradlew
sh -n publish_github.sh

# Mock Docker and ss to verify staging script fails fast on occupied port.
printf '\nTesting port-occupied fail-fast with mock executables...\n'
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_DOCKER_CALLS"
if [[ "$1" == container && "$2" == inspect ]]; then exit 1; fi
exit 0
EOF
cat > "$TMP/ss" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'LISTEN 0 128 0.0.0.0:5432 0.0.0.0:*'
EOF
chmod +x "$TMP/docker" "$TMP/ss"
export MOCK_DOCKER_CALLS="$TMP/calls"
if PATH="$TMP:$PATH" bash homework/session_02/exercise_06/init-staging.sh >"$TMP/stdout" 2>"$TMP/stderr"; then
    echo 'FAIL: staging script should refuse occupied port' >&2
    exit 1
fi
if [[ -f "$TMP/calls" ]] && grep -q '^run ' "$TMP/calls"; then
    echo 'FAIL: docker run executed despite occupied port' >&2
    exit 1
fi
grep -q 'Port 5432 is in use' "$TMP/stderr"
printf 'PASS: occupied port rejected before docker run.\n'

# Check that readiness retries and success branch run in the documented order.
cat > "$TMP/ss" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$TMP/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_DOCKER_CALLS"
case "$1 $2" in
  'container inspect') exit 1 ;;
  'run -d') echo 'mock-container-id'; exit 0 ;;
  'exec quickbite-db')
    count=$(cat "$MOCK_READY_COUNTER" 2>/dev/null || printf '0')
    count=$((count + 1))
    printf '%s' "$count" > "$MOCK_READY_COUNTER"
    if [[ "$count" -ge 3 ]]; then exit 0; else exit 1; fi
    ;;
  'ps --filter') echo 'quickbite-db Up 5432:5432'; exit 0 ;;
esac
exit 0
EOF
cat > "$TMP/sleep" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == 5 ]]
EOF
chmod +x "$TMP/docker" "$TMP/ss" "$TMP/sleep"
export MOCK_READY_COUNTER="$TMP/ready_counter"
: > "$TMP/calls"
PATH="$TMP:$PATH" bash homework/session_02/exercise_06/init-staging.sh >"$TMP/success_out" 2>"$TMP/success_err"
grep -q 'DATABASE STAGING KHỞI TẠO THÀNH CÔNG!' "$TMP/success_out"
[[ "$(cat "$MOCK_READY_COUNTER")" == 3 ]]
[[ "$(grep -c '^run ' "$TMP/calls")" == 1 ]]
printf 'PASS: staging success branch polls readiness and reports green success.\n'

printf '\nStatic tests passed; integration requires a real Docker daemon and Gradle dependencies.\n' 
