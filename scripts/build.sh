#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/utils.sh"; load_env

log "=== Build iniciado ==="
sudo -v

"${ROOT_DIR}/scripts/fetch_base.sh"
sudo "${ROOT_DIR}/scripts/mkimg.sh"
sudo "${ROOT_DIR}/scripts/mount.sh"
sudo "${ROOT_DIR}/scripts/customize.sh"
sudo "${ROOT_DIR}/scripts/unmount.sh"

log "Imagem pronta em ${OUTPUT_DIR}/${IMG_NAME}"
log "Para testar em QEMU: ./scripts/qemu-run.sh" 