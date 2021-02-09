#!/bin/sh
set -euo pipefail
set -o errexit

trap 'kill -SIGQUIT $PID' INT

CRON_DAILY_COMMAND="/usr/bin/curator --config /etc/curator/config.yml /etc/curator/action.yml"
[ "${DEPLOY:-}" = "true" ] && CRON_DAILY_COMMAND="cronlock ${CRON_DAILY_COMMAND}"

cat > /etc/periodic/daily/curator <<EOF
#!/bin/sh
${CRON_DAILY_COMMAND}
EOF
chmod +x /etc/periodic/daily/curator

[ $# -eq 0 ] && exec crond -f -L/dev/stdout || exec "$@" &
PID=$! && wait
