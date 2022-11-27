#!/bin/sh
[ -n "${DEBUG}" ] && set -x
set -eu

for user in ${USERS:-${USER:-user}}; do
  id "${user}" > /dev/null 2>&1 || useradd -s /bin/bash "${user}"
  [ ! -d "/home/${user}" ] \
   && mkdir -p "/home/${user}" \
   && chown "${user}" "/home/${user}" \
   && chmod 0750 "/home/${user}"
  for file in .aliases .bash_aliases .bash_profile .bashrc .dircolors_aliases .docker_aliases .profile .sh_aliases .sh_profile .shrc; do \
    [ -f "/etc/skel/${file}" ] && [ ! -f "/home/${user}/${file}" ] \
     && cp "/etc/skel/${file}" "/home/${user}" \
     && chown "${user}" "/home/${user}/${file}"
  done
  usermod -a -G docker   "${user}"
  usermod -a -G x2gouser "${user}"
  mkdir -p "/home/${user}/.ssh"
  keys=$(su "${user}" /app/authorized_keys.sh 2>/dev/null) \
   && echo "${keys}" > "/home/${user}/.ssh/authorized_keys" \
   || echo "WARNING: Unable to fetch authorized keys for ssh user ${user}."
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
cp /app/setup_ecryptfs_sshagent.sh /etc/profile.d/
mkdir -p /shared && chmod 1777 /shared
