#shellcheck shell=sh
# core: conventions of the engine.
# - a function returns its result in R, never through a subshell, so that it
#   can also set global state; only leaf helpers are used inside $( )
# - POSIX sh has no local variables: every temporary of a function is
#   prefixed with a short tag of that function (_p_ in myos_path...), so that
#   nested calls never clobber each other
# - a list of paths is newline separated (NL); a list of words is space
#   separated; loops over word lists run with globbing off (set -f), a word
#   may be a pattern such as *.example.org
# - exit codes: 0 ok, 1 failure, 2 usage, 3 unknown stack, 4 audit findings,
#   5 lock held
NL='
'
R=

myos_die() { # CODE MESSAGE...
  _die_code=$1; shift
  printf 'myos: %s\n' "$*" >&2
  exit "$_die_code"
}
myos_warn() { printf 'myos: warning: %s\n' "$*" >&2; }
myos_debug() { [ -n "${MYOS_DEBUG:-}" ] && printf 'myos: debug: %s\n' "$*" >&2; :; }

# myos_lower STRING -> R
myos_lower() { R=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]'); }
# myos_name STRING -> R: a compose project safe slug (lowercase, no . - _)
myos_name() { R=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '._-'); }
# myos_id STRING -> R: a shell identifier
myos_id() { R=$(printf '%s' "$1" | tr -c 'A-Za-z0-9' '_'); }

# myos_has WORD LIST -> 0 when WORD is one of the words of LIST
myos_has() {
  set -f
  for _has_w in $2; do [ "$_has_w" = "$1" ] && { set +f; return 0; }; done
  set +f; return 1
}
# myos_uniq LIST -> R: the words of LIST without repetition, order kept
myos_uniq() {
  set -f; _uq_out=
  for _uq_w in $1; do myos_has "$_uq_w" "$_uq_out" || _uq_out="${_uq_out:+$_uq_out }$_uq_w"; done
  set +f; R=$_uq_out
}
# myos_nl_uniq NL-LIST -> R: same on a newline separated list
myos_nl_uniq() {
  _nu_ifs=$IFS; IFS=$NL; set -f; _nu_out=
  for _nu_l in $1; do
    case "$NL$_nu_out$NL" in *"$NL$_nu_l$NL"*) ;; *) _nu_out="${_nu_out:+$_nu_out$NL}$_nu_l" ;; esac
  done
  IFS=$_nu_ifs; set +f; R=$_nu_out
}
# myos_nl_join NL-LIST SEP -> R
myos_nl_join() {
  _nj_ifs=$IFS; IFS=$NL; set -f; _nj_out=
  for _nj_l in $1; do _nj_out="${_nj_out:+$_nj_out$2}$_nj_l"; done
  IFS=$_nj_ifs; set +f; R=$_nj_out
}
# myos_sort_words LIST -> R: words sorted (C locale), unique
myos_sort_words() {
  [ -n "$1" ] || { R=; return 0; }
  set -f; R=$(printf '%s\n' $1 | LC_ALL=C sort -u | tr '\n' ' '); set +f; R=${R% }
}
# myos_realpath DIR -> R (empty when DIR does not exist)
myos_realpath() { R=$(cd "$1" 2>/dev/null && pwd -P); }
