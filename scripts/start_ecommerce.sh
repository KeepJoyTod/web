#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-start}" in
  start)
    shift || true
    exec bash "$SCRIPT_DIR/deploy.sh" "$@"
    ;;
  stop)
    shift
    exec bash "$SCRIPT_DIR/stop.sh" "$@"
    ;;
  restart)
    shift
    bash "$SCRIPT_DIR/stop.sh"
    exec bash "$SCRIPT_DIR/deploy.sh" "$@"
    ;;
  status)
    shift
    exec bash "$SCRIPT_DIR/doctor.sh" "$@"
    ;;
  help|-h|--help)
    cat <<'EOF'
This compatibility entry delegates to the maintained scripts:
  start_ecommerce.sh [start] [deploy options]  -> scripts/deploy.sh
  start_ecommerce.sh stop [stop options]       -> scripts/stop.sh
  start_ecommerce.sh restart [deploy options]  -> stop, then deploy
  start_ecommerce.sh status                    -> scripts/doctor.sh

See DEPLOYMENT.md for the canonical local deployment workflow.
EOF
    ;;
  backend|frontend|admin)
    printf 'Partial-service startup is no longer supported by this compatibility entry.\n' >&2
    printf 'Use scripts/deploy.sh and see DEPLOYMENT.md.\n' >&2
    exit 2
    ;;
  *)
    exec bash "$SCRIPT_DIR/deploy.sh" "$@"
    ;;
esac
