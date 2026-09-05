#shellcheck shell=sh
# status: the services of the project from `compose ps --format json`

# myos_ps -> R: NL list of "service state health" of the current project
myos_ps() {
  myos_compose_cmd; _ps_cmd=$R
  _ps_json=$($_ps_cmd ps --format json 2>/dev/null | sed -e 's/^\[//' -e 's/\]$//' -e 's/},{/}\
{/g')
  R=$(printf '%s\n' "$_ps_json" | sed -n 's/.*"Service": *"\([^"]*\)".*"State": *"\([^"]*\)".*"Health": *"\([^"]*\)".*/\1 \2 \3/p')
}
myos_verb_status() {
  if [ "$MYOS_DRYRUN" = true ]; then myos_compose ps --format json; return 0; fi
  myos_ps; _st_rows=$R; _st_bad=
  _st_ifs=$IFS; IFS=$NL; set -f
  for _st_r in $_st_rows; do
    IFS=$_st_ifs; set +f
    set -- $_st_r
    if [ "$MYOS_OUTPUT" = json ]; then
      printf '{"verb":"status","project":"%s","service":"%s","state":"%s","health":"%s"}\n' "$MYOS_PROJECT" "$1" "$2" "${3:-}"
    else
      printf '%s %s %s %s\n' "$MYOS_PROJECT" "$1" "$2" "${3:-}"
    fi
    [ "$2" = running ] || _st_bad="$_st_bad $1"
    IFS=$NL; set -f
  done
  IFS=$_st_ifs; set +f
  if [ -n "$MYOS_STRICT" ] && [ -n "$_st_bad" ]; then myos_event status "$MYOS_PROJECT" fail "not running:$_st_bad"; return 4; fi
  return 0
}

# myos_wait_healthy: poll until every service runs (and is healthy when it has a check)
myos_wait_healthy() {
  _wh_deadline=$(( $(date +%s) + ${MYOS_HEALTH_TIMEOUT:-120} ))
  while :; do
    myos_ps; _wh_bad=
    _wh_ifs=$IFS; IFS=$NL; set -f
    for _wh_r in $R; do IFS=$_wh_ifs; set +f; set -- $_wh_r; { [ "$2" = running ] && { [ -z "${3:-}" ] || [ "$3" = healthy ]; }; } || _wh_bad="$_wh_bad $1"; IFS=$NL; set -f; done
    IFS=$_wh_ifs; set +f
    [ -z "$_wh_bad" ] && { myos_event health "$MYOS_PROJECT" ok; return 0; }
    [ "$(date +%s)" -ge "$_wh_deadline" ] && { myos_event health "$MYOS_PROJECT" fail "not healthy:$_wh_bad"; return 1; }
    sleep 1
  done
}
