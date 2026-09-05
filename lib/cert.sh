#shellcheck shell=sh
# cert: which certificates a server needs, derived from what its stacks route.
#
# The hostnames are already declared, once, in the fabio route tags a stack
# publishes: urlprefix-<host>/<path>. Asking for them a second time in a
# domains.txt would be a second source of truth, free to disagree with what is
# actually served. They are read from the resolved compose configuration
# instead.
#
# A name written *.example.org needs a wildcard, which ACME only issues over
# dns-01; a concrete name can be had over http-01. That is the whole of
# "per-site or wildcard according to need": the tags say which.

# myos_cert_names  the hostnames the requested stacks route, one per line
myos_cert_names() {
  for _ref in $MYOS_STACKS; do
    _files=$(myos_stack_compose_files "$_ref" 2>/dev/null) || continue
    [ -n "$_files" ] || continue
    _fw=$(myos_framework_compose_files)
    [ -n "$_fw" ] && _files="$_files
$_fw"
    _app=$(myos_stack_name "$_ref")
    _project=$(myos_project_name "$(myos_scope "$_ref")" "$USER" "$ENV" "$_app")
    DRYRUN=false myos_compose "$_project" "$_files" -- config 2>/dev/null
  done | myos_cert_parse
}

# myos_cert_parse  (compose config on stdin) -> hostnames
# A tag is urlprefix-<host>[:<port>]/<path> with options after a space; the
# bare "*" is fabio's catch-all and names nothing.
myos_cert_parse() {
  grep -oE 'urlprefix-[^",[:space:]]*' 2>/dev/null |
  sed -e 's/^urlprefix-//' -e 's|/.*||' -e 's/:[0-9]*$//' |
  grep -vE '^\*?$' |
  sort -u
}

# myos_cert_covers WILDCARD_PARENT NAME  does *.parent cover this name?
# A wildcard matches one label, so *.example.org covers a.example.org but
# neither example.org nor a.b.example.org.
myos_cert_covers() {
  case $2 in
    *".$1")
      _head=${2%".$1"}
      case $_head in *.*|'') return 1 ;; *) return 0 ;; esac ;;
    *) return 1 ;;
  esac
}

# myos_cert_groups  the certificates to ask for, one per line, in the shape
# dehydrated reads: the common name first, then its subject alternative names.
#
# MYOS_CERT_MODE:
#   auto      a wildcard where the tags use one, a certificate per name otherwise
#   wildcard  one wildcard per domain, whether or not a tag asked for it
#   per-site  never a wildcard: one certificate per name, dns-01 not required
myos_cert_groups() {
  _names=$(myos_cert_names)
  [ -n "$_names" ] || return 0
  _mode=${MYOS_CERT_MODE:-auto}

  # the parents a wildcard is wanted for
  _wild=
  for _n in $_names; do
    case $_n in
      \*.*) [ "$_mode" = per-site ] || _wild="$_wild ${_n#\*.}" ;;
    esac
  done
  if [ "$_mode" = wildcard ]; then
    for _n in $_names; do
      case $_n in
        \*.*) ;;
        *.*.*) _wild="$_wild ${_n#*.}" ;;
      esac
    done
  fi
  _wild=$(printf '%s' "$_wild" | tr ' ' '\n' | sed '/^$/d' | sort -u)

  # one line per wildcard, the parent first so it is the common name
  for _p in $_wild; do
    printf '%s *.%s\n' "$_p" "$_p"
  done

  # the concrete names a wildcard does not already cover
  for _n in $_names; do
    case $_n in \*.*) continue ;; esac
    _covered=no
    for _p in $_wild; do
      [ "$_n" = "$_p" ] && { _covered=yes; break; }
      myos_cert_covers "$_p" "$_n" && { _covered=yes; break; }
    done
    [ "$_covered" = no ] && printf '%s\n' "$_n"
  done
  return 0
}

# myos_cert_needs_dns  true when any certificate asked for is a wildcard
myos_cert_needs_dns() { myos_cert_groups | grep -q '\*\.'; }
