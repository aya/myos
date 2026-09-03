#shellcheck shell=sh
# shellcheck source=lib/cmd/_compose.sh
# myos scale <stack> SERVICE=<name> NUM=<n>   run n containers of a service
. "$MYOS_ROOT/lib/cmd/_compose.sh"

myos_cmd_scale() {
  _ref=$(printf '%s' "$MYOS_STACKS" | head -1)
  [ -n "$_ref" ] || myos_die "$MYOS_E_USAGE" "usage: myos scale <stack> SERVICE=name NUM=n"
  _service=${SERVICE:-$(myos_stack_name "$_ref")}
  [ -n "${NUM:-}" ] || myos_die "$MYOS_E_USAGE" "myos scale needs NUM=<n>"
  MYOS_ARGS="--scale $_service=$NUM ${MYOS_ARGS:-}"
  myos_cmd_compose up
}
