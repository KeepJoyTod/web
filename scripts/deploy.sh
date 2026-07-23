#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT/back"
FRONTEND_DIR="$ROOT/frontend"
ADMIN_DIR="$ROOT/frontend-admin"
LOGS_DIR="$ROOT/logs"
PIDS_DIR="$ROOT/.pids"

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

MODE="${MODE:-dev}"
SKIP_INFRASTRUCTURE=0
INIT_DB=0
SKIP_BUILD=0
DRY_RUN=0
WITH_MONITORING=0
DB_NAME="${DB_NAME:-web}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-123456}"
BACKEND_PORT="${BACKEND_PORT:-8080}"
FRONTEND_PORT="${FRONTEND_PORT:-5173}"
ADMIN_PORT="${ADMIN_PORT:-5174}"

for arg in "$@"; do
  case "$arg" in
    --mode=dev|--mode=prod) MODE="${arg#*=}" ;;
    --skip-infrastructure|--skip-db) SKIP_INFRASTRUCTURE=1 ;;
    --init-db) INIT_DB=1 ;;
    --skip-build) SKIP_BUILD=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --with-monitoring) WITH_MONITORING=1 ;;
    --no-install) : ;; # Backward-compatible no-op; this script never installs system software.
    --db-name=*) DB_NAME="${arg#*=}" ;;
    --db-user=*) DB_USER="${arg#*=}" ;;
    --db-password=*) DB_PASSWORD="${arg#*=}" ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

