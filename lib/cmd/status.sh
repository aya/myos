#shellcheck shell=sh
# myos status  what is running, under the name the make engine used for ps
myos_cmd_status() {
  # shellcheck source=lib/cmd/_compose.sh
  . "$MYOS_ROOT/lib/cmd/_compose.sh"
  myos_cmd_compose ps
}
