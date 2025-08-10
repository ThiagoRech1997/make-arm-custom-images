#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/utils.sh"; load_env; require_root

IMG="${OUTPUT_DIR}/${IMG_NAME}"
mkdir -p "${TMP_DIR}/boot" "${TMP_DIR}/root"

LOOPDEV=$(losetup -Pf --show "${IMG}")
echo "${LOOPDEV}" > "${TMP_DIR}/loopdev"

mount "${LOOPDEV}p2" "${TMP_DIR}/root"
mount "${LOOPDEV}p1" "${TMP_DIR}/boot"

log "Montado em ${TMP_DIR}/root e ${TMP_DIR}/boot" 