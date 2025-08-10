#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

log() { echo "[$(date +'%F %T')] $*"; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Execute como root (sudo)."
    exit 1
  fi
}

load_env() {
  if [[ -f "${ENV_FILE}" ]]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' "${ENV_FILE}" | xargs -d '\n')
  else
    echo ".env não encontrado. Copie de env.example"
    exit 1
  fi
} 