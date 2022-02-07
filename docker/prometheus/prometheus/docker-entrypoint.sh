#!/bin/ash
set -euo pipefail
set -o errexit
set -x

trap 'kill -SIGQUIT $PID' INT

# Launch alertmanager by default, or paramater
[ $# -eq 0 ] && /bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --storage.tsdb.no-lockfile || exec "$@" &
PID=$! && wait

