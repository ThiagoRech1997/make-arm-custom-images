#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/utils.sh"; load_env; require_root

IMG="${OUTPUT_DIR}/${IMG_NAME}"
BOOT_SIZE_MB=256

mkdir -p "${OUTPUT_DIR}" "${TMP_DIR}"
log "Criando imagem ${IMG} com ${IMG_SIZE_GB}G"
qemu-img create -f raw "${IMG}" ${IMG_SIZE_GB}G

log "Particionando (MBR: boot + root)"
parted --script "${IMG}" \
  mklabel msdos \
  mkpart primary fat32 1MiB ${BOOT_SIZE_MB}MiB \
  set 1 boot on \
  mkpart primary ext4 ${BOOT_SIZE_MB}MiB 100%

# mapear partições
LOOPDEV=$(losetup -Pf --show "${IMG}")
BOOT_PART=${LOOPDEV}p1
ROOT_PART=${LOOPDEV}p2

mkfs.vfat -F32 "${BOOT_PART}"
mkfs.ext4 -F "${ROOT_PART}"

mkdir -p "${TMP_DIR}/boot" "${TMP_DIR}/root"
mount "${ROOT_PART}" "${TMP_DIR}/root"
mount "${BOOT_PART}" "${TMP_DIR}/boot"

# extrair rootfs Alpine
log "Extraindo rootfs Alpine"
tar -xzf "${ROOT_DIR}/tmp/${ALPINE_TARBALL}" -C "${TMP_DIR}/root"

# preparar boot (nota: firmware/kernel reais do RPi devem ser adicionados depois, para QEMU usamos emulação aproximada)
touch "${TMP_DIR}/boot/BOOTPLACEHOLDER"

sync
umount "${TMP_DIR}/boot" || true
umount "${TMP_DIR}/root" || true
losetup -d "${LOOPDEV}"

log "Imagem base criada" 