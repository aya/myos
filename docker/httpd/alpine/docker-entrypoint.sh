#!/bin/sh
set -euo pipefail
set -o errexit

trap 'kill -SIGQUIT $PID' INT

# Launch httpd
[ $# -eq 0 ] && httpd-foreground || exec "$@" &
PID=$! && wait
