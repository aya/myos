#!/bin/sh
[ -n "${DEBUG}" ] && set -x
set -eu

CIPHER="${ECRYPTFS_CIPHER:-aes}"
KEY_BYTES="${ECRYPTFS_KEY_BYTES:-16}"
LOWER_DIR="${1:-${ECRYPTFS_LOWER_DIR:-/home}}"
UPPER_DIR="${ECRYPTFS_UPPER_DIR:-${LOWER_DIR}}"
PASSPHRASE="${ECRYPTFS_PASSPHRASE:-$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)}"
KEY="${ECRYPTFS_KEY:-passphrase:passphrase_passwd=${PASSPHRASE}}"
FNEK_SIG="${ECRYPTFS_FNEK_SIG:-$(printf "%s" "${PASSPHRASE}" |/usr/bin/ecryptfs-add-passphrase --fnek - |/usr/bin/awk '$5 == "sig" && NR == 2 {print substr($6,2,16)}')}"

# ecryptfs already mounted ?
grep -q "${LOWER_DIR} ${UPPER_DIR} ecryptfs " /proc/mounts 2>/dev/null && break

mkdir -p "${LOWER_DIR}" "${UPPER_DIR}"

/bin/mount -t ecryptfs -o \
key="${KEY}",\
no_sig_cache,\
ecryptfs_cipher="${CIPHER}",\
ecryptfs_enable_filename=y,\
ecryptfs_enable_filename_crypto=y,\
ecryptfs_fnek_sig="${FNEK_SIG}",\
ecryptfs_key_bytes="${KEY_BYTES}",\
ecryptfs_passthrough=n,\
ecryptfs_unlink_sigs\
 "${LOWER_DIR}" "${UPPER_DIR}" 1>/dev/null

# Overwrite sensible variables with random data
ECRYPTFS_KEY="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"
ECRYPTFS_PASSPHRASE="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"
KEY="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"
PASSPHRASE="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"
