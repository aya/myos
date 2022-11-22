#!/bin/sh
[ -n "${DEBUG}" ] && set -x
set -eu

sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "s/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/g" /etc/ssh/sshd_config
sed -i "s/^#\?PermitTTY.*/PermitTTY no/g" /etc/ssh/sshd_config
sed -i "s/^#\?PermitTunnel.*/PermitTunnel no/g" /etc/ssh/sshd_config
sed -i "s/^#\?PermitUserEnvironment.*/PermitUserEnvironment no/g" /etc/ssh/sshd_config
sed -i "s/^#\?PrintLastLog.*/PrintLastLog yes/g" /etc/ssh/sshd_config
sed -i "s/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#\?X11Forwarding.*/X11Forwarding no/g" /etc/ssh/sshd_config
sed -i "s/^#\?Port.*/Port ${SSH_PORT:-22}/g" /etc/ssh/sshd_config

cat >> /etc/ssh/sshd_config <<EOF
Match group x2gouser
  AllowAgentForwarding yes
  AllowTcpForwarding yes
  PermitTTY yes
EOF
