#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/utils.sh"; load_env; require_root

ROOT_MNT="${TMP_DIR}/root"
BOOT_MNT="${TMP_DIR}/boot"
LOOPDEV=$(cat "${TMP_DIR}/loopdev" || true)

umount "${ROOT_MNT}" || true
umount "${BOOT_MNT}" || true

if [[ -n "${LOOPDEV}" ]]; then
  losetup -d "${LOOPDEV}" || true
fi

log "Desmontado" 