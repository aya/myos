#shellcheck shell=sh
# swarm: the backend that deploys to a Docker Swarm. `--backend swarm` (or
# MYOS_BACKEND=swarm) sends here the verbs whose call differs; the resolution
# of a stack is untouched, only the call changes. `docker stack deploy` reads
# one file, so the resolved files are rendered by `compose config` first: the
# same six layers of values, the same overlays, one deployment.
#   up     compose config | docker stack deploy -c - <project>
#   down   docker stack rm <project>
#   ps     docker stack services <project>
#   logs   docker service logs <project>_<service>   (SERVICE is required)
#   config the render, unchanged: it is what gets deployed
# --prune is not passed unless asked: a project is deployed one reference at a
# time, so pruning `up host/consul` would remove the services of host/fabio.
# What swarm ignores in a compose file (build:, depends_on:, container_name:,
# restart:) is the business of the policy gate, not of this file: a stack that
# needs a build has no image to deploy, and saying so is its job.

myos_swarm_cmd() { # -> R: the docker command with its target, for display
  myos_target_env; _sw_t=$R
  R="${_sw_t:+$_sw_t }docker --log-level=error"
}

myos_swarm_run() { # ARGS...: print under dry run, run otherwise
  myos_swarm_cmd; _sw_c=$R
  if [ "$MYOS_DRYRUN" = true ]; then printf '%s %s\n' "$_sw_c" "$*"; return 0; fi
  myos_target_env
  if [ -n "$R" ]; then env "$R" docker --log-level=error "$@"; else docker --log-level=error "$@"; fi
}

# myos_swarm_deploy_cmd -> R: the deploy side of the pipe, words quoted
myos_swarm_deploy_cmd() {
  myos_target_env; _sd_e=
  [ -n "$R" ] && { myos_shquote "$R"; _sd_e="$R "; }
  myos_shquote "$MYOS_PROJECT"
  R="env ${_sd_e}docker --log-level=error stack deploy --with-registry-auth${MYOS_PRUNE:+ --prune} --detach=false -c - $R"
}

myos_swarm_deploy() {
  [ -n "$MYOS_STACK_FILES" ] || { myos_warn "no compose file for $MYOS_STACK"; return 0; }
  if [ "$MYOS_DRYRUN" = true ]; then
    myos_compose_cmd; _sw_r=$R
    myos_swarm_cmd; printf '%s config | %s stack deploy --with-registry-auth%s --detach=false -c - %s\n' \
      "$_sw_r" "$R" "${MYOS_PRUNE:+ --prune}" "$MYOS_PROJECT"
    return 0
  fi
  myos_compose_env; _sw_pre=$R
  myos_compose_bin; _sw_pre="$_sw_pre $R"
  _sw_old=$IFS; IFS=$NL; set -f
  for _sw_x in $MYOS_STACK_FILES; do myos_shquote "$_sw_x"; _sw_pre="$_sw_pre -f $R"; done
  IFS=$_sw_old; set +f
  myos_shquote "$MYOS_PROJECT"; _sw_pre="$_sw_pre -p $R config"
  myos_swarm_deploy_cmd; _sw_dep=$R
  eval "env $_sw_pre | $_sw_dep"
}

# the overlays a swarm needs: the private and public networks of the model,
# attachable so a one-off container can still join them
myos_swarm_networks_ensure() {
  _sn_have=
  [ "$MYOS_DRYRUN" = true ] || _sn_have=$(myos_swarm_run network ls --format '{{.Name}}' 2>/dev/null)
  myos_swarm_cmd; _sn_c=$R
  for _sn_n in "$MYOS_NETWORK_PRIVATE" "$MYOS_NETWORK_PUBLIC"; do
    case "$NL$_sn_have$NL" in *"$NL$_sn_n$NL"*) ;;
      *) if [ "$MYOS_DRYRUN" = true ]; then printf '%s network create --driver overlay --attachable %s\n' "$_sn_c" "$_sn_n"
         else myos_swarm_run network create --driver overlay --attachable "$_sn_n" >/dev/null; fi ;;
    esac
  done
}

myos_swarm_up()     { myos_swarm_networks_ensure; myos_swarm_deploy; }
myos_swarm_down()   { myos_swarm_run stack rm "$MYOS_PROJECT"; }
myos_swarm_ps()     { myos_swarm_run stack services "$MYOS_PROJECT"; }
myos_swarm_logs()   {
  [ -n "$MYOS_SERVICE" ] || myos_die 2 "logs on the swarm backend needs SERVICE=<name>: docker service logs takes one service"
  myos_swarm_run service logs --follow --tail=100 "${MYOS_PROJECT}_$MYOS_SERVICE"
}
