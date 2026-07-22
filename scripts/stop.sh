#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIDS_DIR="$ROOT/.pids"
STOP_INFRASTRUCTURE=0
WITH_MONITORING=0

for arg in "$@"; do
  case "$arg" in
    --stop-infrastructure) STOP_INFRASTRUCTURE=1 ;;
    --with-monitoring) WITH_MONITORING=1 ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

for name in backend frontend admin; do
  pid_file="$PIDS_DIR/$name.pid"
  if [[ ! -f "$pid_file" ]]; then
    printf '%s: no managed process metadata\n' "$name"
    continue
  fi

  pid="$(sed -n '1p' "$pid_file")"
  expected_start="$(sed -n '2p' "$pid_file")"
  expected_root="$(sed -n '3p' "$pid_file")"
  expected_directory="$(sed -n '4p' "$pid_file")"
  if [[ ! "$pid" =~ ^[0-9]+$ || -z "$expected_start" || "$expected_root" != "$ROOT" || "$expected_directory" != "$ROOT"/* ]]; then
    printf '%s: invalid or legacy PID metadata; refusing to stop any process\n' "$name" >&2
    continue
  fi

  if ! kill -0 "$pid" 2>/dev/null; then
    printf '%s: PID %s is no longer running\n' "$name" "$pid"
    rm -f "$pid_file"
    continue
  fi

  actual_start="$(ps -p "$pid" -o lstart= | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  actual_command="$(ps -p "$pid" -o command= | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [[ -z "$actual_start" || "$actual_start" != "$expected_start" || "$actual_command" != *"$expected_directory"* ]]; then
    printf '%s: PID %s identity changed or was reused; refusing to stop it\n' "$name" "$pid" >&2
    continue
  fi

  kill "$pid"
  for _ in $(seq 1 20); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.25
  done
  kill -0 "$pid" 2>/dev/null && kill -9 "$pid"
  if kill -0 "$pid" 2>/dev/null; then
    printf '%s: failed to stop verified PID %s\n' "$name" "$pid" >&2
    exit 1
  fi

  rm -f "$pid_file"
  printf '%s: stopped verified PID %s\n' "$name" "$pid"
done

if [[ "$STOP_INFRASTRUCTURE" == "1" ]]; then
  cd "$ROOT"
  if [[ "$WITH_MONITORING" == "1" ]]; then
    docker compose --profile monitoring stop
  else
    docker compose stop mysql redis
  fi
fi
