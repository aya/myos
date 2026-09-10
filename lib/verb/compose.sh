#shellcheck shell=sh
# The verbs that are one docker compose call on the resolved stacks of a
# project. myos_compose ARGS... runs (or prints, under dry run) the call with
# the files of the current project; the values referenced by the files are
# exported to it.

# myos_compose_bin -> R: the compose command. DOCKER_COMPOSE when set; the
# compose plugin when it answers; the docker-compose binary otherwise.
# The plugin file being present is not enough: a binary the docker CLI cannot
# load (wrong architecture, quarantined on macOS -- `failed to fetch metadata:
# signal: killed`) sits in the right directory and never runs. So the plugin is
# asked whether it answers. That costs one fork, memoised for the run, and it
# buys the difference between a working default and a manual DOCKER_COMPOSE=.
myos_compose_bin() {
  [ -n "${MYOS_COMPOSE_BIN:-}" ] && { R=$MYOS_COMPOSE_BIN; return 0; }
  if [ -n "${DOCKER_COMPOSE:-}" ]; then R=$DOCKER_COMPOSE
  else
    R=
    for _cb_p in "${HOME:-/nonexistent}/.docker/cli-plugins" /usr/local/lib/docker/cli-plugins /usr/lib/docker/cli-plugins /usr/libexec/docker/cli-plugins /opt/homebrew/lib/docker/cli-plugins "${DOCKER_CONFIG:-/nonexistent}/cli-plugins"; do
      [ -x "$_cb_p/docker-compose" ] || continue
      docker compose version >/dev/null 2>&1 && R="docker --log-level=error compose --ansi=auto"
      break
    done
    [ -n "$R" ] || { if command -v docker-compose >/dev/null 2>&1; then R=docker-compose; else R="docker --log-level=error compose --ansi=auto"; fi; }
  fi
  MYOS_COMPOSE_BIN=$R
}
myos_compose_cmd() { # -> R: the command prefix, files and project included
  _c_f=; _c_old=$IFS; IFS=$NL; set -f
  for _c_x in $MYOS_STACK_FILES; do _c_f="$_c_f -f $_c_x"; done
  IFS=$_c_old; set +f
  myos_target_env; _c_t=$R
  myos_compose_bin; R="${_c_t:+$_c_t }$R$_c_f -p $MYOS_PROJECT"
}

# myos_compose_env -> R: the values the files reference, as quoted assignments
myos_compose_env() {
  myos_env_vars; _ce_pre=
  set -f
  for _ce_v in $R; do
    myos_var "$_ce_v"; [ -n "$R" ] || continue
    myos_shquote "$_ce_v=$R"; _ce_pre="$_ce_pre $R"
  done
  set +f
  R=$_ce_pre
}

myos_run() { # COMMAND...: print under dry run, run otherwise
  if [ "$MYOS_DRYRUN" = true ]; then printf '%s\n' "$*"; return 0; fi
  "$@"
}

myos_compose() { # ARGS...
  [ -n "$MYOS_STACK_FILES" ] || { myos_warn "no compose file for $MYOS_STACK"; return 0; }
  myos_compose_cmd; _c_cmd=$R
  if [ "$MYOS_DRYRUN" = true ]; then printf '%s %s\n' "$_c_cmd" "$*"; return 0; fi
  # the exports and the command words are quoted one by one, so that env
  # sees assignments, then the command, then the verb arguments as given.
  # The target comes after them: it wins over a value of the same name.
  myos_compose_env; _c_pre=$R
  myos_target_env; [ -n "$R" ] && { myos_shquote "$R"; _c_pre="$_c_pre $R"; }
  myos_compose_bin; _c_pre="$_c_pre $R"
  _c_old=$IFS; IFS=$NL; set -f
  for _c_x in $MYOS_STACK_FILES; do myos_shquote "$_c_x"; _c_pre="$_c_pre -f $R"; done
  IFS=$_c_old; set +f
  myos_shquote "$MYOS_PROJECT"; _c_pre="$_c_pre -p $R"
  eval "set -- $_c_pre \"\$@\""
  env "$@"
}

myos_networks_ensure() {
  _c_have=
  myos_target_env; _c_t=$R   # the networks belong to the endpoint the stack goes to
  [ "$MYOS_DRYRUN" = true ] || _c_have=$(myos_docker network ls --format '{{.Name}}' 2>/dev/null)
  for _c_n in "$MYOS_NETWORK_PRIVATE" "$MYOS_NETWORK_PUBLIC"; do
    case "$NL$_c_have$NL" in *"$NL$_c_n$NL"*) ;;
      *) if [ "$MYOS_DRYRUN" = true ]; then printf '%sdocker network create %s\n' "${_c_t:+$_c_t }" "$_c_n"; else myos_docker network create "$_c_n" >/dev/null; fi ;;
    esac
  done
}

myos_verb_up() {
  myos_policy_enforce || return $?
  if [ "$MYOS_BACKEND" = swarm ]; then
    # no build here: swarm ignores build:, the image is pushed before the deploy
    myos_up_needs_bootstrap && { myos_verb_env_update || return 1; }
    myos_swarm_up || return 1
  else
    if myos_up_needs_bootstrap; then myos_verb_bootstrap || return 1; else myos_networks_ensure; fi
    myos_compose up -d ${MYOS_SERVICE:+"$MYOS_SERVICE"} || return 1
  fi
  if [ -n "$MYOS_FIREWALL" ] && [ "$MYOS_STACK_SCOPE" = host ]; then MYOS_SUB=apply; myos_firewall_apply; fi
}
myos_verb_down()    { [ "$MYOS_BACKEND" = swarm ] && { myos_swarm_down; return $?; }; myos_compose down; }
myos_verb_build()   { myos_compose build; }
myos_verb_config()  { myos_compose config; }
myos_verb_logs()    { [ "$MYOS_BACKEND" = swarm ] && { myos_swarm_logs; return $?; }; myos_compose logs --follow --tail=100 ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_ps()      { [ "$MYOS_BACKEND" = swarm ] && { myos_swarm_ps; return $?; }; myos_compose ps; }
myos_verb_status()  { myos_compose ps; }
myos_verb_restart() { myos_compose restart ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_start()   { myos_compose start ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_stop()    { myos_compose stop ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_recreate(){ myos_compose up -d --force-recreate ${MYOS_SERVICE:+"$MYOS_SERVICE"}; }
myos_verb_connect() { myos_compose exec "${MYOS_SERVICE:-$MYOS_STACK_NAME}" /bin/sh; }
myos_verb_exec()    { myos_compose exec -T "${MYOS_SERVICE:-$MYOS_STACK_NAME}" sh -c "$MYOS_ARGS"; }
myos_verb_run()     { myos_compose run --rm "${MYOS_SERVICE:-$MYOS_STACK_NAME}" $MYOS_ARGS; }
myos_verb_scale()   { myos_compose up -d --scale "${MYOS_SERVICE:-$MYOS_STACK_NAME}=${MYOS_NUM:-1}"; }
