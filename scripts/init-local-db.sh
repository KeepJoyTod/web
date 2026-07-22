#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_FILE="$ROOT/back/sql/init_db.sql"
DRY_RUN=0

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

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

[[ "$DB_PORT" =~ ^[0-9]+$ ]] || { echo "DB_PORT must be numeric." >&2; exit 2; }
[[ "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || { echo "DB_NAME may contain only letters, numbers, and underscores." >&2; exit 2; }
[[ "$DB_USER" =~ ^[A-Za-z0-9_]+$ ]] || { echo "DB_USER may contain only letters, numbers, and underscores." >&2; exit 2; }
[[ -f "$SQL_FILE" ]] || { echo "SQL file not found: $SQL_FILE" >&2; exit 1; }

printf 'Local MySQL target: %s@%s:%s/%s (password not printed)\n' "$DB_USER" "$DB_HOST" "$DB_PORT" "$DB_NAME"
if [[ "$DRY_RUN" == "1" ]]; then
  printf '[dry-run] would create database if absent, require zero existing tables, then import %s through stdin\n' "$SQL_FILE"
  exit 0
fi

command -v mysql >/dev/null 2>&1 || {
  echo "mysql CLI was not found in PATH. Install or expose the client before retrying." >&2
  exit 1
}

mysql_args=(--protocol=TCP -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER")

if ! MYSQL_PWD="$DB_PASSWORD" mysql "${mysql_args[@]}" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"; then
  echo "Could not create or access database $DB_NAME. Check the local MySQL service and credentials." >&2
  exit 1
fi

if ! table_count="$(MYSQL_PWD="$DB_PASSWORD" mysql "${mysql_args[@]}" -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';")"; then
  echo "Could not inspect database $DB_NAME. No SQL was imported." >&2
  exit 1
fi

[[ "$table_count" =~ ^[0-9]+$ ]] || { echo "Unexpected table count returned by MySQL." >&2; exit 1; }
if [[ "$table_count" != "0" ]]; then
  echo "Database $DB_NAME contains $table_count table(s); refusing to import into a non-empty database." >&2
  exit 1
fi

printf 'Importing schema and seed data into empty database %s...\n' "$DB_NAME"
if ! MYSQL_PWD="$DB_PASSWORD" mysql "${mysql_args[@]}" "$DB_NAME" < "$SQL_FILE"; then
  printf 'Import failed. Database %s may now be partially initialized. Keep it for inspection and set a new DB_NAME in .env before retrying; this script will not delete tables or data.\n' "$DB_NAME" >&2
  exit 1
fi

printf 'Database %s initialized successfully.\n' "$DB_NAME"
