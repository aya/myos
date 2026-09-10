#shellcheck shell=sh
# target: which docker endpoint a verb talks to. `--target NAME` (or
# MYOS_TARGET) names it, and the value MYOS_TARGET_<NAME> holds it, so a target
# is declared wherever values are declared: $WORKDIR/.env of the project, a
# .env of a stack, engine.settings. No new file format and no inventory of its
# own: the repository that holds the stacks holds the targets.
#   MYOS_TARGET_SONIC=ssh://ops@sonic.example.org   -> DOCKER_HOST
#   MYOS_TARGET_HCO=context:hco                     -> DOCKER_CONTEXT
# An unknown target is an error (exit 3, as an unknown stack): the empty value
# of a name nobody declared would mean "the local socket", so a typo would
# deploy here instead of there. It is resolved once, before any verb runs, so
# the failure comes before the first network is created; a target therefore
# belongs to the project ($WORKDIR/.env) or to the environment, not to a stack.
# The assignment is written last on the docker call, so the target wins over a
# value of the same name a stack may carry.

myos_docker() { # ARGS...: docker on the target, for the calls that are not compose
  myos_target_env
  if [ -n "$R" ]; then env "$R" docker "$@"; else docker "$@"; fi
}

myos_target_env() { # -> R: the assignment the docker call needs, unquoted
  R=
  [ -n "${MYOS_TARGET:-}" ] || return 0
  fn_upper "$MYOS_TARGET"; _tg_n=$R
  myos_var "MYOS_TARGET_$_tg_n"; _tg_v=$R
  [ -n "$_tg_v" ] || myos_die 3 "unknown target $MYOS_TARGET (declare MYOS_TARGET_$_tg_n)"
  case $_tg_v in
    context:*) R="DOCKER_CONTEXT=${_tg_v#context:}" ;;
    *://*)     R="DOCKER_HOST=$_tg_v" ;;
    *)         myos_die 3 "bad target $MYOS_TARGET: $_tg_v is neither scheme://... nor context:<name>" ;;
  esac
}
