#shellcheck shell=sh
# myos expose [--strict]  what the stacks publish, and to whom
#
# Two readings are joined: the compose files as written, which say which
# binding each port asks for, and the resolved configuration, which says the
# address it ends up on. The first is the intent, the second is the fact, and
# reporting both is the point: a port nobody bound answers the internet, and on
# linux the host firewall does not see it, because docker writes its own rules.
#
# --strict exits 1 when a port is published without a binding.
myos_cmd_expose() {
  _strict=false
  case ${MYOS_ARGS:-}${MYOS_VARS:-} in *--strict*) _strict=true ;; esac

  _rows=$(myos_expose_rows)
  [ -n "$_rows" ] || {
    printf 'no published port: nothing is reachable from outside the docker network\n'
    return 0
  }

  printf '%s%-20s %-14s %-22s %-6s %s%s\n' \
    "$MYOS_C_HIGHLIGHT" STACK SERVICE "PUBLISHED ON" PORT BINDING "$MYOS_C_RESET"
  _bad=0
  _oIFS=$IFS; IFS='
'
  for _row in $_rows; do
    IFS=$_oIFS
    _st=${_row%%|*}; _r=${_row#*|}
    _sv=${_r%%|*};  _r=${_r#*|}
    _on=${_r%%|*};  _r=${_r#*|}
    _pt=${_r%%|*};  _sc=${_r#*|}
    if [ "$_sc" = unbound ]; then
      _bad=$((_bad + 1))
      printf '%-20s %-14s %s%-22s%s %-6s %s%s%s\n' "$_st" "$_sv" \
        "$MYOS_C_WARN" "$_on" "$MYOS_C_RESET" "$_pt" "$MYOS_C_WARN" "$_sc" "$MYOS_C_RESET"
    else
      printf '%-20s %-14s %-22s %-6s %s\n' "$_st" "$_sv" "$_on" "$_pt" "$_sc"
    fi
    IFS='
'
  done
  IFS=$_oIFS

  if [ "$_bad" -gt 0 ]; then
    myos_warning "$_bad port(s) published without a binding: docker opens them on every address"
    # shellcheck disable=SC2016  # the variable name is the message, not a value
    myos_warning 'bind them: ports: ["${MYOS_BIND_PRIVATE}::<port>"] for a service behind the load balancer'
    [ "$_strict" = true ] && return "$MYOS_E_FAIL"
  fi
  return 0
}

# myos_expose_rows  STACK|SERVICE|ADDR:PORT|CONTAINER_PORT|BINDING
myos_expose_rows() {
  for _ref in $MYOS_STACKS; do
    _files=$(myos_stack_compose_files "$_ref" 2>/dev/null) || continue
    [ -n "$_files" ] || continue
    _fw=$(myos_framework_compose_files)
    [ -n "$_fw" ] && _files="$_files
$_fw"
    _app=$(myos_stack_name "$_ref")
    _project=$(myos_project_name "$(myos_scope "$_ref")" "$USER" "$ENV" "$_app")

    # what the files ask for, later overlays overriding earlier ones
    _decl=$(mktemp "${TMPDIR:-/tmp}/myos-expose.XXXXXX")
    # shellcheck disable=SC2086  # a newline separated list of paths
    myos_expose_declared $_files > "$_decl" 2>/dev/null

    DRYRUN=false myos_compose "$_project" "$_files" -- config 2>/dev/null |
      myos_expose_resolved |
      while IFS='|' read -r _v _t _o; do
        _b=$(awk -F'|' -v s="$_v" -v p="$_t" '$1==s && $2==p {last=$3} END {print last}' "$_decl")
        printf '%s|%s|%s|%s|%s\n' "$_ref" "$_v" "$_o" "$_t" "${_b:-unbound}"
      done
    rm -f "$_decl"
  done
}

# myos_expose_resolved  (compose config on stdin) -> SERVICE|CONTAINER_PORT|ADDR:PORT
# compose normalises every port to the long form, so one shape is enough
myos_expose_resolved() {
  awk '
    /^services:/ { insvc = 1; next }
    insvc && /^  [a-zA-Z0-9_.-]+:/ { svc = $1; sub(/:$/, "", svc); inports = 0 }
    insvc && /^    ports:/ { inports = 1; next }
    inports && /^    [a-z]/ { inports = 0 }
    inports && /host_ip:/ { ip = $2 }
    inports && /published:/ { pub = $2; gsub(/"/, "", pub) }
    inports && /target:/ { tgt = $2 }
    inports && /protocol:/ {
      # compose leaves published empty when docker picks the port at run time
      printf "%s|%s|%s:%s\n", svc, tgt, (ip == "" ? "0.0.0.0" : ip), (pub == "" ? "auto" : pub)
      ip = ""; pub = ""; tgt = ""
    }
  '
}
