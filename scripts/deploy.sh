#!/usr/bin/env bash
set -euo pipefail

MODE="${MODE:-dev}"
NO_INSTALL=0
SKIP_DB=0
INIT_DB=0
SKIP_BUILD=0
DRYRUN=0
DB_NAME="${DB_NAME:-web}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-projectku-mysql}"
FRONTEND_DEPS_DONE=0
ADMIN_DEPS_DONE=0

if [[ -f ".env" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    [[ -z "${!key:-}" ]] && export "$key"="$value"
  done < ".env"
fi

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
ADMIN_DIR="$ROOT/frontend-admin"
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
  if have apt-get; then install_pkgs openjdk-17-jdk; return 0; fi
  if have dnf || have yum; then install_pkgs java-17-openjdk-devel; return 0; fi
  if have brew; then install_pkgs openjdk@17; return 0; fi
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
    if have node; then
      local major2
      major2="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
      if [[ "$major2" -ge 18 ]]; then return 0; fi
    fi
    echo "Node.js 18+ is required. Your distro repo may be too old; please install via nvm or NodeSource." >&2
    exit 1
  fi
  if have brew; then
    install_pkgs node
    return 0
  fi
  echo "Node.js 18+ is required. Please install it manually." >&2
  exit 1
}

ensure_docker() {
  if have docker; then return 0; fi
  if have apt-get; then install_pkgs docker.io; return 0; fi
  if have dnf || have yum; then install_pkgs docker; return 0; fi
  if have brew; then
    install_pkgs docker
    echo "On macOS you still need Docker Desktop/Colima to run containers." >&2
    return 0
  fi
  install_pkgs docker
}

start_compose() {
  [[ "$SKIP_DB" == "1" ]] && return 0
  ensure_docker
  say "Starting infrastructure services (docker compose) ..."
  if [[ "$DRYRUN" == "1" ]]; then
    echo "[dry-run] (cd \"$ROOT\" && docker compose up -d) or docker-compose up -d"
    return 0
  fi
  (cd "$ROOT" && (docker compose up -d || docker-compose up -d))
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

  local sql_dir="$ROOT/back/sql"
  if [[ ! -d "$sql_dir" && -d "$BACKEND_DIR/sql" ]]; then
    sql_dir="$BACKEND_DIR/sql"
  fi
  [[ -d "$sql_dir" ]] || { echo "SQL directory not found: $sql_dir" >&2; exit 1; }

  local sqls=()
  if [[ -f "$sql_dir/init_db.sql" ]]; then
    sqls=("init_db.sql")
  else
    local ordered=(
      "schema_v1.sql"
      "schema_v2_address.sql"
      "schema_v3_payment.sql"
      "schema_v4_marketing_aftersales.sql"
      "schema_v5_products_tags.sql"
      "seed_demo.sql"
      "seed_products_categories_1_8.sql"
    )
    local rel
    for rel in "${ordered[@]}"; do
      [[ -f "$sql_dir/$rel" ]] && sqls+=("$rel")
    done

    if [[ ${#sqls[@]} -eq 0 ]]; then
      shopt -s nullglob
      local discovered=("$sql_dir"/*.sql)
      shopt -u nullglob
      local f
      for f in "${discovered[@]}"; do
        [[ -f "$f" ]] && sqls+=("$(basename "$f")")
      done
    fi
  fi

  [[ ${#sqls[@]} -gt 0 ]] || { echo "No SQL files found in: $sql_dir" >&2; exit 1; }

  if [[ "$DRYRUN" == "1" ]]; then
    echo "[dry-run] ensure database exists: $DB_NAME"
  else
    docker exec "$MYSQL_CONTAINER" mysql "-u$DB_USER" "-p$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` DEFAULT CHARSET utf8mb4;" >/dev/null
  fi

  local rel
  for rel in "${sqls[@]}"; do
    local f="$sql_dir/$rel"
    [[ -f "$f" ]] || { echo "SQL file not found: $f" >&2; exit 1; }
    if [[ "$DRYRUN" == "1" ]]; then
      echo "[dry-run] import $(basename "$sql_dir")/$rel"
      continue
    fi
    docker exec -i "$MYSQL_CONTAINER" mysql "-u$DB_USER" "-p$DB_PASSWORD" "$DB_NAME" <"$f"
  done
}

npm_install_dir() {
  local dir="$1"
  local label="$2"
  [[ -f "$dir/package.json" ]] || return 0
  ensure_node18
  say "Installing $label dependencies ..."
  if [[ -f "$dir/package-lock.json" ]]; then
    (cd "$dir" && run "npm ci")
  else
    (cd "$dir" && run "npm install")
  fi
}

frontend_deps() {
  [[ -f "$FRONTEND_DIR/package.json" ]] || return 0
  if [[ "$FRONTEND_DEPS_DONE" == "1" ]]; then return 0; fi
  npm_install_dir "$FRONTEND_DIR" "frontend"
  FRONTEND_DEPS_DONE=1
}

admin_deps() {
  [[ -f "$ADMIN_DIR/package.json" ]] || return 0
  if [[ "$ADMIN_DEPS_DONE" == "1" ]]; then return 0; fi
  npm_install_dir "$ADMIN_DIR" "frontend-admin"
  ADMIN_DEPS_DONE=1
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
  admin_deps

  if [[ -f "$BACKEND_DIR/pom.xml" ]]; then
    say "Building backend (Maven) ..."
    (cd "$BACKEND_DIR" && run "mvn -DskipTests package")
  fi

  if [[ "$MODE" == "prod" && -f "$FRONTEND_DIR/package.json" ]]; then
    say "Building frontend (Vite) ..."
    (cd "$FRONTEND_DIR" && run "npm run build")
  fi

  if [[ "$MODE" == "prod" && -f "$ADMIN_DIR/package.json" ]]; then
    say "Building frontend-admin (Vite) ..."
    (cd "$ADMIN_DIR" && run "npm run build")
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

  if [[ -f "$ADMIN_DIR/package.json" ]]; then
    admin_deps
    if [[ "$MODE" == "dev" ]]; then
      run_bg admin "$ADMIN_DIR" npm run dev
    else
      run_bg admin "$ADMIN_DIR" npm run preview -- --host 0.0.0.0 --port 4174
    fi
  fi

  printf '\nFrontend: http://localhost:5173\n'
  if [[ "$MODE" == "dev" ]]; then
    printf 'Admin:    http://localhost:5174\n'
  else
    printf 'Admin:    http://localhost:4174\n'
  fi
  printf 'Backend:  http://localhost:8080/api\n'
}

say "Project root: $ROOT"
start_compose
import_db
build_if_needed
start_app
