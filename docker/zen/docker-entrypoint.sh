#!/usr/bin/env sh
set -euo errexit

# Print a debug message if debug mode is on ($DEBUG is not empty)
# @param message
debug_msg ()
{
  if [ -n "${DEBUG:-}" -a "${DEBUG:-}" != "false" ]; then
    echo "$@"
  fi
}

# Install astrXbian/Astroport.ONE
/install.sh

case "${1:-start}" in

  start)
    debug_msg "Starting..."
    exec sudo /usr/sbin/cron -f -L/dev/stdout
  ;;

  install)
    debug_msg "Installing..."
    exec /install.sh
  ;;

  *)
    debug_msg "Exec: $@"
    exec "$@"
  ;;

esac