[[ "$MODE" == "dev" || "$MODE" == "prod" ]] || { echo "MODE must be dev or prod." >&2; exit 2; }
[[ "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || { echo "DB_NAME may contain only letters, numbers, and underscores." >&2; exit 2; }
[[ "$DB_USER" =~ ^[A-Za-z0-9_]+$ ]] || { echo "DB_USER may contain only letters, numbers, and underscores." >&2; exit 2; }
if [[ "$SKIP_INFRASTRUCTURE" == "0" && "$DB_USER" != "root" ]]; then
  echo "The Compose workflow requires DB_USER=root. Use --skip-infrastructure for an existing non-root MySQL account." >&2
  exit 2
fi

export MODE DB_NAME DB_USER DB_PASSWORD BACKEND_PORT FRONTEND_PORT ADMIN_PORT
mkdir -p "$LOGS_DIR" "$PIDS_DIR"

step() { printf '\n==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

assert_java17() {
  have java || { echo "JDK 17 is required, but java was not found in PATH." >&2; exit 1; }
  local version_line detected_java_home
  version_line="$(java -version 2>&1 | head -n 1)"
  [[ "$version_line" =~ \"17([.\"]|$) ]] || { echo "JDK 17 is required. Current: $version_line" >&2; exit 1; }
  if [[ -z "${JAVA_HOME:-}" || ! -x "${JAVA_HOME:-}/bin/javac" ]]; then
    detected_java_home="$(java -XshowSettings:properties -version 2>&1 | sed -n 's/^[[:space:]]*java\.home[[:space:]]*=[[:space:]]*//p' | head -n 1)"
    if [[ -n "$detected_java_home" && -x "$detected_java_home/bin/javac" ]]; then
      export JAVA_HOME="$detected_java_home"
      printf 'Using JAVA_HOME=%s for this deployment process.\n' "$JAVA_HOME"
    fi
  fi
  [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/javac" ]] || { echo "JAVA_HOME could not be resolved to a JDK 17 root." >&2; exit 1; }
}

assert_node() {
  have node || { echo "Node.js ^20.19.0 or >=22.12.0 is required." >&2; exit 1; }
  local major minor version
  version="$(node --version | sed 's/^v//')"
  major="${version%%.*}"
  minor="${version#*.}"; minor="${minor%%.*}"
  if ! { [[ "$major" == "20" && "$minor" -ge 19 ]] || [[ "$major" == "22" && "$minor" -ge 12 ]] || [[ "$major" -gt 22 ]]; }; then
    echo "Node.js ^20.19.0 or >=22.12.0 is required. Current: v$version" >&2
    exit 1
  fi
  have npm || { echo "npm was not found in PATH." >&2; exit 1; }
}

maven_command=()
resolve_maven() {
  if [[ -f "$BACKEND_DIR/mvnw" ]]; then
    if [[ -x "$BACKEND_DIR/mvnw" ]]; then
      maven_command=("$BACKEND_DIR/mvnw")
    else
      maven_command=(bash "$BACKEND_DIR/mvnw")
    fi
  elif have mvn; then
    maven_command=(mvn)
  else
    echo "Maven was not found. Restore back/mvnw or install Maven 3.8+." >&2
    exit 1
  fi
}

start_infrastructure() {
  [[ "$SKIP_INFRASTRUCTURE" == "1" ]] && return 0
  have docker || { echo "Docker is required unless --skip-infrastructure is used." >&2; exit 1; }
  step "Starting MySQL and Redis"
  if [[ "$WITH_MONITORING" == "1" ]]; then
    (cd "$ROOT" && run docker compose --profile monitoring up -d)
  else
    (cd "$ROOT" && run docker compose up -d mysql redis)
  fi
}

compose_mysql() {
  (
    cd "$ROOT"
    docker compose exec -T mysql sh -c \
      'user=$1; shift; MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -u "$user" "$@"' \
      sh "$DB_USER" "$@"
  )
}

compose_mysqladmin() {
  (
    cd "$ROOT"
    docker compose exec -T mysql sh -c \
      'user=$1; shift; MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysqladmin -u "$user" "$@"' \
      sh "$DB_USER" "$@"
  )
}

wait_mysql() {
  [[ "$SKIP_INFRASTRUCTURE" == "1" || "$DRY_RUN" == "1" ]] && return 0
  step "Waiting for MySQL"
  local attempt
  for attempt in $(seq 1 60); do
    if compose_mysqladmin ping --silent >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "MySQL did not become ready. Run from the repository root: docker compose logs mysql" >&2
  exit 1
}

initialize_database() {
  [[ "$INIT_DB" == "1" ]] || return 0
  [[ "$SKIP_INFRASTRUCTURE" == "0" ]] || { echo "--init-db requires the Compose MySQL container." >&2; exit 1; }
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] initialize empty database $DB_NAME from back/sql/init_db.sql"
    return 0
  fi

  wait_mysql
  local table_count
  compose_mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  table_count="$(compose_mysql -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';")"
  [[ "$table_count" == "0" ]] || { echo "Database $DB_NAME is not empty. Omit --init-db to preserve existing data." >&2; exit 1; }
  step "Importing database schema and seed data"
  if ! compose_mysql "$DB_NAME" < "$BACKEND_DIR/sql/init_db.sql"; then
    printf 'Import failed. Database %s may now be partially initialized. Keep it for inspection and set a new DB_NAME in .env before retrying; this script will not delete tables or data.\n' "$DB_NAME" >&2
    exit 1
  fi
}

lock_hash() {
  local file="$1"
  if have sha256sum; then
    sha256sum "$file" | awk '{print $1}'
  elif have shasum; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "A SHA-256 tool (sha256sum or shasum) is required." >&2
    return 1
  fi
}

managed_process_matches() {
  local name="$1" pid_file="$PIDS_DIR/$1.pid" pid expected_start expected_root expected_directory actual_start actual_command
  [[ -f "$pid_file" ]] || return 1
  pid="$(sed -n '1p' "$pid_file")"
  expected_start="$(sed -n '2p' "$pid_file")"
  expected_root="$(sed -n '3p' "$pid_file")"
  expected_directory="$(sed -n '4p' "$pid_file")"
  [[ "$pid" =~ ^[0-9]+$ && -n "$expected_start" && "$expected_root" == "$ROOT" && "$expected_directory" == "$ROOT"/* ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  actual_start="$(ps -p "$pid" -o lstart= | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  actual_command="$(ps -p "$pid" -o command= | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ "$actual_start" == "$expected_start" && "$actual_command" == *"$expected_directory"* ]]
}

install_node_dependencies() {
  local directory="$1" name="$2" url="$3" marker="$4" current_hash recorded_hash="" lock_marker
  current_hash="$(lock_hash "$directory/package-lock.json")"
  lock_marker="$directory/node_modules/.projectku-package-lock.sha256"
  if frontend_up "$url" "$marker"; then
    [[ -f "$lock_marker" ]] && recorded_hash="$(tr -d '\r\n' < "$lock_marker")"
    if managed_process_matches "$name" && [[ "$recorded_hash" == "$current_hash" ]]; then
      printf '%s is already running with the current lockfile; skipping npm ci.\n' "$(basename "$directory")"
      return 0
    fi
    printf '%s is running without matching process/lockfile metadata. Stop it before deployment.\n' "$(basename "$directory")" >&2
    return 1
  fi
  step "Synchronizing dependencies: $(basename "$directory")"
  (cd "$directory" && run npm ci)
  [[ "$DRY_RUN" == "1" ]] || printf '%s\n' "$current_hash" > "$lock_marker"
}

build_projects() {
  assert_java17
  assert_node
  resolve_maven
  install_node_dependencies "$FRONTEND_DIR" frontend "http://127.0.0.1:$FRONTEND_PORT/" 'content="projectku-user"'
  install_node_dependencies "$ADMIN_DIR" admin "http://127.0.0.1:$ADMIN_PORT/" 'content="projectku-admin"'
  [[ "$SKIP_BUILD" == "1" ]] && return 0

  step "Compiling backend"
  (cd "$BACKEND_DIR" && run "${maven_command[@]}" -DskipTests compile)
  step "Building user frontend"
  (cd "$FRONTEND_DIR" && run npm run build)
  step "Building admin frontend"
  (cd "$ADMIN_DIR" && run npm run build)
}

backend_up() {
  have curl || return 1
  curl --silent --fail --max-time 3 "$1" 2>/dev/null | node -e '
    let body = "";
    process.stdin.on("data", chunk => body += chunk);
    process.stdin.on("end", () => {
      try {
        const health = JSON.parse(body);
        const ready = health.status === "UP"
          && health.components?.db?.status === "UP"
          && health.components?.redis?.status === "UP";
        process.exit(ready ? 0 : 1);
      } catch {
        process.exit(1);
      }
    });
  '
}

frontend_up() {
  local response status body
  have curl || return 1
  response="$(curl --silent --max-time 3 --write-out $'\n%{http_code}' "$1" 2>/dev/null)" || return 1
  status="${response##*$'\n'}"
  body="${response%$'\n'*}"
  [[ "$status" == "200" ]] && grep -Fq "$2" <<< "$body"
}

start_process() {
  local name="$1" directory="$2" pid started
  shift 2
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] start %s:' "$name"
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  (
    cd "$directory"
    nohup "$@" >"$LOGS_DIR/$name.out.log" 2>"$LOGS_DIR/$name.err.log" &
    pid=$!
    started="$(ps -p "$pid" -o lstart= | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    {
      printf '%s\n' "$pid"
      printf '%s\n' "$started"
      printf '%s\n' "$ROOT"
      printf '%s\n' "$directory"
    } >"$PIDS_DIR/$name.pid"
  )
  printf 'Started %s (PID %s).\n' "$name" "$(sed -n '1p' "$PIDS_DIR/$name.pid")"
}

wait_service() {
  local name="$1" url="$2" timeout="$3" elapsed=0
  shift 3
  [[ "$DRY_RUN" == "1" ]] && return 0
  while [[ "$elapsed" -lt "$timeout" ]]; do
    if "$@"; then printf '%s ready: %s\n' "$name" "$url"; return 0; fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  echo "$name did not become ready: $url. Check logs/$name.err.log and logs/$name.out.log." >&2
  exit 1
}

start_applications() {
  local backend_health="http://127.0.0.1:$BACKEND_PORT/api/actuator/health"
  local frontend_url="http://127.0.0.1:$FRONTEND_PORT/"
  local admin_url="http://127.0.0.1:$ADMIN_PORT/"
  local -a frontend_command admin_command
  step "Starting application services"

  if backend_up "$backend_health"; then
    managed_process_matches backend || {
      echo "Backend is healthy at $backend_health but is not managed by this repository; port $BACKEND_PORT is occupied." >&2
      exit 1
    }
    echo "Reusing verified backend process from this repository."
  elif managed_process_matches backend; then
    echo "Backend process from this repository is already running; waiting for health."
  else
    start_process backend "$BACKEND_DIR" "${maven_command[@]}" spring-boot:run
  fi

  wait_service backend "$backend_health" 120 backend_up "$backend_health"

  if [[ "$MODE" == "dev" ]]; then
    frontend_command=(npm --prefix "$FRONTEND_DIR" run dev -- --host 0.0.0.0 --port "$FRONTEND_PORT")
    admin_command=(npm --prefix "$ADMIN_DIR" run dev -- --host 0.0.0.0 --port "$ADMIN_PORT")
  else
    frontend_command=(npm --prefix "$FRONTEND_DIR" run preview -- --host 0.0.0.0 --port "$FRONTEND_PORT")
    admin_command=(npm --prefix "$ADMIN_DIR" run preview -- --host 0.0.0.0 --port "$ADMIN_PORT")
  fi

  if frontend_up "$frontend_url" 'content="projectku-user"'; then
    managed_process_matches frontend || {
      echo "User frontend is healthy at $frontend_url but is not managed by this repository; port $FRONTEND_PORT is occupied." >&2
      exit 1
    }
    echo "Reusing verified user frontend process from this repository."
  elif managed_process_matches frontend; then
    echo "User frontend process from this repository is already running; waiting for health."
  else
    start_process frontend "$FRONTEND_DIR" "${frontend_command[@]}"
  fi

  if frontend_up "$admin_url" 'content="projectku-admin"'; then
    managed_process_matches admin || {
      echo "Admin frontend is healthy at $admin_url but is not managed by this repository; port $ADMIN_PORT is occupied." >&2
      exit 1
    }
    echo "Reusing verified admin frontend process from this repository."
  elif managed_process_matches admin; then
    echo "Admin frontend process from this repository is already running; waiting for health."
  else
    start_process admin "$ADMIN_DIR" "${admin_command[@]}"
  fi

  wait_service frontend "$frontend_url" 60 frontend_up "$frontend_url" 'content="projectku-user"'
  wait_service admin "$admin_url" 60 frontend_up "$admin_url" 'content="projectku-admin"'
}

step "Project root: $ROOT"
start_infrastructure
initialize_database
build_projects
start_applications

printf '\nUser frontend:  http://localhost:%s\n' "$FRONTEND_PORT"
printf 'Admin frontend: http://localhost:%s\n' "$ADMIN_PORT"
printf 'Backend:        http://localhost:%s/api\n' "$BACKEND_PORT"
printf 'Health:         http://localhost:%s/api/actuator/health\n' "$BACKEND_PORT"
