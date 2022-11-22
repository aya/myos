#!/bin/sh
[ -n "${DEBUG}" ] && set -x
### every exit != 0 fails the script
set -eu

if [ ! -f /app/.setup_done ]; then
  /app/setup.sh
  /app/setup_locales.sh
  /app/setup_sshd.sh
  /app/setup_timezone.sh
fi

/app/setup_ecryptfs.sh /dev/shm &
/app/setup_users.sh

## Start-up our services manually (since Docker container will not invoke all init scripts).
## However, some service do start automatically, when placed and NOT-hidden in: /etc/xdg/autostart folder.

# Start SSH daemon
service ssh start
# Start dbus system daemon
service dbus start
# Start syslog (for debugging reasons)
service rsyslog start
# prevent fail2ban to fail starting
touch /var/log/auth.log
# prevent tail -f to fail starting
touch /var/log/pam-script.log
# prevent fail2ban to fail restarting
rm -f /var/run/fail2ban/fail2ban.sock
# Start fail2ban (for security reasons)
service fail2ban start

cleanup() {
  /bin/umount -fl /home ||:
  service dbus stop
  service fail2ban stop
  service rsyslog stop
  service ssh stop
  kill "$PID" 2>/dev/null
  exit
}

trap "cleanup" INT TERM

if [ $# -eq 0 ]; then
  exec tail -f /var/log/fail2ban.log /var/log/syslog /var/log/auth.log /var/log/pam-script.log &
  PID=$! && wait
else
  # WARNING: cleanup is not called
  exec su ${USER:-root} /bin/bash -c "set -e && $*"
fi
cleanup
