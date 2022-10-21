#!/usr/bin/env sh
set -euo errexit

[ -n "${DEBUG:-}" -a "${DEBUG:-}" != "false" ] && set -x

case "${1:-start}" in

  start)
    exec /usr/sbin/crond -f -L/dev/stdout
  ;;

  *)
    exec /usr/local/bin/certbot "$@"
  ;;

esac
