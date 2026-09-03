#shellcheck shell=sh
# shellcheck disable=SC3028  # HOSTNAME is a myos variable, set by bin/myos
# myos env [VAR...]  show resolved variables (replaces the make print-VAR target)

# myos_env_print NAME VALUE
# Same shape as the make print-<VAR> target: the name padded to 37 columns in
# the highlight colour, then the value in the value colour.
myos_env_print() {
  printf '%s%-37s%s%s%s%s\n' \
    "$MYOS_C_HIGHLIGHT" "$1" "$MYOS_C_RESET" "$MYOS_C_VALUE" "$2" "$MYOS_C_RESET"
}

myos_cmd_env() {
  _vars=${MYOS_VARS:-}
  [ -n "$_vars" ] || _vars=$MYOS_ARGS
  [ -n "$_vars" ] || _vars=$MYOS_REFS_RAW
  if [ -z "$_vars" ]; then
    _vars="ENV USER HOSTNAME DOMAIN WORKDIR MYOS_PATH SCOPE STACK COMPOSE_PROJECT_NAME COMPOSE_FILE"
  fi
  for _v in $_vars; do
    case $_v in
      MYOS_PATH)              myos_env_print "$_v" "$(myos_path)" ;;
      COMPOSE_FILE)           myos_env_print "$_v" "$(myos_all_compose_files | tr '\n' ' ' | sed 's/ $//')" ;;
      COMPOSE_PROJECT_NAME)   myos_env_print "$_v" "$(myos_first_project)" ;;
      COMPOSE_SERVICE_NAME)   myos_env_print "$_v" "$(myos_service_name "$(myos_first_project)")" ;;
      COMPOSE_FILE_SUFFIX)    myos_env_print "$_v" "$(myos_compose_suffixes)" ;;
      STACK)                  myos_env_print "$_v" "$(printf '%s' "$MYOS_STACKS" | tr '\n' ' ' | sed 's/ $//')" ;;
      SCOPE)                  myos_env_print "$_v" "$(myos_first_scope)" ;;
      APP|APP_NAME)           myos_env_print "$_v" "$(myos_first_app)" ;;
      DOCKER_REPOSITORY)      myos_env_print "$_v" "$(printf '%s' "$(myos_first_project)" | tr '_-' '//')" ;;
      DOCKER_NETWORK_DEFAULT) myos_env_print "$_v" "$(myos_network_default "$(myos_first_project)")" ;;
      DOCKER_NETWORK_PRIVATE) myos_env_print "$_v" "$(myos_network_private "$USER" "$ENV")" ;;
      DOCKER_NETWORK_PUBLIC)  myos_env_print "$_v" "$(myos_network_public "${HOSTNAME:-}")" ;;
      DOCKER_NETWORK)
        if [ "$(myos_first_scope)" = user ]; then myos_env_print "$_v" "$USER"
        else myos_env_print "$_v" "$(myos_network_private "$USER" "$ENV")"; fi ;;
      # HOST_STACK and USER_STACK are what the make engine called the scope
      HOST_STACK)
        if [ "$(myos_first_scope)" = host ]; then myos_env_print "$_v" host
        else myos_env_print "$_v" ""; fi ;;
      USER_STACK)
        if [ "$(myos_first_scope)" = user ]; then myos_env_print "$_v" User
        else myos_env_print "$_v" ""; fi ;;
      *)                      myos_env_print "$_v" "$(myos_var "$_v")" ;;
    esac
  done
}

