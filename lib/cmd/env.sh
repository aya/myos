#shellcheck shell=sh
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
      *)                    printf '%s %s\n' "$_v" "$(myos_var "$_v")" ;;
    esac
  done
}

# myos_all_compose_files  every compose file of every requested stack, in order
myos_all_compose_files() {
  for _ref in $MYOS_STACKS; do
    myos_stack_compose_files "$_ref" 2>/dev/null
  done
  [ -f "$MYOS_ROOT/share/compose/networks.yml" ] && printf '%s\n' "$MYOS_ROOT/share/compose/networks.yml"
  return 0
}

# myos_first_project  the compose project of the first requested stack
myos_first_project() {
  for _ref in $MYOS_STACKS; do
    _app=$(myos_stack_name "$_ref")
    case $_ref in .|./*|/*|../*) _app=$(basename "$(myos_stack_resolve "$_ref" 2>/dev/null)") ;; esac
    myos_project_name "$(myos_scope "$_ref")" "$USER" "$ENV" "$_app"
    return 0
  done
}
