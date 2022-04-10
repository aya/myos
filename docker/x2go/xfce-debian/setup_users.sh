#!/bin/sh
[ -n "${DEBUG}" ] && set -x
set -eu

for user in ${USERS:-${USERNAME}}; do
  id "${user}" > /dev/null 2>&1 || useradd -s /bin/bash "${user}"
  [ ! -d "/home/${user}" ] \
   && mkdir -p "/home/${user}" \
   && chown "${user}" "/home/${user}" \
   && chmod 0750 "/home/${user}"
  for file in .bash_logout .bashrc .profile; do
    [ ! -f "/home/${user}/${file}" ] \
     && cp "/etc/skel/${file}" "/home/${user}" \
     && chown "${user}" "/home/${user}/${file}"
  done
  usermod -a -G x2gouser "${user}"
  mkdir -p "/home/${user}/.ssh"
  wget -qO "/home/${user}/.ssh/authorized_keys" "https://gitlab.com/${user}.keys" 2>/dev/null \
   || wget -qO "/home/${user}/.ssh/authorized_keys" "https://github.com/${user}.keys" 2>/dev/null \
   || echo "WARNING: Unable to fetch ssh public keys for user ${user}."
  chown "${user}" "/home/${user}/.ssh" "/home/${user}/.ssh/authorized_keys"
done
for sudoer in ${SUDOERS:-}; do
  usermod -a -G sudo "${sudoer}"
done
for ecrypter in ${ECRYPTERS:-}; do
  mkdir -p "/home/${ecrypter}/.ecryptfs"
  touch "/home/${ecrypter}/.ecryptfs/auto-mount"
  touch "/home/${ecrypter}/.ecryptfs/auto-umount"
  chown -R "${ecrypter}" "/home/${ecrypter}/.ecryptfs"
done
ln -s /app/setup_ecryptfs_sshagent.sh /etc/profile.d/
mkdir -p /shared && chmod 1777 /shared
