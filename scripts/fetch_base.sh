#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/utils.sh"; load_env

mkdir -p "${ROOT_DIR}/tmp" "${OUTPUT_DIR}"
cd "${ROOT_DIR}/tmp"

if [[ ! -f "${ALPINE_TARBALL}" ]]; then
  log "Baixando ${ALPINE_TARBALL}"
  wget "${ALPINE_BASE_URL}/v${ALPINE_VERSION%.*}/releases/${ALPINE_ARCH}/${ALPINE_TARBALL}"
else
  log "Tarball já presente: ${ALPINE_TARBALL}"
fi

log "OK" 