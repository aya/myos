#!/bin/sh
set -eu

CIPHER="${ECRYPTFS_CIPHER:-aes}"
KEY_BYTES="${ECRYPTFS_KEY_BYTES:-32}"
LOWER_DIR="${ECRYPTFS_LOWER_DIR:-/home}"
UPPER_DIR="${ECRYPTFS_UPPER_DIR:-${LOWER_DIR}}"
ALIAS="${ECRYPTFS_ALIAS:-${LOWER_DIR##*/}}"
PASSPHRASE="${ECRYPTFS_PASSPHRASE:-$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)}"
KEY="${ECRYPTFS_KEY:-passphrase:passphrase_passwd=${PASSPHRASE}}"
SIG="${ECRYPTFS_SIG:-$(printf "%s" "${PASSPHRASE}" |/usr/bin/ecryptfs-add-passphrase - |/usr/bin/awk '$5 == "sig" {print substr($6,2,16); exit;}')}"
FNEK_SIG="${ECRYPTFS_FNEK_SIG:-$(printf "%s" "${PASSPHRASE}" |/usr/bin/ecryptfs-add-passphrase --fnek - |/usr/bin/awk '$5 == "sig" && NR == 2 {print substr($6,2,16)}')}"

mkdir -p ${LOWER_DIR} ${UPPER_DIR} ${HOME}/.ecryptfs
printf "%s\n" "${LOWER_DIR} ${UPPER_DIR} ecryptfs" > ${HOME}/.ecryptfs/${ALIAS}.conf
printf "%s\n" "${SIG}" > ${HOME}/.ecryptfs/${ALIAS}.sig
printf "%s\n" "${FNEK_SIG}" >> ${HOME}/.ecryptfs/${ALIAS}.sig
# mount.ecryptfs_private ${ALIAS}

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
ECRYPTFS_PASSPHRASE="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"
PASSPHRASE="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"
