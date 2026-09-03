#shellcheck shell=sh
# str: string helpers ported from make/utils.mk and make/def.mk.

# myos_lower STRING / myos_upper STRING
myos_lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
myos_upper() { printf '%s' "$1" | tr '[:lower:]-.' '[:upper:]__'; }

# myos_name STRING  compose-project-safe name: lowercase, no . - _
# (make: $(subst _,,$(subst -,,$(subst .,,$(call LOWERCASE,$(1))))))
myos_name() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '._-'; }

# myos_slugify STRING  keep [a-z0-9_], everything else becomes _
myos_slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]/_/g'; }

# myos_reverse WORDS...  reverse the order of space separated words
myos_reverse() {
  _out=
  for _w in $1; do _out="$_w${_out:+ }$_out"; done
  printf '%s' "$_out"
}

# myos_verle A B  true when version A <= B (make: verle)
myos_verle() {
  [ -n "$1" ] || return 1
  [ -n "$2" ] || return 1
  [ "$1" = "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" ]
}

# myos_verlt A B  true when version A < B
myos_verlt() {
  [ "$1" = "$2" ] && return 1
  myos_verle "$1" "$2"
}

# The make list functions the catalogue uses, on space separated words.

# myos_firstword LIST / myos_lastword LIST
myos_firstword() { for _w in $1; do printf '%s' "$_w"; return 0; done; }
myos_lastword()  { _l=; for _w in $1; do _l=$_w; done; printf '%s' "$_l"; }

# myos_or A B...  the first argument that is not empty
myos_or() { for _a in "$@"; do [ -n "$_a" ] && { printf '%s' "$_a"; return 0; }; done; }

# myos_patsubst PATTERN REPLACEMENT LIST
# The pattern holds one %, standing for any text; the replacement puts it back.
myos_patsubst() {
  _pre=${1%%%*}; _suf=${1#*%}
  _rpre=${2%%%*}; _rsuf=${2#*%}
  _out=
  for _w in $3; do
    case $_w in
      "$_pre"*"$_suf")
        _stem=${_w#"$_pre"}; _stem=${_stem%"$_suf"}
        _out="${_out:+$_out }$_rpre$_stem$_rsuf" ;;
      *) _out="${_out:+$_out }$_w" ;;
    esac
  done
  printf '%s' "$_out"
}

# myos_filter PATTERNS LIST / myos_filter_out PATTERNS LIST
# A make pattern uses % where a shell pattern uses *.
myos_filter() {
  _pats=$(printf '%s' "$1" | tr '%' '*')
  _out=
  for _w in $2; do
    for _p in $_pats; do
      # shellcheck disable=SC2254  # the pattern is meant to glob
      case $_w in $_p) _out="${_out:+$_out }$_w"; break ;; esac
    done
  done
  printf '%s' "$_out"
}
myos_filter_out() {
  _pats=$(printf '%s' "$1" | tr '%' '*')
  _out=
  for _w in $2; do
    _keep=yes
    for _p in $_pats; do
      # shellcheck disable=SC2254  # the pattern is meant to glob
      case $_w in $_p) _keep=no; break ;; esac
    done
    [ "$_keep" = yes ] && _out="${_out:+$_out }$_w"
  done
  printf '%s' "$_out"
}

# myos_addprefix PREFIX LIST / myos_addsuffix SUFFIX LIST
myos_addprefix() { _out=; for _w in $2; do _out="${_out:+$_out }$1$_w"; done; printf '%s' "$_out"; }
myos_addsuffix() { _out=; for _w in $2; do _out="${_out:+$_out }$_w$1"; done; printf '%s' "$_out"; }

# myos_b64url  read stdin, write url-safe base64 without padding
myos_b64url() { openssl enc -A -base64 | tr '+/' '-_' | tr -d '='; }

# myos_jwt HEADER PAYLOAD SECRET  a HS256 JSON web token
# Ported from the JWT macro of make/def.mk, which supabase uses to derive its
# anon and service keys from one secret. The make macro split on the commas of
# the payload; this one does not.
myos_jwt() {
  _h=${1:-'{"alg":"HS256","typ":"JWT"}'}
  _p=$2
  _s=$3
  _hb=$(printf '%s' "$_h" | myos_b64url)
  _pb=$(printf '%s' "$_p" | myos_b64url)
  _sig=$(printf '%s' "$_hb.$_pb" | openssl dgst -sha256 -binary -hmac "$_s" | myos_b64url)
  printf '%s.%s.%s' "$_hb" "$_pb" "$_sig"
}
