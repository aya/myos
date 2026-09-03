#shellcheck shell=sh
# hooks: the per-stack settings that used to live in a .mk file.
#
# A stack may ship, next to its compose files:
#   _stack.env       settings shared by every stack of the directory
#   _stack.sh        the same, computed
#   <name>.env       dotenv, for plain values
#   <name>.env.<env> the same, for one environment
#   <name>.sh        shell, for values that have to be computed (fabio tags, JWTs)
#   <name>.mk        the legacy make snippet, still read for its groups
#
# A .sh hook runs with the myos helpers available (myos_tagprefix, myos_uri,
# myos_var) and sets variables directly. This is what lets a stack of the
# catalogue work on a machine that has no make.

# myos_stack_hooks DIR NAME  load the hooks of one stack, most specific last
myos_stack_hooks() {
  _hdir=$1; _hname=$2
  for _h in "$_hdir/_stack.env" "$_hdir/$_hname.env" "$_hdir/$_hname.env.$ENV"; do
    [ -f "$_h" ] && myos_dotenv_load "$_h"
  done
  for _h in "$_hdir/_stack.sh" "$_hdir/$_hname.sh" "$_hdir/$_hname.$ENV.sh"; do
    if [ -f "$_h" ]; then
      myos_debug "hook $_h"
      # shellcheck source=/dev/null
      . "$_h"
    fi
  done
  return 0
}
