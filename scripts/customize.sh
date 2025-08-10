#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/utils.sh"; load_env; require_root

LOOPDEV=$(cat "${TMP_DIR}/loopdev")
ROOT_MNT="${TMP_DIR}/root"
BOOT_MNT="${TMP_DIR}/boot"

log "Montando pseudo-FS"
mount -t proc none "${ROOT_MNT}/proc"
mount -t sysfs none "${ROOT_MNT}/sys"
mount -o bind /dev "${ROOT_MNT}/dev"
mount -o bind /dev/pts "${ROOT_MNT}/dev/pts"

# wpa_supplicant
install -d "${ROOT_MNT}/etc/wpa_supplicant"
envsubst < "${ROOT_DIR}/configs/wpa_supplicant.conf.tmpl" > "${ROOT_MNT}/etc/wpa_supplicant/wpa_supplicant.conf"

# interfaces (opcional, Alpine também permite setup via scripts)
install -d "${ROOT_MNT}/etc/network"
envsubst < "${ROOT_DIR}/configs/interfaces.rpi3.tmpl" > "${ROOT_MNT}/etc/network/interfaces"

# hostname
echo "${HOSTNAME}" > "${ROOT_MNT}/etc/hostname"

# mirrors
echo "${ALPINE_MIRROR%%/}/v${ALPINE_VERSION%.*}/main" > "${ROOT_MNT}/etc/apk/repositories"
echo "${ALPINE_MIRROR%%/}/v${ALPINE_VERSION%.*}/community" >> "${ROOT_MNT}/etc/apk/repositories"

# pacotes
cp "${ROOT_DIR}/configs/packages.txt" "${ROOT_MNT}/root/packages.txt"
chroot "${ROOT_MNT}" /bin/sh -lc "apk update && apk add \$(cat /root/packages.txt)"

# openrc services
cp "${ROOT_DIR}/configs/services-openrc.txt" "${ROOT_MNT}/root/services-openrc.txt"
chroot "${ROOT_MNT}" /bin/sh -lc 'while read -r svc; do [ -n "$svc" ] && rc-update add "$svc" default || true; done < /root/services-openrc.txt'

# docker enable opcional no boot
if [ "${INSTALL_DOCKER:-false}" = "true" ]; then
  chroot "${ROOT_MNT}" /bin/sh -lc "rc-update add docker boot || true"
fi

# ssh opcional
if [ "${ENABLE_SSH:-true}" = "true" ]; then
  chroot "${ROOT_MNT}" /bin/sh -lc "rc-update add sshd default || true"
fi

# hook pós-customização
install -m 0755 "${ROOT_DIR}/configs/post-customize.sh" "${ROOT_MNT}/root/post-customize.sh"
chroot "${ROOT_MNT}" /bin/sh -lc "/root/post-customize.sh || true"

log "Customização concluída"

umount "${ROOT_MNT}/dev/pts" || true
umount "${ROOT_MNT}/dev" || true
umount "${ROOT_MNT}/proc" || true
umount "${ROOT_MNT}/sys" || true 