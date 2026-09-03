#shellcheck shell=sh
# Helper: myos_stack_resolve exports the parsed name and version as a side
# effect, which a subshell would discard.
myos_stack_resolve "postgres:9.6" >/dev/null
printf '%s %s\n' "$MYOS_STACK_NAME" "$MYOS_STACK_VERSION"
