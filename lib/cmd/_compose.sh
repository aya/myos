#shellcheck shell=sh
# shellcheck disable=SC3028  # HOSTNAME is a myos variable, set by bin/myos
# The commands that map straight onto docker compose.
#
# Stacks are grouped by compose project: every host stack shares the project of
# the machine, so `myos up host` is a single compose call with every file, the
# way the stack was meant to be described.

# myos_cmd_compose COMMAND
myos_cmd_compose() {
  _cmd=$1
  _projects=
  _rc=0

  for _ref in $MYOS_STACKS; do
    _files=$(myos_stack_compose_files "$_ref") || { _rc=$MYOS_E_NOSTACK; continue; }
    [ -n "$_files" ] || { myos_warning "no compose file for stack $_ref"; continue; }
    _scope=$(myos_scope "$_ref")
    _app=$(myos_stack_name "$_ref")
    case $_ref in .|./*|/*|../*) _app=$(basename "$(myos_stack_resolve "$_ref")") ;; esac
    _project=$(myos_project_name "$_scope" "$USER" "$ENV" "$_app")
    # accumulate the files of every stack sharing a project, keeping the order
    _projects=$(printf '%s\n%s\t%s' "$_projects" "$_project" "$(printf '%s' "$_files" | tr '\n' ' ')")
  done

  [ "$_rc" = 0 ] || return "$_rc"

  for _project in $(printf '%s' "$_projects" | sed '/^$/d' | cut -f1 | awk '!seen[$0]++'); do
    _files=$(printf '%s' "$_projects" | sed '/^$/d' | awk -F'\t' -v p="$_project" '$1==p {print $2}' | tr ' ' '\n' | sed '/^$/d' | awk '!seen[$0]++')
    # the framework overlays always come last, as the make engine did
    _fw=$(myos_framework_compose_files)
    [ -n "$_fw" ] && _files="$_files
$_fw"

    COMPOSE_PROJECT_NAME=$_project
    COMPOSE_SERVICE_NAME=$(myos_service_name "$_project")
    DOCKER_NETWORK_DEFAULT=${DOCKER_NETWORK_DEFAULT:-$(myos_network_default "$_project")}
    DOCKER_NETWORK_PRIVATE=$(myos_network_private "$USER" "$ENV")
    # shellcheck disable=SC3028  # HOSTNAME is set by bin/myos, not by the shell
    DOCKER_NETWORK_PUBLIC=$(myos_network_public "$HOSTNAME")
    export COMPOSE_PROJECT_NAME COMPOSE_SERVICE_NAME
    export DOCKER_NETWORK_DEFAULT DOCKER_NETWORK_PRIVATE DOCKER_NETWORK_PUBLIC

    case $_cmd in
      up) myos_network_ensure "$DOCKER_NETWORK_PRIVATE" "$DOCKER_NETWORK_PUBLIC" ;;
    esac

    # shellcheck disable=SC2086,SC2046  # options and MYOS_ARGS are word lists
    myos_compose "$_project" "$_files" -- "$_cmd" $(myos_compose_options "$_cmd") ${MYOS_ARGS:-} || _rc=$?
  done
  return "$_rc"
}

# myos_compose_options COMMAND  the default options of each compose command
myos_compose_options() {
  case $1 in
    up)   printf '%s' "${DOCKER_COMPOSE_UP_OPTIONS:--d}" ;;
    logs) printf '%s' "${DOCKER_COMPOSE_LOGS_OPTIONS:---follow --tail=100}" ;;
    down) printf '%s' "${DOCKER_COMPOSE_DOWN_OPTIONS:-}" ;;
    *)    printf '' ;;
  esac
}

# myos_network_ensure NAME...  create the external networks if they are missing
myos_network_ensure() {
  for _n in "$@"; do
    [ -n "$_n" ] || continue
    if [ "${DRYRUN:-false}" = true ]; then
      printf 'docker network create %s\n' "$_n"
    else
      docker network inspect "$_n" >/dev/null 2>&1 || myos_run docker network create "$_n" >/dev/null
    fi
  done
  return 0
}
