#shellcheck shell=sh
# var: variable resolution, with the lazy defaults the make engine had.
#
# make gives every `VAR ?= $(call ...)` two properties at once: an explicit
# value wins, and the default is re-evaluated at each reference, so it sees
# whatever a .env loaded later has changed.
#
# The shell gets both by keeping defaults in functions: `myos_var NAME` reads
# the variable when it has a value, and otherwise calls the function
# `myos_default_NAME`. The prefix matters: a bare function named after the
# variable would collide with commands on PATH, and a stack setting called
# `host` or `test` would then run a program instead of returning a value.
#
#   myos_default_HOST_FABIO_SERVICE_9998_TAGS() { myos_tagprefix HOST_FABIO 9998; }
#
# is the exact equivalent of
#
#   HOST_FABIO_SERVICE_9998_TAGS ?= $(call tagprefix,HOST_FABIO,9998)

MYOS_VAR_MAX_DEPTH=${MYOS_VAR_MAX_DEPTH:-32}

# myos_var NAME  the value of NAME: the variable if it has one, else the lazy
# default, else empty.
myos_var() {
  [ -n "${1:-}" ] || return 0
  eval "_myos_set=\${$1+yes}"
  if [ "${_myos_set:-}" = yes ]; then
    eval "printf '%s' \"\$$1\""
    return 0
  fi
  myos_var_is_lazy "$1" || return 0

  # a default written in terms of itself would loop for ever
  _myos_depth=$((${MYOS_VAR_DEPTH:-0} + 1))
  if [ "$_myos_depth" -gt "$MYOS_VAR_MAX_DEPTH" ]; then
    myos_error "variable $1 is defined in terms of itself"
    return 1
  fi
  MYOS_VAR_DEPTH=$_myos_depth "myos_default_$1"
}

# myos_default NAME BODY  declare a lazy default from a string, for callers
# that build the variable name at run time
myos_default() {
  eval "myos_default_$1() { $2; }"
}

# myos_var_is_lazy NAME  true when NAME has no value but has a lazy default
myos_var_is_lazy() {
  eval "_myos_set=\${$1+yes}"
  [ "${_myos_set:-}" = yes ] && return 1
  # a shell function, never a command on PATH: command -v prints the name back
  # for a function and a path for a program
  _myos_fn=$(command -v "myos_default_$1" 2>/dev/null) || return 1
  [ "$_myos_fn" = "myos_default_$1" ]
}
