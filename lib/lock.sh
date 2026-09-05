#shellcheck shell=sh
# lock: one state-changing verb at a time per project ($WORKDIR/.myos/lock.<project>)
myos_lock() {
  _lk=$MYOS_WORKDIR/.myos/lock.$MYOS_PROJECT
  mkdir -p "$MYOS_WORKDIR/.myos" 2>/dev/null || :
  if ! mkdir "$_lk" 2>/dev/null; then myos_die 5 "$MYOS_PROJECT is locked by another run ($_lk)"; fi
  MYOS_LOCKED="${MYOS_LOCKED:+$MYOS_LOCKED$NL}$_lk"
  trap 'myos_unlock_all' EXIT
}
myos_unlock() { rmdir "$MYOS_WORKDIR/.myos/lock.$MYOS_PROJECT" 2>/dev/null || :; }
myos_unlock_all() {
  _ua_ifs=$IFS; IFS=$NL; set -f
  for _ua_l in ${MYOS_LOCKED:-}; do rmdir "$_ua_l" 2>/dev/null || :; done
  IFS=$_ua_ifs; set +f
}
