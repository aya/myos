#shellcheck shell=sh
# myos exec <stack> [-- command...]   run a command in a running service
# myos run  <stack> [-- command...]   run it in a new container
#
# The service defaults to the stack name, which is what it is called in most
# stacks; SERVICE=<name> picks another one.
myos_cmd_exec() { myos_service_command exec; }
myos_cmd_run()  { myos_service_command run; }

myos_service_command() {
  _what=$1
  _ref=$(printf '%s' "$MYOS_STACKS" | head -1)
  [ -n "$_ref" ] || myos_die "$MYOS_E_USAGE" "usage: myos $_what <stack> [SERVICE=name] -- command..."
  _service=${SERVICE:-$(myos_stack_name "$_ref")}
  _files=$(myos_stack_compose_files "$_ref") || return $?
  _fw=$(myos_framework_compose_files)
  [ -n "$_fw" ] && _files="$_files
$_fw"
  _app=$(myos_stack_name "$_ref")
  case $_ref in .|./*|/*|../*) _app=$(basename "$(myos_stack_resolve "$_ref")") ;; esac
  _project=$(myos_project_name "$(myos_scope "$_ref")" "$USER" "$ENV" "$_app")
  case $_what in
    exec) _opts="" ;;
    run)  _opts=${DOCKER_COMPOSE_RUN_OPTIONS:---rm} ;;
  esac
  # shellcheck disable=SC2086  # options and arguments are deliberate word lists
  myos_compose "$_project" "$_files" -- "$_what" $_opts "$_service" ${MYOS_ARGS:-}
}
