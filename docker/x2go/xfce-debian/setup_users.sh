#!/bin/sh
set -eu

for user in ${USERS:-${USERNAME}}; do
  id ${user} > /dev/null 2>&1 || useradd -ms /bin/bash ${user}
  usermod -a -G x2gouser ${user}
  mkdir -p /home/${user}/.ssh
  wget -qO /home/${user}/.ssh/authorized_keys https://github.com/${user}.keys
  chown -R ${user} /home/${user}/.ssh
done
for sudoer in ${SUDOERS:-}; do
  usermod -a -G sudo ${sudoer}
done
mkdir -p /home/shared && chmod 1777 /home/shared
