#!/bin/ash
set -euo pipefail
set -o errexit

trap 'kill -SIGQUIT $PID' INT

# Launch pdns_recursor by default
[ $# -eq 0 ] && /usr/local/sbin/pdns_recursor || exec "$@" &
PID=$! && wait
