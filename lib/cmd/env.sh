#shellcheck shell=sh
# shellcheck disable=SC3028  # HOSTNAME is a myos variable, set by bin/myos
# myos env [VAR...]  show resolved variables (replaces the make print-VAR target)
myos_cmd_env() {
  _vars=${MYOS_VARS:-}
  [ -n "$_vars" ] || _vars=$MYOS_ARGS
  [ -n "$_vars" ] || _vars=$MYOS_REFS_RAW
  if [ -z "$_vars" ]; then
    _vars="ENV USER HOSTNAME DOMAIN WORKDIR MYOS_PATH STACK COMPOSE_PROJECT_NAME COMPOSE_FILE"
  fi
  for _v in $_vars; do
    case $_v in
      MYOS_PATH)            printf '%s %s\n' "$_v" "$(myos_path)" ;;
      COMPOSE_FILE)         printf '%s %s\n' "$_v" "$(myos_all_compose_files | tr '\n' ' ' | sed 's/ $//')" ;;
      COMPOSE_PROJECT_NAME) printf '%s %s\n' "$_v" "$(myos_first_project)" ;;
      STACK)                printf '%s %s\n' "$_v" "$(printf '%s' "$MYOS_STACKS" | tr '\n' ' ' | sed 's/ $//')" ;;
      DOCKER_NETWORK_DEFAULT) printf '%s %s\n' "$_v" "$(myos_network_default "$(myos_first_project)")" ;;
      DOCKER_NETWORK_PRIVATE) printf '%s %s\n' "$_v" "$(myos_network_private "$USER" "$ENV")" ;;
      DOCKER_NETWORK_PUBLIC)  printf '%s %s\n' "$_v" "$(myos_network_public "${HOSTNAME:-}")" ;;
      COMPOSE_SERVICE_NAME)   printf '%s %s\n' "$_v" "$(myos_service_name "$(myos_first_project)")" ;;
      COMPOSE_FILE_SUFFIX)    printf '%s %s\n' "$_v" "$(myos_compose_suffixes)" ;;
      APP|APP_NAME)           printf '%s %s\n' "$_v" "$(myos_first_app)" ;;
      SCOPE)                  printf '%s %s\n' "$_v" "$(myos_first_scope)" ;;
      # HOST_STACK/USER_STACK are the names the make engine used for the scope
      HOST_STACK)             [ "$(myos_first_scope)" = host ] && printf '%s host\n' "$_v" || printf '%s\n' "$_v" ;;
      USER_STACK)             [ "$(myos_first_scope)" = user ] && printf '%s User\n' "$_v" || printf '%s\n' "$_v" ;;
      DOCKER_REPOSITORY)      printf '%s %s\n' "$_v" "$(printf '%s' "$(myos_first_project)" | tr '_-' '//')" ;;
      DOCKER_NETWORK)
        if [ "$(myos_first_scope)" = user ]; then printf '%s %s\n' "$_v" "$USER"
        else printf '%s %s\n' "$_v" "$(myos_network_private "$USER" "$ENV")"; fi ;;
      *)                    printf '%s %s\n' "$_v" "$(myos_var "$_v")" ;;
    esac
  done
}

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
