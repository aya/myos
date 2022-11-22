#!/bin/sh
[ -n "${DEBUG}" ] && set -x
set -eu

user=${1:-${USER}}
domain=${USER/*@}

[ -f "/home/${user}/.ssh/authorized_keys" ] \
 && authorized_keys=$(cat "/home/${user}/.ssh/authorized_keys" 2>/dev/null)
if [ -n "${authorized_keys:-}" ]; then
  echo "${authorized_keys:-}"
elif [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
    for host in ${SSH_AUTHORIZED_KEYS:-}; do
      wget -qO - "${host}" 2>/dev/null && break
    done
elif [ -n "${user}" ]; then
  # if no domain
  if [ "${domain}" = "${user}" ]; then
    for host in ${SSH_PUBLIC_HOSTS:-}; do
      wget -qO - "https://${host}/${user}.keys" 2>/dev/null && break
    done
  else
    exit 1
  fi
fi
