#shellcheck shell=sh
# myos recreate  remove the containers and create them again
# myos reload    the same, under the name the make engine used
myos_cmd_recreate() {
  # shellcheck source=lib/cmd/_compose.sh
  . "$MYOS_ROOT/lib/cmd/_compose.sh"
  MYOS_ARGS="--force-recreate ${MYOS_ARGS:-}"
  myos_cmd_compose up
}
myos_cmd_reload() { myos_cmd_recreate; }
