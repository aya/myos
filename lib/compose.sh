#shellcheck shell=sh
# compose: find a usable docker compose, and call it once per project.
#
# The legacy engine ran one `docker compose up` per sub-stack, each time with
# the full file list, so N sub-stacks meant N identical calls. The CLI calls
# compose once per project (documented in spec/golden/DELTAS.md).

MYOS_COMPOSE_MIN_VERSION=${COMPOSE_VERSION:-2.24.4}

# myos_compose_bin  print the compose command to use, fail with MYOS_E_NOREQ
myos_compose_bin() {
  [ -n "${MYOS_COMPOSE_BIN:-}" ] && { printf '%s' "$MYOS_COMPOSE_BIN"; return 0; }
  if myos_have docker; then
    _v=$(docker compose version --short 2>/dev/null)
    if myos_verle "$MYOS_COMPOSE_MIN_VERSION" "$_v"; then printf 'docker compose'; return 0; fi
  fi
  if myos_have docker-compose; then
    _v=$(docker-compose version --short 2>/dev/null)
    if myos_verle "$MYOS_COMPOSE_MIN_VERSION" "$_v"; then printf 'docker-compose'; return 0; fi
  fi
  myos_error "docker compose >= $MYOS_COMPOSE_MIN_VERSION not found (install the docker compose plugin or docker-compose)"
  return "$MYOS_E_NOREQ"
}

# myos_compose PROJECT FILES -- ARGS...
# FILES is a newline separated list; the project directory is that of the first
# file, so relative build contexts and env_file entries keep working.
myos_compose() {
  _project=$1; _files=$2; shift 2
  [ "${1:-}" = "--" ] && shift
  [ -n "$_files" ] || { myos_error "no compose file for project $_project"; return "$MYOS_E_NOSTACK"; }
  _bin=$(myos_compose_bin) || return $?

  _fargs=""
  _first=""
  for _f in $_files; do
    [ -n "$_first" ] || _first=$_f
    _fargs="$_fargs -f $_f"
  done
  _dir=$(dirname "$_first")

  # the variables the compose files reference, plus the network names: those
  # live in networks.yml, which is appended after the scan
  # shellcheck disable=SC2086  # both are deliberate word lists
  _vars=$(myos_env_vars $_files)
  # shellcheck disable=SC2086
  _envargs=$(myos_env_export $_vars DOCKER_NETWORK_DEFAULT DOCKER_NETWORK_PRIVATE DOCKER_NETWORK_PUBLIC COMPOSE_SERVICE_NAME)

  if [ "${DRYRUN:-false}" = true ]; then
    # shellcheck disable=SC2086  # printed, not executed
    printf '%s%s -p %s --project-directory %s %s\n' "$_bin" "$_fargs" "$_project" "$_dir" "$*"
    return 0
  fi

  # Export the variables in a subshell rather than through env(1): a value may
  # contain spaces, and the command line must still be split on spaces (the
  # compose binary can be the two words "docker compose").
  (
    while IFS= read -r _kv; do
      [ -n "$_kv" ] || continue
      # shellcheck disable=SC2163  # _kv is a NAME=value pair, not a name
      export "$_kv"
    done <<EOF
$_envargs
EOF
    # shellcheck disable=SC2086  # _bin and _fargs are deliberate word lists
    exec $_bin --ansi=auto $_fargs -p "$_project" --project-directory "$_dir" "$@"
  )
}
