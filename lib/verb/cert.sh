#shellcheck shell=sh
# cert: the certificates a host needs, derived from what it routes.
# The routes are the consul tags urlprefix-<host>/<path> of the settings
# (the <SVC>_SERVICE_<port>_TAGS the stacks export); every host named there
# needs a certificate in the host volume (/host/certs/<name>-cert.pem and
# -key.pem, what fabio reads).
#   cert list          the names, wildcards marked
#   cert [issue|renew] the concrete names through dehydrated (http-01):
#                      domains.txt written into the host volume, then
#                      `dehydrated -c` in the dehydrated service; wildcards
#                      need --wildcard and a dns-01 hook (actions/cert-dns
#                      of a stack, or MYOS_CERT_DNS_HOOK)
#   cert --self-signed a self-signed certificate per name (bootstrap)
#   cert --check       the expiry of every certificate

# myos_cert_names: MYOS_CERT_NAMES (concrete, sorted) and MYOS_CERT_WILDCARDS
myos_cert_names() {
  _cn_tags=; myos_env_vars; _cn_all="$R $MYOS_SET_EXPORT $MYOS_SET_NAMES"
  myos_uniq "$_cn_all"; set -f
  for _cn_v in $R; do
    case $_cn_v in *TAGS*|*URIS*) ;; *) continue ;; esac
    myos_var "$_cn_v"; case $R in *urlprefix-*) _cn_tags="$_cn_tags $R" ;; esac
  done
  _cn_names=; _cn_wild=
  for _cn_t in $(printf '%s' "$_cn_tags" | tr ',' ' '); do
    case $_cn_t in urlprefix-*) ;; *) continue ;; esac
    _cn_h=${_cn_t#urlprefix-}; _cn_h=${_cn_h%%/*}; _cn_h=${_cn_h%%:*}
    case $_cn_h in ''|'*') continue ;; \*.*) _cn_wild="$_cn_wild $_cn_h" ;; *) _cn_names="$_cn_names $_cn_h" ;; esac
  done
  set +f
  myos_sort_words "$_cn_names"; MYOS_CERT_NAMES=$R
  myos_sort_words "$_cn_wild"; MYOS_CERT_WILDCARDS=$R
}

myos_cert_volume() { myos_var HOST_DOCKER_VOLUME; [ -n "$R" ] || R=$MYOS_HOSTNAME; }

myos_verb_cert() {
  myos_cert_names
  case ${MYOS_SUB:-issue} in
    list)
      set -f
      for _ct_n in $MYOS_CERT_NAMES; do printf '%s\n' "$_ct_n"; done
      for _ct_n in $MYOS_CERT_WILDCARDS; do printf '%s wildcard\n' "$_ct_n"; done
      set +f; return 0 ;;
  esac
  [ -n "$MYOS_CERT_NAMES$MYOS_CERT_WILDCARDS" ] || { myos_event issue "$MYOS_STACK" skip "no route names a host"; return 0; }
  if [ -n "${MYOS_SELF_SIGNED:-}" ]; then myos_cert_self_signed; return $?; fi
  if [ -n "${MYOS_CHECK:-}" ]; then myos_cert_check; return $?; fi
  myos_verb_with_hooks cert myos_cert_issue
}

myos_cert_issue() {
  myos_cert_volume; _ci_vol=$R
  _ci_domains=$MYOS_CERT_NAMES
  if [ -n "$MYOS_CERT_WILDCARDS" ]; then
    if [ -n "${MYOS_WILDCARD:-}" ]; then
      _ci_hook=${MYOS_CERT_DNS_HOOK:-}
      [ -n "$_ci_hook" ] || { myos_hook_dirs; _ci_ifs=$IFS; IFS=$NL; set -f; for _ci_d in $R; do [ -x "$_ci_d/actions/cert-dns" ] && _ci_hook=$_ci_d/actions/cert-dns; done; IFS=$_ci_ifs; set +f; }
      [ -n "$_ci_hook" ] || myos_die 1 "a wildcard needs dns-01: provide actions/cert-dns in a stack or MYOS_CERT_DNS_HOOK for $MYOS_CERT_WILDCARDS"
      _ci_domains="$_ci_domains $MYOS_CERT_WILDCARDS"
    else
      myos_event wildcard "$MYOS_CERT_WILDCARDS" skip "needs --wildcard and a dns-01 hook"
    fi
  fi
  [ -n "$_ci_domains" ] || return 0
  if [ "$MYOS_DRYRUN" = true ]; then
    printf 'docker run --rm -i -v %s:/host alpine sh -c "mkdir -p /host/dehydrated && cat > /host/dehydrated/domains.txt" <<EOF\n%s\nEOF\n' "$_ci_vol" "$(printf '%s\n' $_ci_domains)"
  else
    printf '%s\n' $_ci_domains | docker run --rm -i -v "$_ci_vol:/host" alpine sh -c 'mkdir -p /host/dehydrated && cat > /host/dehydrated/domains.txt' || return 1
  fi
  myos_event domains "$_ci_vol" ok "$_ci_domains"
  myos_compose exec -T dehydrated dehydrated -c || { myos_event issue "$MYOS_STACK" fail; return 1; }
  myos_event issue "$MYOS_STACK" ok
}

myos_cert_self_signed() {
  myos_cert_volume; _cs_vol=$R; set -f
  for _cs_n in $MYOS_CERT_NAMES; do
    set +f
    myos_run docker run --rm -v "$_cs_vol:/host" alpine sh -c "apk add -q openssl && mkdir -p /host/certs && [ -f /host/certs/$_cs_n-cert.pem ] || openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj /CN=$_cs_n -addext subjectAltName=DNS:$_cs_n -keyout /host/certs/$_cs_n-key.pem -out /host/certs/$_cs_n-cert.pem 2>/dev/null" \
      && myos_event self-signed "$_cs_n" ok || { myos_event self-signed "$_cs_n" fail; set +f; return 1; }
    set -f
  done
  set +f
}

myos_cert_check() {
  myos_cert_volume; _cc_vol=$R; _cc_rc=0; set -f
  for _cc_n in $MYOS_CERT_NAMES; do
    set +f
    _cc_end=$(docker run --rm -v "$_cc_vol:/host:ro" alpine sh -c "apk add -q openssl && openssl x509 -enddate -noout -in /host/certs/$_cc_n-cert.pem" 2>/dev/null)
    if [ -n "$_cc_end" ]; then myos_event check "$_cc_n" ok "${_cc_end#notAfter=}"; else myos_event check "$_cc_n" fail "no certificate"; _cc_rc=4; fi
    set -f
  done
  set +f; return $_cc_rc
}
