#!/usr/bin/env bash
set -euo pipefail

MODE="dev"
NO_INSTALL=0
SKIP_DB=0
INIT_DB=0
SKIP_BUILD=0
DRYRUN=0
DB_NAME="web"
DB_USER="root"
DB_PASSWORD="123456"
MYSQL_CONTAINER="projectku-mysql"

for arg in "$@"; do
  case "$arg" in
    --mode=dev|--mode=prod) MODE="${arg#*=}" ;;
    --no-install) NO_INSTALL=1 ;;
    --skip-db) SKIP_DB=1 ;;
    --init-db) INIT_DB=1 ;;
    --skip-build) SKIP_BUILD=1 ;;
    --dry-run) DRYRUN=1 ;;
    --db-name=*) DB_NAME="${arg#*=}" ;;
    --db-user=*) DB_USER="${arg#*=}" ;;
    --db-password=*) DB_PASSWORD="${arg#*=}" ;;
    --mysql-container=*) MYSQL_CONTAINER="${arg#*=}" ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT/frontend"
BACKEND_DIR="$ROOT/back"
if [[ ! -d "$BACKEND_DIR" && -d "$ROOT/backend" ]]; then
  BACKEND_DIR="$ROOT/backend"
fi
LOGS_DIR="$ROOT/logs"
PIDS_DIR="$ROOT/.pids"
mkdir -p "$LOGS_DIR" "$PIDS_DIR"

say() { printf '\n%s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

run() {
  if [[ "$DRYRUN" == "1" ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  eval "$@"
}

install_pkgs() {
  local pkgs=("$@")
  if [[ "$NO_INSTALL" == "1" ]]; then
    echo "Missing dependencies: ${pkgs[*]}" >&2
    exit 1
  fi

  if have apt-get; then
    run "sudo apt-get update"
    run "sudo apt-get install -y ${pkgs[*]}"
    return 0
  fi

  if have dnf; then
    run "sudo dnf install -y ${pkgs[*]}"
    return 0
  fi

  if have yum; then
    run "sudo yum install -y ${pkgs[*]}"
    return 0
  fi

  if have brew; then
    run "brew install ${pkgs[*]}"
    return 0
  fi

  echo "No supported package manager found. Please install: ${pkgs[*]}" >&2
  exit 1
}

ensure_java17() {
  if have java; then
    local major
    major="$(java -version 2>&1 | head -n1 | sed -E 's/.*"([0-9]+).*/\1/')"
    if [[ "$major" == "17" ]]; then return 0; fi
  fi
  install_pkgs openjdk-17-jdk
}

ensure_maven() {
  have mvn || install_pkgs maven
}

ensure_node18() {
  if have node; then
    local major
    major="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
    if [[ "$major" -ge 18 ]]; then return 0; fi
  fi

  if have apt-get; then
    install_pkgs nodejs npm
    return 0
  fi
  if have brew; then
    install_pkgs node
    return 0
  fi
  echo "Node.js 18+ is required. Please install it manually." >&2
  exit 1
}

ensure_docker() {
  have docker || install_pkgs docker.io
}

start_compose() {
  [[ "$SKIP_DB" == "1" ]] && return 0
  ensure_docker
  say "Starting MySQL (docker compose) ..."
  (cd "$ROOT" && run "docker compose up -d || docker-compose up -d")
}

wait_mysql() {
  [[ "$SKIP_DB" == "1" ]] && return 0
  [[ "$DRYRUN" == "1" ]] && return 0
  say "Waiting for MySQL to be ready ..."
  for _ in $(seq 1 60); do
    if docker exec "$MYSQL_CONTAINER" mysqladmin ping "-u$DB_USER" "-p$DB_PASSWORD" --silent >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "MySQL is not ready. Check: docker logs $MYSQL_CONTAINER" >&2
  exit 1
}

import_db() {
  [[ "$SKIP_DB" == "1" ]] && return 0
  [[ "$INIT_DB" == "0" ]] && return 0
  wait_mysql
  say "Importing database schema and seed data ..."

  local sqls=(
    "back/sql/schema_v1.sql"
    "back/sql/schema_v2_address.sql"
    "back/sql/schema_v3_payment.sql"
    "back/sql/schema_v4_marketing_aftersales.sql"
    "back/sql/schema_v5_products_tags.sql"
    "back/sql/seed_demo.sql"
    "back/sql/seed_products_categories_1_8.sql"
  )

  for rel in "${sqls[@]}"; do
    local f="$ROOT/$rel"
    [[ -f "$f" ]] || { echo "SQL file not found: $f" >&2; exit 1; }
    if [[ "$DRYRUN" == "1" ]]; then
      echo "[dry-run] import $rel"
      continue
    fi
    docker exec -i "$MYSQL_CONTAINER" mysql "-u$DB_USER" "-p$DB_PASSWORD" "$DB_NAME" <"$f"
  done
}

frontend_deps() {
  [[ -f "$FRONTEND_DIR/package.json" ]] || return 0
  ensure_node18
  say "Installing frontend dependencies ..."
  (cd "$FRONTEND_DIR" && run "npm ci")
}

backend_deps() {
  [[ -f "$BACKEND_DIR/pom.xml" ]] || return 0
  ensure_java17
  ensure_maven
}

build_if_needed() {
  [[ "$SKIP_BUILD" == "1" ]] && return 0
  backend_deps
  frontend_deps

  if [[ -f "$BACKEND_DIR/pom.xml" ]]; then
    say "Building backend (Maven) ..."
    (cd "$BACKEND_DIR" && run "mvn -DskipTests package")
  fi

  if [[ "$MODE" == "prod" && -f "$FRONTEND_DIR/package.json" ]]; then
    say "Building frontend (Vite) ..."
    (cd "$FRONTEND_DIR" && run "npm run build")
  fi
}

run_bg() {
  local name="$1"
  local workdir="$2"
  shift 2
  local logfile="$LOGS_DIR/${name}.log"
  local pidfile="$PIDS_DIR/${name}.pid"

  if [[ "$DRYRUN" == "1" ]]; then
    printf '[dry-run] (cd "%s" && %s) > "%s" 2>&1 &\n' "$workdir" "$*" "$logfile"
    return 0
  fi

  (
    cd "$workdir"
    "$@"
  ) >"$logfile" 2>&1 &

  echo "$!" >"$pidfile"
  echo "Started $name (pid=$(cat "$pidfile")), logs: $logfile"
}

start_app() {
  say "Starting services ..."

  if [[ -f "$BACKEND_DIR/pom.xml" ]]; then
    backend_deps
    if [[ "$MODE" == "dev" ]]; then
      run_bg backend "$BACKEND_DIR" mvn spring-boot:run
    else
      local jar
      jar="$(ls -1t "$BACKEND_DIR"/target/*.jar 2>/dev/null | head -n1 || true)"
      [[ -n "$jar" ]] || { echo "Backend jar not found. Build first." >&2; exit 1; }
      run_bg backend "$BACKEND_DIR" java -jar "$jar"
    fi
  fi

  if [[ -f "$FRONTEND_DIR/package.json" ]]; then
    frontend_deps
    if [[ "$MODE" == "dev" ]]; then
      run_bg frontend "$FRONTEND_DIR" npm run dev
    else
      run_bg frontend "$FRONTEND_DIR" npm run preview -- --host 0.0.0.0 --port 5173
    fi
  fi

  printf '\nFrontend: http://localhost:5173\nBackend:  http://localhost:8080/api\n'
}

say "Project root: $ROOT"
start_compose
import_db
build_if_needed
start_app
