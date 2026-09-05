#shellcheck shell=sh
# firewall: which ports the project publishes, to whom, and the rules of the
# host for them.
#   firewall [audit]   every published port of the compose files, with its
#                      scope: public (0.0.0.0), private (127.0.0.1), mesh
#                      (the address of MYOS_BIND_MESH) or an address;
#                      --strict exits 4 when a stack that is not a host
#                      stack publishes a public port
#   firewall apply     the rules for the public ports of a host stack and
#                      for <SVC>_FIREWALL (or the old <SVC>_UFW_UPDATE /
#                      <SVC>_UFW_DOCKER), through MYOS_FIREWALL=auto|ufw|
#                      nftables|pf|none; -n prints them
# The portable defence is the bind address: a stack writes
# "${MYOS_BIND_PRIVATE:-127.0.0.1}:8080:80" and only the host stacks bind
# ${MYOS_BIND_PUBLIC}. Docker publishes around the host firewall on Linux,
# so a rule alone protects nothing.

# myos_ports -> R: NL list of "service<TAB>spec" from the raw compose files
myos_ports_raw() {
  R=; [ -n "$MYOS_STACK_FILES" ] || return 0
  _pr_ifs=$IFS; IFS=$NL; set -f
  # shellcheck disable=SC2086
  R=$(awk '
    /^services:/ {top="services"; next}
    /^[^ \t#]/ {top=$0; next}
    top != "services" {next}
    /^  [A-Za-z0-9_.-]+:/ {svc=$0; sub(/^  /, "", svc); sub(/:.*/, "", svc); inports=0; next}
    /^    ports:/ {inports=1; next}
    /^    [A-Za-z_]/ {inports=0}
    inports && /^ +- / {p=$0; sub(/^ +- /, "", p); gsub(/^["'"'"']|["'"'"']$/, "", p); if (p ~ /^[^ ]/) print svc "\t" p}
  ' $MYOS_STACK_FILES)
  IFS=$_pr_ifs; set +f
}

# myos_port_parse SPEC -> MYOS_PORT_ADDR MYOS_PORT_HOST MYOS_PORT_CONTAINER MYOS_PORT_PROTO
myos_port_parse() {
  _pp=$1; MYOS_PORT_PROTO=tcp
  case $_pp in */*) MYOS_PORT_PROTO=${_pp##*/}; _pp=${_pp%/*} ;; esac
  case $_pp in
    *:*:*) MYOS_PORT_ADDR=${_pp%%:*}; _pp=${_pp#*:}; MYOS_PORT_HOST=${_pp%%:*}; MYOS_PORT_CONTAINER=${_pp#*:} ;;
    *:*)   MYOS_PORT_ADDR=; MYOS_PORT_HOST=${_pp%%:*}; MYOS_PORT_CONTAINER=${_pp#*:} ;;
    *)     MYOS_PORT_ADDR=; MYOS_PORT_HOST=; MYOS_PORT_CONTAINER=$_pp ;;
  esac
  [ -n "$MYOS_PORT_HOST" ] || MYOS_PORT_HOST=random
  [ -n "$MYOS_PORT_CONTAINER" ] || MYOS_PORT_CONTAINER=none
}
myos_port_scope() { # ADDR -> R
  myos_var MYOS_BIND_MESH; _sc_mesh=$R
  case $1 in
    ''|0.0.0.0|'::') R=public ;;
    127.0.0.1|localhost|'::1') R=private ;;
    *) if [ -n "$_sc_mesh" ] && [ "$1" = "$_sc_mesh" ]; then R=mesh; else R=address; fi ;;
  esac
}

# myos_ports -> R: NL list of "service host container proto scope address"
myos_ports() {
  myos_ports_raw; _po_raw=$R; _po_out=
  _po_ifs=$IFS; IFS=$NL; set -f
  for _po_l in $_po_raw; do
    IFS=$_po_ifs; set +f
    _po_svc=${_po_l%%	*}; _po_spec=${_po_l#*	}
    myos_env_resolve "$_po_spec"; myos_port_parse "$R"
    myos_port_scope "$MYOS_PORT_ADDR"
    _po_out="$_po_out$NL$_po_svc $MYOS_PORT_HOST $MYOS_PORT_CONTAINER $MYOS_PORT_PROTO $R ${MYOS_PORT_ADDR:-0.0.0.0}"
    IFS=$NL; set -f
  done
  IFS=$_po_ifs; set +f; R=${_po_out#"$NL"}
}

myos_verb_firewall() {
  case ${MYOS_SUB:-audit} in apply) myos_firewall_apply ;; *) myos_firewall_audit ;; esac
}

myos_firewall_audit() {
  myos_ports; _fa_bad=
  _fa_ifs=$IFS; IFS=$NL; set -f
  for _fa_l in $R; do
    IFS=$_fa_ifs; set +f; set -- $_fa_l
    if [ "$MYOS_OUTPUT" = json ]; then
      printf '{"verb":"firewall","stack":"%s","service":"%s","port":"%s","container":"%s","proto":"%s","scope":"%s","address":"%s"}\n' "$MYOS_STACK" "$1" "$2" "$3" "$4" "$5" "$6"
    else
      printf '%s %s %s %s %s%s\n' "$MYOS_STACK" "$1" "$2" "$5" "$6" "$( [ "$4" = tcp ] || printf ' /%s' "$4")"
    fi
    [ "$5" = public ] && [ "$MYOS_STACK_SCOPE" != host ] && _fa_bad="$_fa_bad $1:$2"
    IFS=$NL; set -f
  done
  IFS=$_fa_ifs; set +f
  if [ -n "$MYOS_STRICT" ] && [ -n "$_fa_bad" ]; then myos_event audit "$MYOS_STACK" fail "public ports of a stack that is not a host stack:$_fa_bad"; return 4; fi
  return 0
}

# myos_firewall_rules -> R: NL list of "port/proto" the host must open for the project
myos_firewall_rules() {
  _fr_out=
  myos_ports
  _fr_ifs=$IFS; IFS=$NL; set -f
  for _fr_l in $R; do
    IFS=$_fr_ifs; set +f; set -- $_fr_l
    [ "$5" = public ] && [ "$2" != random ] && _fr_out="$_fr_out$NL$2/$4"
    # the explicit lists of the service: <PREFIX><SVC>_FIREWALL, or the old ufw names
    fn_upper "$1"; _fr_svc=$R
    for _fr_n in "${MYOS_STACK_SCOPE_PREFIX}${_fr_svc}_FIREWALL" "${MYOS_STACK_SCOPE_PREFIX}${_fr_svc}_UFW_UPDATE" "${MYOS_STACK_SCOPE_PREFIX}${_fr_svc}_UFW_DOCKER"; do
      myos_var "$_fr_n"; for _fr_p in $R; do case $_fr_p in */*) _fr_out="$_fr_out$NL$_fr_p" ;; *) _fr_out="$_fr_out$NL$_fr_p/tcp" ;; esac; done
    done
    IFS=$NL; set -f
  done
  IFS=$_fr_ifs; set +f
  myos_nl_uniq "${_fr_out#"$NL"}"
}

