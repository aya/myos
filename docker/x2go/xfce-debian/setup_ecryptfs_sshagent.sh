#!/bin/sh
[ -n "${DEBUG}" ] && set -x

# if auto-mount ecryptfs
if [ -f "${HOME}/.ecryptfs/auto-mount" ]; then

  LOWER_DIR="${1:-${ECRYPTFS_LOWER_DIR:-${HOME}/Secure}}"
  UPPER_DIR="${ECRYPTFS_UPPER_DIR:-${LOWER_DIR}}"
  ALIAS="${ECRYPTFS_ALIAS:-${LOWER_DIR##*/}}"

  # if not already mounted
  if ! grep -q "${LOWER_DIR} ${UPPER_DIR} ecryptfs " /proc/mounts 2>/dev/null; then

    # create mount point
    mkdir -p "${LOWER_DIR}" "${UPPER_DIR}"

    # we should always use the same key when multiple keys are loaded in ssh-agent
    if [ -f "${HOME}/.ecryptfs/${ALIAS}.key" ]; then
      ssh_key_fingerprint=$(cat "${HOME}/.ecryptfs/${ALIAS}.key")
    # first time, select the first key and write fingerprint to file
    else
      ssh_key_fingerprint=$(/usr/bin/ssh-add -l 2>/dev/null |awk '{print $2; exit;}')
      [ -n "${ssh_key_fingerprint}" ] && printf "%s\n" "${ssh_key_fingerprint}" > "${HOME}/.ecryptfs/${ALIAS}.key"
    fi

    # select ssh key name matching fingerprint
    ssh_key=$(/usr/bin/ssh-add -l 2>/dev/null |awk '$2 == "'"${ssh_key_fingerprint:-undef}"'" {print $3}')
    # if ssh key
    if [ -n "${ssh_key}" ]; then
      # decrypt encrypted passphrase
      if [ -f "${HOME}/.ecryptfs/${ALIAS}.ssh" ]; then
        PASSPHRASE=$(/usr/local/bin/ssh-crypt -b -d -k "${ssh_key}" -i "${HOME}/.ecryptfs/${ALIAS}.ssh")
      # first time, generate random passphrase and write encrypted passphrase to file
      else
        PASSPHRASE="${ECRYPTFS_PASSPHRASE:-$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)}"
        printf "%s" "${PASSPHRASE}" |/usr/local/bin/ssh-crypt -b -e -k "${ssh_key}" -o "${HOME}/.ecryptfs/${ALIAS}.ssh"
      fi
      # load authentication token signature (fekek)
      SIG="${ECRYPTFS_SIG:-$(printf "%s" "${PASSPHRASE}" |/usr/bin/ecryptfs-add-passphrase - |/usr/bin/awk '$5 == "sig" {print substr($6,2,16); exit;}')}"
      # load filename authentication token signature (fnek)
      FNEK_SIG="${ECRYPTFS_FNEK_SIG:-$(printf "%s" "${PASSPHRASE}" |/usr/bin/ecryptfs-add-passphrase --fnek - |/usr/bin/awk '$5 == "sig" && NR == 2 {print substr($6,2,16)}')}"

      # Overwrite sensible variables with random data
      ECRYPTFS_PASSPHRASE="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"
      PASSPHRASE="$(/usr/bin/base64 /dev/urandom |/usr/bin/head -c 64)"

      # first time, write ecryptfs_private config to file
      if [ ! -f "${HOME}/.ecryptfs/${ALIAS}.conf" ]; then
        printf "%s %s ecryptfs\n" "${LOWER_DIR}" "${UPPER_DIR}" > "${HOME}/.ecryptfs/${ALIAS}.conf"
      fi

      # first time, write authentication token signatures to file
      if [ ! -f "${HOME}/.ecryptfs/${ALIAS}.sig" ]; then
        printf "%s\n" "${SIG}" > "${HOME}/.ecryptfs/${ALIAS}.sig"
        printf "%s\n" "${FNEK_SIG}" >> "${HOME}/.ecryptfs/${ALIAS}.sig"
        # mount ecryptfs
        /sbin/mount.ecryptfs_private "${ALIAS}"
      else
        # check authentication tokens to prevent mounting with bad ones
        if grep "${SIG}" "${HOME}/.ecryptfs/${ALIAS}.sig" >/dev/null \
         && grep "${FNEK_SIG}" "${HOME}/.ecryptfs/${ALIAS}.sig" >/dev/null; then
          # mount ecryptfs
          /sbin/mount.ecryptfs_private "${ALIAS}"
        fi
      fi

    else
      echo "WARNING: Unable to find ssh key ${ssh_key} in ssh agent ${SSH_AUTH_SOCK}"
    # if ssh key
    fi
  # if not already mounted
  fi
# if auto-mount ecryptfs
fi
