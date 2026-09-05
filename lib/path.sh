#shellcheck shell=sh
# path: where stacks are looked up.
# MYOS_PATH (colon separated) or the default list, ascending precedence: the
# system, then the user, then the parent of the project, then the project.
# Only existing directories are kept, once each (realpath).

myos_path() { # -> R: NL list of stack directories, ascending precedence
  [ -n "${MYOS_PATH_CACHE:-}" ] && { R=$MYOS_PATH_CACHE; return 0; }
  if [ -n "${MYOS_PATH:-}" ]; then
    _p_cands=$(printf '%s' "$MYOS_PATH" | tr ':' '\n')
  else
    _p_cands=
    for _p_d in /usr/share /usr/local/share "${HOME:-/nonexistent}/.local/share" "$MYOS_WORKDIR/.." "$MYOS_WORKDIR"; do
      _p_cands="$_p_cands$NL$_p_d/myos/stack$NL$_p_d/stack"
    done
  fi
  _p_ifs=$IFS; IFS=$NL; set -f; _p_out=
  for _p_c in $_p_cands; do
    [ -d "$_p_c" ] || continue
    myos_realpath "$_p_c"; _p_c=$R
    case "$NL$_p_out$NL" in *"$NL$_p_c$NL"*) ;; *) _p_out="${_p_out:+$_p_out$NL}$_p_c" ;; esac
  done
  IFS=$_p_ifs; set +f
  MYOS_PATH_CACHE=$_p_out; R=$_p_out
}
