#shellcheck shell=sh
# myos ls [--groups]  list the stacks myos can see, and where they come from
myos_cmd_ls() {
  case ${MYOS_REFS_RAW:-}${MYOS_ARGS:-} in
    *--groups*) myos_ls_groups; return 0 ;;
  esac
  _IFS=$IFS; IFS=:
  for _d in $(myos_path); do
    IFS=$_IFS
    printf '%s%s%s\n' "$MYOS_C_INFO" "$_d" "$MYOS_C_RESET"
    for _s in "$_d"/*; do
      [ -d "$_s" ] || continue
      _n=$(basename "$_s")
      _f=$(find "$_s" -maxdepth 1 \( -name '*.yml' -o -name '*.yaml' \) | wc -l | tr -d ' ')
      [ "$_f" = 0 ] && continue
      printf '  %-24s %s compose file(s)\n' "$_n" "$_f"
    done
    IFS=:
  done
  IFS=$_IFS
}

myos_ls_groups() {
  _IFS=$IFS; IFS=:
  for _d in $(myos_path); do
    IFS=$_IFS
    for _f in "$_d"/*.mk "$_d"/*.env "$_d"/*/*.mk; do
      [ -f "$_f" ] || continue
      _n=$(basename "$_f"); _n=${_n%.mk}; _n=${_n%.env}
      _v=$(myos_group_value "$_n")
      [ -n "$_v" ] && printf '%-16s %s\n' "$_n" "$_v"
    done
    IFS=:
  done
  IFS=$_IFS
}
