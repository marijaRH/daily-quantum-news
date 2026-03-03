#!/usr/bin/env bash
# Run Daily Quantum News digest. Use from cron (8AM CET) or GitHub Actions.
# Usage: run-quantum-digest.sh [env-file]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${1:-}" ]]; then
  if [[ "$1" == /* ]]; then
    ENV_FILE="$1"
  else
    ENV_FILE="${SCRIPT_DIR}/$1"
  fi
else
  ENV_FILE="${SCRIPT_DIR}/quantum-digest.env"
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

export PYTHONPATH="${SCRIPT_DIR}/.venv-deps:${PYTHONPATH:-}"
exec python3 "${SCRIPT_DIR}/quantum_daily_digest.py"
