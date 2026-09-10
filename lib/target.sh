#shellcheck shell=sh
# target: which docker endpoint a verb talks to. `--target NAME` (or
# MYOS_TARGET) names it, and the name is enough -- there is nothing to declare
# anywhere:
#   --target sonic              an ssh host, as ssh_config already knows it
#   --target ssh://ops@sonic    the endpoint written out, when the name is not
#                               enough (another account, another port)
#   --target tcp://host:2376    any docker endpoint
#   --target context:hco        a docker context
# A bare name is an ssh host on purpose: the inventory of a fleet is already
# written, once, in ssh_config -- and a repository can carry its own
# (.ssh/config included from ~/.ssh/config). Asking a project to repeat it in a
# variable was one indirection too many, and it made the target unreadable
# before $WORKDIR/.env existed, which broke the first `up` of a fresh clone.

myos_target_env() { # -> R: the assignment the docker call needs, unquoted
  R=
  [ -n "${MYOS_TARGET:-}" ] || return 0
  case $MYOS_TARGET in
    context:*) R="DOCKER_CONTEXT=${MYOS_TARGET#context:}" ;;
    *://*)     R="DOCKER_HOST=$MYOS_TARGET" ;;
    *[!A-Za-z0-9._-]*) myos_die 3 "bad target $MYOS_TARGET (an ssh host, scheme://..., or context:<name>)" ;;
    *)         R="DOCKER_HOST=ssh://$MYOS_TARGET" ;;
  esac
}

# myos_target_hostname -> R: the name of the machine the target is, empty when
# there is no target. Everything the model derives from the host -- the public
# network, the project of a host stack, the certificates -- is named after it,
# so taking the hostname of the workstation would put a deployment on a network
# named after the laptop that ran the command, where nothing else can find it.
# It is read from the target itself; `HOSTNAME=` on the command line overrides
# it when the ssh alias and the machine's own name differ.
myos_target_hostname() {
  R=
  [ -n "${MYOS_TARGET:-}" ] || return 0
  _th=$MYOS_TARGET
  case $_th in context:*) _th=${_th#context:} ;; *://*) _th=${_th#*://} ;; esac
  _th=${_th#*@}          # user@host
  _th=${_th%%:*}         # host:port
  _th=${_th%%/*}         # host/path
  _th=${_th%%.*}         # the short name, as the engine does for HOSTNAME
  R=$_th
}

myos_docker() { # ARGS...: docker on the target, for the calls that are not compose
  myos_target_env
  if [ -n "$R" ]; then env "$R" docker "$@"; else docker "$@"; fi
}
