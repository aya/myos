#shellcheck shell=sh
# shellcheck disable=SC3028  # HOSTNAME is a myos variable, set by bin/myos
# myos doctor  check that this installation can actually run a stack
myos_cmd_doctor() {
  _rc=0
  _ok()   { printf '  %-28s %s\n' "$1" "$2"; }
  _bad()  { printf '  %-28s %s%s%s\n' "$1" "$MYOS_C_ERROR" "$2" "$MYOS_C_RESET"; _rc=$MYOS_E_NOREQ; }

  printf 'myos %s at %s\n' "$MYOS_VERSION" "$MYOS_ROOT"
  printf 'requirements:\n'
  if myos_have docker; then _ok docker "$(docker version --format '{{.Client.Version}}' 2>/dev/null || echo present)"
  else _bad docker "not found"; fi
  if _c=$(myos_compose_bin 2>/dev/null); then _ok "compose" "$_c"; else _bad compose "docker compose >= $MYOS_COMPOSE_MIN_VERSION not found"; fi
  if [ "${DRYRUN:-false}" != true ]; then
    if docker info >/dev/null 2>&1; then _ok "docker daemon" "reachable${DOCKER_HOST:+ via $DOCKER_HOST}"
    else _bad "docker daemon" "unreachable${DOCKER_HOST:+ ($DOCKER_HOST)}"; fi
  fi

  printf 'configuration:\n'
  for _f in $(myos_conf_files); do _ok "$_f" "read"; done
  [ -f "${HOME:-}/.config/myos/config" ] && _ok "${HOME:-}/.config/myos/config" "read"
  [ -f "$WORKDIR/.env" ] && _ok "$WORKDIR/.env" "read"
  _ok ENV "$ENV"
  _ok USER "$USER"
  _ok HOSTNAME "$HOSTNAME"
  _ok DOMAIN "$DOMAIN"
  _ok "project format" "${MYOS_PROJECT_FORMAT:-user-env-app}"

  printf 'stacks:\n'
  _p=$(myos_path)
  if [ -n "$_p" ]; then printf '%s\n' "$_p" | tr ':' '\n' | sed 's/^/  /'
  else _bad "stack path" "empty"; fi

  # a .env written for the make engine can hold values the shell reads differently
  if [ -f "$WORKDIR/.env" ] && grep -qE '\$\(|\$\{[a-z]' "$WORKDIR/.env"; then
    printf '  %-28s %s%s%s\n' "$WORKDIR/.env" "$MYOS_C_WARN" "contains make expansions" "$MYOS_C_RESET"
  fi
  return "$_rc"
}
