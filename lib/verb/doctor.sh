#shellcheck shell=sh
# doctor: what this host and this project lack. Every check is one event
# "<id> ok|warn|fail [hint]"; a stack adds its own through a doctor hook
# printing lines of the same shape; exit 4 when a check fails.

myos_check() { # ID STATUS [HINT]
  myos_event "$1" "$MYOS_PROJECT" "$2" "${3:-}"
  [ "$2" = fail ] && MYOS_DOCTOR_FAILED=1
  return 0
}
myos_verb_doctor() {
  MYOS_DOCTOR_FAILED=
  _dc_v=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
  if [ -n "$_dc_v" ]; then myos_check docker ok "$_dc_v"; else myos_check docker fail "docker is not reachable"; fi
  myos_compose_bin; _dc_bin=$R
  case $_dc_bin in docker-compose*) _dc_c=$(docker-compose version --short 2>/dev/null) ;; *) _dc_c=$(docker compose version --short 2>/dev/null) ;; esac
  if [ -z "$_dc_c" ]; then
    if command -v docker-compose >/dev/null 2>&1; then myos_check compose fail "$_dc_bin does not answer; set DOCKER_COMPOSE=docker-compose in the machine config to use the binary"
    else myos_check compose fail "no docker compose plugin nor docker-compose binary"; fi
  elif [ "$(printf '%s\n2.21.0\n' "$_dc_c" | sort -t. -k1,1n -k2,2n -k3,3n | head -n1)" = "2.21.0" ]; then myos_check compose ok "$_dc_c"
  else myos_check compose fail "compose $_dc_c is older than 2.21"; fi
  case $_dc_bin in docker-compose*) myos_check compose-bin warn "the docker-compose binary is used: install the compose plugin when you can" ;; esac
  command -v just >/dev/null 2>&1 && myos_check just ok || myos_check just warn "just is not installed: no justfile hooks, no just --list"
  command -v jq >/dev/null 2>&1 && myos_check jq ok || myos_check jq warn "jq is not installed"
  myos_path; myos_nl_join "$R" ' '; myos_check path ok "$R"
  # the .env against the .env.dist of the stacks
  myos_env_file; _dc_env=$R; myos_env_dists; _dc_missing=
  _dc_ifs=$IFS; IFS=$NL; set -f
  for _dc_f in $R; do
    IFS=$_dc_ifs; set +f
    [ -f "$_dc_f" ] || { IFS=$NL; set -f; continue; }
    for _dc_k in $(sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' "$_dc_f"); do
      myos_env_has "$_dc_k" "$_dc_env" || eval "[ -n \"\${$_dc_k+set}\" ]" || _dc_missing="$_dc_missing $_dc_k"
    done
    IFS=$NL; set -f
  done
  IFS=$_dc_ifs; set +f
  if [ -n "$_dc_missing" ]; then myos_check env fail "missing from $_dc_env:$_dc_missing (run myos env-update)"; else myos_check env ok; fi
  # the values the compose files reference
  myos_env_vars; _dc_empty=
  set -f; for _dc_k in $R; do myos_var "$_dc_k"; [ -n "$R" ] || _dc_empty="$_dc_empty $_dc_k"; done; set +f
  [ -n "$_dc_empty" ] && myos_check values warn "empty:$_dc_empty" || myos_check values ok
  # networks
  _dc_nets=$(docker network ls --format '{{.Name}}' 2>/dev/null); _dc_nomissing=
  for _dc_n in "$MYOS_NETWORK_PRIVATE" "$MYOS_NETWORK_PUBLIC"; do case "$NL$_dc_nets$NL" in *"$NL$_dc_n$NL"*) ;; *) _dc_nomissing="$_dc_nomissing $_dc_n" ;; esac; done
  [ -n "$_dc_nomissing" ] && myos_check network warn "missing:$_dc_nomissing (created by up)" || myos_check network ok
  # locks
  [ -d "$MYOS_WORKDIR/.myos/lock.$MYOS_PROJECT" ] && myos_check lock warn "$MYOS_PROJECT is locked" || myos_check lock ok
  # the doctor hooks of the stacks: one check per line
  myos_hook_dirs
  _dc_ifs=$IFS; IFS=$NL; set -f
  for _dc_d in $R; do
    IFS=$_dc_ifs; set +f
    myos_hook_find doctor "$_dc_d"
    if [ -n "$R" ]; then
      myos_hook_run doctor "$_dc_d" "$R" | while IFS= read -r _dc_l; do
        set -- $_dc_l; [ $# -ge 2 ] && myos_check "$1" "$2" "${3:+$(shift 2; echo "$*")}"
      done
      # the loop ran in a subshell: read the failure back from its output
    fi
    IFS=$NL; set -f
  done
  IFS=$_dc_ifs; set +f
  [ -z "$MYOS_DOCTOR_FAILED" ] || return 4
  return 0
}