myos_firewall_adapter() { # -> R: ufw|nftables|pf|none
  case ${MYOS_FIREWALL:-auto} in
    auto) if command -v ufw >/dev/null 2>&1; then R=ufw; elif command -v nft >/dev/null 2>&1; then R=nftables; elif command -v pfctl >/dev/null 2>&1; then R=pf; else R=none; fi ;;
    *) R=$MYOS_FIREWALL ;;
  esac
}

myos_firewall_apply() {
  [ "$MYOS_STACK_SCOPE" = host ] || { myos_event apply "$MYOS_STACK" skip "not a host stack: bind its ports on \${MYOS_BIND_PRIVATE} instead"; return 0; }
  myos_firewall_adapter; _ap_ad=$R
  myos_firewall_rules; _ap_rules=$R
  [ -n "$_ap_rules" ] || { myos_event apply "$MYOS_STACK" skip "no public port"; return 0; }
  _ap_ifs=$IFS; IFS=$NL; set -f
  for _ap_r in $_ap_rules; do
    IFS=$_ap_ifs; set +f
    _ap_port=${_ap_r%/*}; _ap_proto=${_ap_r#*/}
    case $_ap_ad in
      ufw)      myos_run ufw allow "$_ap_port/$_ap_proto" ;;
      nftables) myos_run nft add rule inet filter input "$_ap_proto" dport "$_ap_port" accept ;;
      pf)       printf 'pass in proto %s to any port %s   # add to /etc/pf.conf\n' "$_ap_proto" "$_ap_port" ;;
      none)     printf 'open %s/%s\n' "$_ap_port" "$_ap_proto" ;;
      *) myos_die 2 "unknown firewall adapter $_ap_ad (ufw, nftables, pf, none)" ;;
    esac || { myos_event rule "$_ap_r" fail; IFS=$_ap_ifs; set +f; return 1; }
    IFS=$NL; set -f
  done
  IFS=$_ap_ifs; set +f
  myos_event apply "$MYOS_STACK" ok "$_ap_ad"
}
