#shellcheck shell=sh
# shellcheck disable=SC1091  # lib/cmd files are sourced by path at run time
# shellcheck disable=SC3028  # HOSTNAME is a myos variable, set by bin/myos
# myos cert <list|domains|issue|renew|show>  the certificates a server needs
#
# The hostnames come from the route tags of the stacks, so a site gets a
# certificate by being routed, not by being written down a second time.
myos_cmd_cert() {
  _sub=$(myos_firstword "${MYOS_VARS:-}${MYOS_ARGS:+ $MYOS_ARGS}")
  [ -n "$_sub" ] || _sub=list
  case $_sub in
    list)    myos_cert_list ;;
    domains) myos_cert_write_domains ;;
    issue)   myos_cert_run "" ;;
    renew)   myos_cert_run "--cron" ;;
    show)    myos_cert_show ;;
    *) myos_die "$MYOS_E_USAGE" "myos cert <list|domains|issue|renew|show>" ;;
  esac
}

# myos_cert_list  the certificates that would be asked for, and how
myos_cert_list() {
  _groups=$(myos_cert_groups)
  [ -n "$_groups" ] || {
    printf 'no routed hostname: nothing to certify\n'
    return 0
  }
  printf '%s%-46s %-9s %s%s\n' "$MYOS_C_HIGHLIGHT" CERTIFICATE CHALLENGE NAMES "$MYOS_C_RESET"
  printf '%s\n' "$_groups" | while IFS= read -r _line; do
    _cn=$(myos_firstword "$_line")
    case $_line in
      *'*.'*) _ch=dns-01 ;;
      *)      _ch=http-01 ;;
    esac
    printf '%-46s %-9s %s\n' "$_cn" "$_ch" "$_line"
  done
  myos_cert_needs_dns &&
    myos_info "a wildcard is asked for: dns-01 needs MYOS_CERT_HOOK to talk to your dns provider"
  return 0
}

# myos_cert_write_domains  the domains.txt dehydrated reads
myos_cert_write_domains() {
  _dir=${MYOS_CERT_DIR:-$WORKDIR/.myos/dehydrated}
  _file=$_dir/domains.txt
  _groups=$(myos_cert_groups)
  [ -n "$_groups" ] || { myos_warning "no routed hostname: not writing $_file"; return 0; }
  myos_run mkdir -p "$_dir"
  if [ "${DRYRUN:-false}" = true ]; then
    printf 'would write %s:\n%s\n' "$_file" "$_groups"
  else
    printf '%s\n' "$_groups" > "$_file"
    printf '%s\n' "$_file"
  fi
}

# myos_cert_run ARGS  run dehydrated in the host stack, on the domains derived
myos_cert_run() {
  myos_cert_write_domains >/dev/null || return $?
  _args=$1
  [ -n "${MYOS_CERT_STAGING:-}" ] && _args="$_args --staging"
  case ${MYOS_ARGS:-} in
    *--staging*) _args="$_args --staging" ;;
  esac
  case ${MYOS_ARGS:-} in
    *--force*) _args="$_args --force" ;;
  esac
  MYOS_ARGS="$_args" SERVICE=${SERVICE:-dehydrated} \
    MYOS_STACKS="host/dehydrated" myos_cert_exec
}

myos_cert_exec() {
  # shellcheck source=lib/cmd/exec.sh
  . "$MYOS_ROOT/lib/cmd/exec.sh"
  myos_cmd_exec
}

# myos_cert_show  the certificates that exist, and when they expire
myos_cert_show() {
  _vol=${HOST_DOCKER_VOLUME:-${HOSTNAME:-localhost}}
  # shellcheck disable=SC2016  # the script runs in the container, not here
  myos_run docker run --rm -v "$_vol:/host" alpine:3.20 sh -c '
    apk add -q openssl 2>/dev/null
    for c in /host/certs/*-cert.pem; do
      [ -f "$c" ] || continue
      n=$(basename "$c" -cert.pem)
      e=$(openssl x509 -in "$c" -noout -enddate 2>/dev/null | sed "s/notAfter=//")
      i=$(openssl x509 -in "$c" -noout -issuer 2>/dev/null | sed "s/.*CN *= *//;s/,.*//")
      printf "%-46s %-28s %s\n" "$n" "$e" "$i"
    done'
}
