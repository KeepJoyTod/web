#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$ROOT/frontend"
BACKEND_DIR="$ROOT/back"

if [[ ! -d "$BACKEND_DIR" && -d "$ROOT/backend" ]]; then
  BACKEND_DIR="$ROOT/backend"
fi

LOG_DIR="${LOG_DIR:-$ROOT/logs}"
PID_DIR="${PID_DIR:-$ROOT/.pids}"
mkdir -p "$LOG_DIR" "$PID_DIR"

is_running() {
  local pid="$1"
  [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1
}

port_listening() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi
  return 1
}

run_bg() {
  local name="$1"
  local workdir="$2"
  local logfile="$LOG_DIR/${name}.log"
  local pidfile="$PID_DIR/${name}.pid"
  shift 2

  if [[ -f "$pidfile" ]]; then
    local old_pid
    old_pid="$(cat "$pidfile" 2>/dev/null || true)"
    if is_running "$old_pid"; then
      echo "$name already running (pid=$old_pid), logs: $logfile"
      return 0
    fi
  fi

  local cmd=""
  for arg in "$@"; do
    cmd+="$(printf '%q ' "$arg")"
  done

  nohup bash -lc "cd $(printf '%q' "$workdir") && exec $cmd" >"$logfile" 2>&1 &

  local pid="$!"
  echo "$pid" >"$pidfile"
  echo "Started $name (pid=$pid), logs: $logfile"
}

start_backend() {
  if [[ ! -f "$BACKEND_DIR/pom.xml" ]]; then
    echo "Backend not found at $BACKEND_DIR"
    return 1
  fi

  if ! command -v mvn >/dev/null 2>&1; then
    echo "mvn not found"
    return 1
  fi

  local backend_port="${BACKEND_PORT:-8080}"
  if port_listening "$backend_port"; then
    echo "Backend port $backend_port already in use, skip backend"
    return 0
  fi

  local db_host="${DB_HOST:-127.0.0.1}"
  local db_port="${DB_PORT:-3307}"
  local db_name="${DB_NAME:-web}"
  local db_user="${DB_USER:-root}"
  local db_pass="${DB_PASS:-123456}"

  local jdbc_url="jdbc:mysql://${db_host}:${db_port}/${db_name}?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false"

  run_bg "backend" "$BACKEND_DIR" env \
    SPRING_DATASOURCE_URL="$jdbc_url" \
    SPRING_DATASOURCE_USERNAME="$db_user" \
    SPRING_DATASOURCE_PASSWORD="$db_pass" \
    mvn spring-boot:run
}

start_frontend() {
  if [[ ! -f "$FRONTEND_DIR/package.json" ]]; then
    echo "Frontend not found at $FRONTEND_DIR"
    return 1
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "npm not found"
    return 1
  fi

  if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    (cd "$FRONTEND_DIR" && npm install)
  fi

  local front_port="${FRONT_PORT:-5173}"
  while port_listening "$front_port"; do
    front_port="$((front_port + 1))"
  done

  FRONTEND_PORT_RESOLVED="$front_port"
  run_bg "frontend" "$FRONTEND_DIR" npm run dev -- --host 0.0.0.0 --port "$front_port"
}

start_backend
start_frontend

echo "Backend:  http://localhost:8080/api"
echo "Frontend: http://localhost:${FRONTEND_PORT_RESOLVED:-5173}/"
