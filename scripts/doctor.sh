#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0
SKIP_DOCKER=0

for arg in "$@"; do
  case "$arg" in
    --skip-docker) SKIP_DOCKER=1 ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

load_env() {
  local file="$1" line key value
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"
    value="${value%$'\r'}"
    if [[ "$value" =~ ^\"(.*)\"$ || "$value" =~ ^\'(.*)\'$ ]]; then
      value="${BASH_REMATCH[1]}"
    fi
    [[ -n "${!key:-}" ]] || export "$key=$value"
  done < "$file"
}

load_env "$ROOT/.env"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-web}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-123456}"
REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
REDIS_PORT="${REDIS_PORT:-6379}"

result() {
  printf '%-18s %-5s %s\n' "$1" "$2" "$3"
  [[ "$2" == "FAIL" ]] && FAILURES=$((FAILURES + 1))
  return 0
}

[[ "$DB_PORT" =~ ^[0-9]+$ && "$DB_PORT" -ge 1 && "$DB_PORT" -le 65535 ]] || result config-DB_PORT FAIL "DB_PORT must be between 1 and 65535"
[[ "$REDIS_PORT" =~ ^[0-9]+$ && "$REDIS_PORT" -ge 1 && "$REDIS_PORT" -le 65535 ]] || result config-REDIS_PORT FAIL "REDIS_PORT must be between 1 and 65535"
[[ "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || result config-DB_NAME FAIL "DB_NAME may contain only letters, numbers, and underscores"
[[ "$DB_USER" =~ ^[A-Za-z0-9_]+$ ]] || result config-DB_USER FAIL "DB_USER may contain only letters, numbers, and underscores"

for file in DEPLOYMENT.md back/pom.xml back/mvnw back/sql/init_db.sql frontend/package.json frontend-admin/package.json docker-compose.yml .env.example scripts/deploy.sh scripts/init-local-db.sh; do
  if [[ -f "$ROOT/$file" ]]; then
    result "$file" PASS "present"
  else
    result "$file" FAIL "missing"
  fi
done

if command -v java >/dev/null 2>&1; then
  JAVA_VERSION="$(java -version 2>&1 | head -n 1)"
  if [[ "$JAVA_VERSION" =~ \"17([.\"]|$) ]]; then result java PASS "$JAVA_VERSION"; else result java FAIL "$JAVA_VERSION"; fi
else
  result java FAIL "JDK 17 was not found in PATH"
fi

if command -v node >/dev/null 2>&1; then
  NODE_VERSION="$(node --version | sed 's/^v//')"
  NODE_MAJOR="${NODE_VERSION%%.*}"
  NODE_MINOR="${NODE_VERSION#*.}"; NODE_MINOR="${NODE_MINOR%%.*}"
  if { [[ "$NODE_MAJOR" == "20" && "$NODE_MINOR" -ge 19 ]] || [[ "$NODE_MAJOR" == "22" && "$NODE_MINOR" -ge 12 ]] || [[ "$NODE_MAJOR" -gt 22 ]]; }; then
    result node PASS "v$NODE_VERSION"
  else
    result node FAIL "v$NODE_VERSION; need ^20.19.0 or >=22.12.0"
  fi
else
  result node FAIL "not found"
fi

command -v npm >/dev/null 2>&1 && result npm PASS "$(command -v npm)" || result npm FAIL "not found"

tcp_open() {
  local host="$1" port="$2" probe_pid timer_pid status
  if command -v nc >/dev/null 2>&1; then
    nc -z -w 2 "$host" "$port" >/dev/null 2>&1
    return
  fi

  (exec 3<>"/dev/tcp/$host/$port") >/dev/null 2>&1 &
  probe_pid=$!
  (sleep 3; kill "$probe_pid" 2>/dev/null) &
  timer_pid=$!
  wait "$probe_pid"
  status=$?
  kill "$timer_pid" 2>/dev/null || true
  wait "$timer_pid" 2>/dev/null || true
  return "$status"
}

if [[ "$SKIP_DOCKER" == "1" ]]; then
  result docker INFO "skipped by --skip-docker"
  if [[ "$DB_PORT" =~ ^[0-9]+$ ]] && tcp_open "$DB_HOST" "$DB_PORT"; then
    result mysql-tcp PASS "$DB_HOST:$DB_PORT reachable"
    if command -v mysql >/dev/null 2>&1; then
      MYSQL_PWD="$DB_PASSWORD" mysql --protocol=TCP -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -Nse "SELECT 1" >/dev/null 2>&1 \
        && result mysql-protocol PASS "connection and credentials accepted" \
        || result mysql-protocol FAIL "connection or credentials rejected"
    else
      result mysql-client WARN "mysql CLI not found; protocol and credentials were not checked"
    fi
  else
    result mysql-tcp FAIL "$DB_HOST:$DB_PORT not reachable"
  fi
  if [[ "$REDIS_PORT" =~ ^[0-9]+$ ]] && tcp_open "$REDIS_HOST" "$REDIS_PORT"; then
    result redis-tcp PASS "$REDIS_HOST:$REDIS_PORT reachable"
    if command -v redis-cli >/dev/null 2>&1; then
      [[ "$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" --raw ping 2>/dev/null)" == "PONG" ]] \
        && result redis-protocol PASS "PING returned PONG" \
        || result redis-protocol FAIL "PING did not return PONG"
    else
      result redis-client WARN "redis-cli not found; protocol was not checked"
    fi
  else
    result redis-tcp FAIL "$REDIS_HOST:$REDIS_PORT not reachable"
  fi
elif command -v docker >/dev/null 2>&1; then
  result docker-cli PASS "$(command -v docker)"
  docker info >/dev/null 2>&1 && result docker-daemon PASS "reachable" || result docker-daemon FAIL "not reachable"
  (cd "$ROOT" && docker compose config --quiet >/dev/null 2>&1) && result compose-config PASS "valid" || result compose-config FAIL "invalid"
else
  result docker-cli FAIL "not found"
fi

if [[ -f "$ROOT/.env" ]]; then result .env INFO "present; values not printed"; else result .env INFO "absent; local defaults will be used"; fi

exit "$FAILURES"
