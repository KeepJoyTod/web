#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$ROOT/frontend"
BACKEND_DIR="$ROOT/backend"
DRYRUN=0

if [[ "${1-}" == "dry-run" ]]; then
  DRYRUN=1
fi

if [[ ! -d "$BACKEND_DIR" && -d "$ROOT/back" ]]; then
  BACKEND_DIR="$ROOT/back"
fi

mkdir -p "$ROOT/logs" "$ROOT/.pids"

run_bg() {
  local name="$1"
  local workdir="$2"
  local logfile="$ROOT/logs/${name}.log"
  local pidfile="$ROOT/.pids/${name}.pid"
  shift 2

  if [[ "$DRYRUN" == "1" ]]; then
    printf '[dry-run] (cd "%s" && %s) > "%s" 2>&1 &\n' "$workdir" "$*" "$logfile"
    return 0
  fi

  (
    cd "$workdir"
    "$@"
  ) >"$logfile" 2>&1 &

  local pid="$!"
  echo "$pid" >"$pidfile"
  echo "Started $name (pid=$pid), logs: $logfile"
}

start_compose() {
  local compose_file="${COMPOSE_FILE-}"

  if [[ -z "$compose_file" ]]; then
    if [[ -f "$ROOT/docker-compose.yml" ]]; then
      compose_file="$ROOT/docker-compose.yml"
    elif [[ -f "$ROOT/compose.yml" ]]; then
      compose_file="$ROOT/compose.yml"
    fi
  fi

  if [[ -z "$compose_file" || ! -f "$compose_file" ]]; then
    echo "No docker-compose.yml, skip database"
    return 0
  fi

  if [[ "$DRYRUN" == "1" ]]; then
    echo "[dry-run] (cd \"$ROOT\" && docker compose -f \"$compose_file\" up -d) || docker-compose -f \"$compose_file\" up -d"
    return 0
  fi

  (
    cd "$ROOT"
    docker compose -f "$compose_file" up -d || docker-compose -f "$compose_file" up -d
  )
}

start_backend() {
  if [[ ! -d "$BACKEND_DIR" ]]; then
    echo "No backend directory, skip backend"
    return 0
  fi

  if [[ -f "$BACKEND_DIR/package.json" ]]; then
    if ! command -v npm >/dev/null 2>&1; then
      echo "npm not found, skip backend (Node)"
      return 0
    fi
    run_bg "backend" "$BACKEND_DIR" bash -lc 'npm run dev || npm start'
    return 0
  fi

  if [[ -f "$BACKEND_DIR/pom.xml" ]]; then
    if ! command -v mvn >/dev/null 2>&1; then
      echo "mvn not found, skip backend (Maven)"
      return 0
    fi
    run_bg "backend" "$BACKEND_DIR" mvn spring-boot:run
    return 0
  fi

  if [[ -f "$BACKEND_DIR/gradlew" ]]; then
    run_bg "backend" "$BACKEND_DIR" bash -lc './gradlew bootRun'
    return 0
  fi

  if [[ -f "$BACKEND_DIR/build.gradle" || -f "$BACKEND_DIR/build.gradle.kts" ]]; then
    if command -v gradle >/dev/null 2>&1; then
      run_bg "backend" "$BACKEND_DIR" gradle bootRun
    else
      echo "gradle not found and no ./gradlew, skip backend (Gradle)"
    fi
    return 0
  fi

  echo "Backend directory exists but no recognized start script"
}

start_frontend() {
  if [[ ! -f "$FRONTEND_DIR/package.json" ]]; then
    echo "No frontend package.json, skip frontend"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "npm not found, skip frontend"
    return 0
  fi

  run_bg "frontend" "$FRONTEND_DIR" npm run dev
}

start_compose
start_backend
start_frontend

exit 0
