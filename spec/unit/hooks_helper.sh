#shellcheck shell=sh
# Helper: hooks set variables in the caller's scope, which a subshell loses.
[ -n "${4:-}" ] && eval "$3=\$4"
myos_stack_hooks "$1" "$2"
eval "printf '%s\n' \"\${$3:-}\""
