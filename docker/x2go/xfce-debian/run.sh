#!/bin/sh
### every exit != 0 fails the script
set -eu

if [ ! -f /app/.setup_done ]; then
  /app/setup.sh
  /app/setup_locales.sh
  /app/setup_sshd.sh
  /app/setup_timezone.sh
fi

# /home is mounted in RAM and does not survive on restart
/app/setup_ecryptfs.sh
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
# prevent fail2ban to fail restarting
rm -f /var/run/fail2ban/fail2ban.sock
# Start fail2ban (for security reasons)
service fail2ban start

cleanup() {
  /bin/umount -fl /home
  service dbus stop
  service fail2ban stop
  service rsyslog stop
  service ssh stop
  kill $PID 2>/dev/null
  exit
}

trap "cleanup" INT TERM

if [ $# -eq 0 ]; then
  exec tail -f /dev/null &
  PID=$! && wait
else
  # WARNING: cleanup is not called
  exec /bin/bash -c "set -e && $@"
fi
cleanup
