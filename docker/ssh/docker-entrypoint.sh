#!/usr/bin/env sh
set -euo pipefail
set -o errexit

# Print a debug message if debug mode is on ($DEBUG is not empty)
# @param message
debug_msg ()
{
  if [ -n "${DEBUG:-}" -a "${DEBUG:-}" != "false" ]; then
    echo "$@"
  fi
}

case "$1" in
  # Start ssh-agent
  ssh-agent)

    # Create proxy-socket for ssh-agent (to give everyone access to the ssh-agent socket)
    debug_msg "Create proxy socket..."
    rm -f ${SSH_AUTH_SOCK} ${SSH_AUTH_PROXY_SOCK} > /dev/null 2>&1
    socat UNIX-LISTEN:${SSH_AUTH_PROXY_SOCK},perm=0666,fork UNIX-CONNECT:${SSH_AUTH_SOCK} &

    debug_msg "Launch ssh-agent..."
    exec /usr/bin/ssh-agent -a ${SSH_AUTH_SOCK} -D >/dev/null
  ;;

  *)
    debug_msg "Exec: $@"
    exec $@
  ;;
esac
