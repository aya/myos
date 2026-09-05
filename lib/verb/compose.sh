#shellcheck shell=sh
# The verbs that are one docker compose call on the resolved stacks of a
# project. myos_compose ARGS... runs (or prints, under dry run) the call with
# the files of the current project; the values referenced by the files are
# exported to it.

myos_compose_cmd() { # -> R: the command prefix, files and project included
  _c_f=; _c_old=$IFS; IFS=$NL; set -f
  for _c_x in $MYOS_STACK_FILES; do _c_f="$_c_f -f $_c_x"; done
  IFS=$_c_old; set +f
  R="docker --log-level=error compose --ansi=auto$_c_f -p $MYOS_PROJECT"
}

myos_run() { # COMMAND...: print under dry run, run otherwise
  if [ "$MYOS_DRYRUN" = true ]; then printf '%s\n' "$*"; return 0; fi
  "$@"
}

myos_compose() { # ARGS...
  [ -n "$MYOS_STACK_FILES" ] || { myos_warn "no compose file for $MYOS_STACK"; return 0; }
  myos_compose_cmd; _c_cmd=$R
  if [ "$MYOS_DRYRUN" = true ]; then printf '%s %s\n' "$_c_cmd" "$*"; return 0; fi
  myos_env_vars; _c_exports=
  set -f
  for _c_v in $R; do
    myos_var "$_c_v"; [ -n "$R" ] && _c_exports="$_c_exports$NL$_c_v=$R"
  done
  set +f
  _c_old=$IFS; IFS=$NL
  # shellcheck disable=SC2086
  env $_c_exports $_c_cmd "$@"; _c_rc=$?
  IFS=$_c_old
  return $_c_rc
}

myos_networks_ensure() {
  _c_have=
  [ "$MYOS_DRYRUN" = true ] || _c_have=$(docker network ls --format '{{.Name}}' 2>/dev/null)
  for _c_n in "$MYOS_NETWORK_PRIVATE" "$MYOS_NETWORK_PUBLIC"; do
    case "$NL$_c_have$NL" in *"$NL$_c_n$NL"*) ;;
      *) if [ "$MYOS_DRYRUN" = true ]; then printf 'docker network create %s\n' "$_c_n"; else docker network create "$_c_n" >/dev/null; fi ;;
    esac
  done
}

myos_verb_up()      { myos_networks_ensure; myos_compose up -d ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_down()    { myos_compose down; }
myos_verb_build()   { myos_compose build; }
myos_verb_config()  { myos_compose config; }
myos_verb_logs()    { myos_compose logs --follow --tail=100 ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_ps()      { myos_compose ps; }
myos_verb_status()  { myos_compose ps; }
myos_verb_restart() { myos_compose restart ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_start()   { myos_compose start ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_stop()    { myos_compose stop ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_recreate(){ myos_compose up -d --force-recreate ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_connect() { myos_compose exec "${MYOS_SERVICE:-$MYOS_STACK_NAME}" /bin/sh; }
myos_verb_exec()    { myos_compose exec -T "${MYOS_SERVICE:-$MYOS_STACK_NAME}" sh -c "$MYOS_ARGS"; }
myos_verb_run()     { myos_compose run --rm "${MYOS_SERVICE:-$MYOS_STACK_NAME}" $MYOS_ARGS; }
myos_verb_scale()   { myos_compose up -d --scale "${MYOS_SERVICE:-$MYOS_STACK_NAME}=${MYOS_NUM:-1}"; }
