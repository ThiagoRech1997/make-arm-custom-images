#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/utils.sh"; load_env

IMG="${OUTPUT_DIR}/${IMG_NAME}"

# Nota: QEMU para RPi é limitado; usamos raspi2 + cortex-a7 para smoke tests
qemu-system-arm \
  -M "${QEMU_MACHINE}" \
  -cpu "${QEMU_CPU}" \
  -m "${QEMU_RAM}" \
  -kernel /usr/lib/qemu/arm/kernel-nographic.elf \
  -drive file="${IMG}",format=raw,if=sd \
  -serial stdio \
  -append "console=ttyAMA0 root=/dev/mmcblk0p2 rootwait rw" 