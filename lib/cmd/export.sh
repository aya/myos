#shellcheck shell=sh
# myos export  print every setting the requested stacks declare, as KEY=value.
#
# One call, so a Makefile can read the whole set at once:
#   $(eval $(shell myos export STACK=host))
# Asking for each variable separately costs a process per variable.
myos_cmd_export() {
  # shellcheck disable=SC2209  # these are literal format names, not commands
  _fmt=sh
  # shellcheck disable=SC2209
  case ${MYOS_ARGS:-}${MYOS_VARS:-} in *--make*) _fmt=make ;; esac
  for _v in $(myos_declared_defaults); do
    _val=$(myos_var "$_v")
    case $_fmt in
      make)
        # make would expand a $ and start a comment at a #, and := stops it
        # from expanding the value again later
        printf '%s := %s\n' "$_v" "$(printf '%s' "$_val" | sed -e 's/\$/$$/g' -e 's/#/\\#/g')" ;;
      *) printf '%s=%s\n' "$_v" "$_val" ;;
    esac
  done
}

# myos_declared_defaults  the variables the loaded hooks declare
myos_declared_defaults() {
  for _ref in $MYOS_STACKS; do
    for _d in $(myos_stack_dirs "$_ref"); do
      for _f in "$_d"/_stack.sh "$_d/$(myos_stack_name "$_ref").sh"; do
        [ -f "$_f" ] && sed -n 's/^myos_default_\([A-Za-z_][A-Za-z0-9_]*\)().*/\1/p' "$_f"
      done
      for _f in "$_d"/_stack.env "$_d/$(myos_stack_name "$_ref").env"; do
        [ -f "$_f" ] && myos_dotenv_parse "$_f" | sed 's/=.*//'
      done
    done
  done | sort -u
}
