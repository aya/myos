#!/bin/sh
[ -n "${DEBUG}" ] && set -x

[ ! -f "${HOME}/.ecryptfs/auto-mount" ] && break

LOWER_DIR="${1:-${ECRYPTFS_LOWER_DIR:-${HOME}/Secure}}"
UPPER_DIR="${ECRYPTFS_UPPER_DIR:-${LOWER_DIR}}"
ALIAS="${ECRYPTFS_ALIAS:-${LOWER_DIR##*/}}"
mkdir -p "${LOWER_DIR}" "${UPPER_DIR}"

# ecryptfs already mounted ?
grep -q "${LOWER_DIR} ${UPPER_DIR} ecryptfs " /proc/mounts 2>/dev/null && break

# we should always use the same key when multiple keys are loaded in ssh-agent
if [ -f "${HOME}/.ecryptfs/${ALIAS}.key" ]; then
  ssh_key_fingerprint=$(cat "${HOME}/.ecryptfs/${ALIAS}.key")
else
  ssh_key_fingerprint=$(/usr/bin/ssh-add -l 2>/dev/null |awk '{print $2; exit;}')
  [ -n "${ssh_key_fingerprint}" ] && printf "%s\n" "${ssh_key_fingerprint}" > "${HOME}/.ecryptfs/${ALIAS}.key"
fi
# select ssh key
ssh_key=$(/usr/bin/ssh-add -l 2>/dev/null |awk '$2 == "'${ssh_key_fingerprint:-undef}'" {print $3}')
[ -z "${ssh_key}" ] && echo "WARNING: Unable to find ssh key ${ssh_key} in ssh agent ${SSH_AUTH_SOCK}" && break

if [ -f "${HOME}/.ecryptfs/${ALIAS}.ssh" ]; then
  PASSPHRASE=$(/usr/local/bin/ssh-crypt -b -d -k "${ssh_key}" -i "${HOME}/.ecryptfs/${ALIAS}.ssh")
else
  PASSPHRASE="${ECRYPTFS_PASSPHRASE:-$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)}"
  printf "%s" "${PASSPHRASE}" |/usr/local/bin/ssh-crypt -b -e -k "${ssh_key}" -o "${HOME}/.ecryptfs/${ALIAS}.ssh"
fi
SIG="${ECRYPTFS_SIG:-$(printf "%s" "${PASSPHRASE}" |/usr/bin/ecryptfs-add-passphrase - |/usr/bin/awk '$5 == "sig" {print substr($6,2,16); exit;}')}"
FNEK_SIG="${ECRYPTFS_FNEK_SIG:-$(printf "%s" "${PASSPHRASE}" |/usr/bin/ecryptfs-add-passphrase --fnek - |/usr/bin/awk '$5 == "sig" && NR == 2 {print substr($6,2,16)}')}"

# Overwrite sensible variables with random data
ECRYPTFS_PASSPHRASE="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"
PASSPHRASE="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"

if [ ! -f "${HOME}/.ecryptfs/${ALIAS}.conf" ]; then
  printf "%s %s ecryptfs\n" "${LOWER_DIR}" "${UPPER_DIR}" > "${HOME}/.ecryptfs/${ALIAS}.conf"
fi

if [ ! -f "${HOME}/.ecryptfs/${ALIAS}.sig" ]; then
  printf "%s\n" "${SIG}" > "${HOME}/.ecryptfs/${ALIAS}.sig"
  printf "%s\n" "${FNEK_SIG}" >> "${HOME}/.ecryptfs/${ALIAS}.sig"
else
  grep "${SIG}" "${HOME}/.ecryptfs/${ALIAS}.sig" >/dev/null
  grep "${FNEK_SIG}" "${HOME}/.ecryptfs/${ALIAS}.sig" >/dev/null
fi

/sbin/mount.ecryptfs_private "${ALIAS}"
