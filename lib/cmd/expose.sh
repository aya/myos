#shellcheck shell=sh
# myos expose [--strict]  what the stacks publish, and to whom
#
# Reads the resolved compose configuration, so it reports what `myos up` would
# open rather than what happens to be running. A port bound to 0.0.0.0 answers
# the internet: on linux docker writes its own firewall rules and the host
# firewall does not see it. --strict exits 1 when a port is world-bound
# without the stack declaring that scope.
myos_cmd_expose() {
  _strict=false
  case ${MYOS_ARGS:-}${MYOS_VARS:-} in *--strict*) _strict=true ;; esac

  _rows=$(myos_expose_rows)
  [ -n "$_rows" ] || { printf 'no published port: nothing is reachable from outside the docker network\n'; return 0; }

  printf '%s%-20s %-14s %-22s %-6s %s%s\n' \
    "$MYOS_C_HIGHLIGHT" STACK SERVICE "PUBLISHED ON" PORT SCOPE "$MYOS_C_RESET"
  _bad=0
  _oIFS=$IFS; IFS='
'
  for _row in $_rows; do
    IFS=$_oIFS
    _st=${_row%%|*}; _rest=${_row#*|}
    _sv=${_rest%%|*}; _rest=${_rest#*|}
    _on=${_rest%%|*}; _rest=${_rest#*|}
    _pt=${_rest%%|*}; _sc=${_rest#*|}
    case ${_on%:*} in
      0.0.0.0|''|'::'|'*')
        [ "$_sc" = public ] || _bad=$((_bad + 1))
        printf '%-20s %-14s %s%-22s%s %-6s %s\n' \
          "$_st" "$_sv" "$MYOS_C_WARN" "$_on" "$MYOS_C_RESET" "$_pt" "$_sc" ;;
      *)
        printf '%-20s %-14s %-22s %-6s %s\n' "$_st" "$_sv" "$_on" "$_pt" "$_sc" ;;
    esac
    IFS='
'
  done
  IFS=$_oIFS

  if [ "$_bad" -gt 0 ]; then
    myos_warning "$_bad port(s) reachable from anywhere without declaring the public scope"
    myos_warning "bind them: ports: [\"\${MYOS_BIND_PRIVATE}::<port>\"]"
    [ "$_strict" = true ] && return "$MYOS_E_FAIL"
  fi
  return 0
}

# myos_expose_rows  STACK|SERVICE|ADDR:PORT|CONTAINER_PORT|SCOPE for every
# published port of the requested stacks
myos_expose_rows() {
  for _ref in $MYOS_STACKS; do
    _files=$(myos_stack_compose_files "$_ref" 2>/dev/null) || continue
    [ -n "$_files" ] || continue
    _fw=$(myos_framework_compose_files)
    [ -n "$_fw" ] && _files="$_files
$_fw"
    _app=$(myos_stack_name "$_ref")
    _project=$(myos_project_name "$(myos_scope "$_ref")" "$USER" "$ENV" "$_app")
    DRYRUN=false myos_compose "$_project" "$_files" -- config 2>/dev/null |
      myos_expose_parse "$_ref" "$(myos_stack_prefix "$_ref")"
  done
}

# myos_expose_parse STACK NAME  (compose config on stdin)
# compose normalises every port to the long form, so one shape is enough
myos_expose_parse() {
  awk -v stack="$1" '
    /^services:/ { insvc = 1; next }
    insvc && /^  [a-zA-Z0-9_.-]+:/ { svc = $1; sub(/:$/, "", svc); inports = 0 }
    insvc && /^    ports:/ { inports = 1; next }
    inports && /^    [a-z]/ { inports = 0 }
    inports && /host_ip:/ { ip = $2 }
    inports && /published:/ { pub = $2; gsub(/"/, "", pub) }
    inports && /target:/ { tgt = $2 }
    inports && /protocol:/ {
      printf "%s|%s|%s:%s|%s\n", stack, svc, (ip == "" ? "0.0.0.0" : ip), pub, tgt
      ip = ""; pub = ""; tgt = ""
    }
  ' | while IFS='|' read -r _s _v _o _t; do
    printf '%s|%s|%s|%s|%s\n' "$_s" "$_v" "$_o" "$_t" "$(myos_expose_scope "$2" "$_v" "$_t")"
  done
}
