#shellcheck shell=sh
# shellcheck disable=SC1090  # hooks are sourced by a path built at run time
# hooks: the per-stack settings that used to live in a .mk file.
#
# A stack directory may ship, next to its compose files:
#   _stack.env       settings shared by every stack of the directory
#   _stack.sh        the same, computed
#   <name>.env       settings of one stack
#   <name>.env.<env> the same, for one environment
#   <name>.sh        computed settings of one stack
#   <name>.mk        the legacy make snippet, still read for its groups
#
# A .sh hook declares lazy defaults (see lib/var.sh): functions named
# myos_default_<VARIABLE>, called only when the variable has no value and
# called again at each reference. That is a make `?=` on a recursive variable,
# and it is what lets a stack of the catalogue work without make installed.
#
# The _stack hooks of every directory between the stack path root and the stack
# itself are loaded, outermost first: make included both $(dir)/*.mk and
# $(dir)/*/*.mk, so a stack in a subdirectory saw its parent's settings.

# myos_stack_hooks DIR NAME  load the hooks that apply to one stack
myos_stack_hooks() {
  _hdir=$1; _hname=$2

  # the stack path entry this directory belongs to
  _root=
  _IFS=$IFS; IFS=:
  for _r in $(myos_path); do
    IFS=$_IFS
    case $_hdir in "$_r"|"$_r"/*) _root=$_r; break ;; esac
    IFS=:
  done
  IFS=$_IFS

  # every directory from the root down to the stack, outermost first
  _chain=$_hdir
  if [ -n "$_root" ]; then
    _d=$_hdir
    while [ "$_d" != "$_root" ] && [ "$_d" != "/" ] && [ -n "$_d" ]; do
      _d=$(dirname "$_d")
      _chain="$_d
$_chain"
    done
  fi

  for _d in $_chain; do
    myos_hook_load "$_d/_stack.env" dotenv
    myos_hook_load "$_d/_stack.sh" shell
  done
  myos_hook_load "$_hdir/$_hname.env" dotenv
  myos_hook_load "$_hdir/$_hname.env.$ENV" dotenv
  myos_hook_load "$_hdir/$_hname.sh" shell
  myos_hook_load "$_hdir/$_hname.$ENV.sh" shell
  return 0
}

# myos_hook_load FILE KIND
myos_hook_load() {
  [ -f "$1" ] || return 0
  myos_debug "hook $1"
  # a hook may need to read a file it ships next to itself
  # shellcheck disable=SC2034  # read by the hooks sourced below
  MYOS_STACK_DIR=$(dirname "$1")
  case $2 in
    dotenv) myos_dotenv_load "$1" ;;
    shell)  . "$1" ;;
  esac
}
