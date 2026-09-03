#shellcheck shell=sh
# shellcheck disable=SC3028  # HOSTNAME is a myos variable, set by bin/myos
# context: what the requested stacks resolve to, and the framework variables a
# stack hook may read.
#
# A hook is written the way a .mk was: it may mention COMPOSE_PROJECT_NAME,
# USER or DOMAIN and expect the framework value. Those are registered as lazy
# defaults, so each is computed when read and an explicit value still wins.

# myos_all_compose_files  every compose file of every requested stack, in order
myos_all_compose_files() {
  for _ref in $MYOS_STACKS; do
    myos_stack_compose_files "$_ref" 2>/dev/null
  done
  myos_framework_compose_files
  return 0
}

# myos_first_app / myos_first_scope / myos_first_project
# describe the first requested stack, which is what the introspection commands
# report when several stacks are asked for at once.
myos_first_app() {
  for _ref in $MYOS_STACKS; do
    case $_ref in
      .|./*|/*|../*) basename "$(myos_stack_resolve "$_ref" 2>/dev/null)" ;;
      *) myos_stack_name "$_ref" ;;
    esac
    return 0
  done
}

myos_first_scope() {
  for _ref in $MYOS_STACKS; do myos_scope "$_ref"; return 0; done
}

myos_first_project() {
  for _ref in $MYOS_STACKS; do
    myos_project_name "$(myos_scope "$_ref")" "$USER" "$ENV" "$(myos_first_app)"
    return 0
  done
}

# myos_context_defaults  register the framework variables as lazy defaults
# shellcheck disable=SC2329  # these are reached through myos_var
myos_context_defaults() {
  myos_default_APP()                       { myos_first_app; }
  myos_default_APP_NAME()                  { myos_name "$(myos_first_app)"; }
  myos_default_SCOPE()                     { myos_first_scope; }
  myos_default_COMPOSE_PROJECT_NAME()      { myos_first_project; }
  myos_default_COMPOSE_SERVICE_NAME()      { myos_service_name "$(myos_first_project)"; }
  myos_default_DOCKER_REPOSITORY()         { printf '%s' "$(myos_first_project)" | tr '_-' '//'; }
  myos_default_DOCKER_NETWORK_DEFAULT()    { myos_network_default "$(myos_first_project)"; }
  myos_default_DOCKER_NETWORK_PRIVATE()    { myos_network_private "$USER" "$ENV"; }
  myos_default_DOCKER_NETWORK_PUBLIC()     { myos_network_public "${HOSTNAME:-}"; }
  myos_default_DOCKER_NETWORK()            { myos_network_private "$USER" "$ENV"; }
  myos_default_DOCKER_IMAGE_TAG()          { printf 'latest'; }
  myos_default_GIT_USER()                  { printf '%s' "$USER"; }
  myos_default_HOST_COMPOSE_PROJECT_NAME() { printf '%s' "${HOSTNAME:-}"; }
  myos_default_HOST_DOCKER_VOLUME()        { printf '%s' "${HOSTNAME:-}"; }
  myos_default_HOST_DOCKER_REPOSITORY()    { printf '%s' "${HOSTNAME:-}" | tr '_-' '//'; }
  myos_default_USER_COMPOSE_PROJECT_NAME() { myos_resu "${MAIL:-}" | tr '.' '-'; }
  myos_default_RESU()                      { myos_resu "${MAIL:-}"; }
}
