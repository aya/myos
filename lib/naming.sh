#shellcheck shell=sh
# shellcheck disable=SC3028  # HOSTNAME is a myos variable, set by bin/myos
# naming: compose project name, service name, networks, user identity.
#
# Ported from make/apps/def.docker.mk (COMPOSE_PROJECT_NAME, COMPOSE_SERVICE_NAME),
# make/def.docker.mk (HOST_*/USER_*, DOCKER_NETWORK_*) and make/def.mk (RESU).

# myos_scope REF  -> host | user | cluster | app
# The first segment of a stack reference decides how the stack is named:
# host stacks are singletons of the machine (they bind privileged ports),
# user stacks are singletons of the user, cluster stacks are swarm namespaces.
myos_scope() {
  [ -n "${MYOS_SCOPE:-}" ] && { printf '%s' "$MYOS_SCOPE"; return 0; }
  case ${1%%/*} in
    host)         printf 'host' ;;
    User|user)    printf 'user' ;;
    cluster)      printf 'cluster' ;;
    *)            printf 'app' ;;
  esac
}

# myos_resu MAIL  -> user.domain identity of a mail address (make: RESU)
# Also sets MYOS_RESU_NIAMOD (reversed domain + reversed user) and
# MYOS_RESU_PATH (that identity as a path), used by the User stacks.
myos_resu() {
  _mail=$(myos_lower "${1:-}" | tr '+_' '..')
  case $_mail in
    *@*) ;;
    *) MYOS_RESU_NIAMOD=; MYOS_RESU_PATH=; printf '%s' "${USER:-}"; return 0 ;;
  esac
  _user=${_mail%@*}
  _domain=${_mail##*@}
  [ -n "$_domain" ] || { MYOS_RESU_NIAMOD=; MYOS_RESU_PATH=; printf '%s' "${USER:-}"; return 0; }
  _niamod=$(myos_reverse "$(printf '%s' "$_domain" | tr '.' ' ')" | tr ' ' '.')
  _resu=$(myos_reverse "$(printf '%s' "$_user" | tr '.' ' ')" | tr ' ' '.')
  MYOS_RESU_NIAMOD="$_niamod.$_resu"
  # consumed by the User stacks, not by this file
  # shellcheck disable=SC2034
  MYOS_RESU_PATH=$(printf '%s' "$MYOS_RESU_NIAMOD" | tr '.' '/')
  printf '%s.%s' "$_user" "$_domain"
}

# myos_project_name SCOPE USER ENV APP [PATH]
# host    -> HOST_COMPOSE_PROJECT_NAME, defaults to the hostname
# user    -> USER_COMPOSE_PROJECT_NAME, defaults to the RESU identity
# cluster -> the stack name: one namespace per swarm, not per user
# app     -> MYOS_PROJECT_FORMAT: user-env-app (default) or user-app-env (legacy)
myos_project_name() {
  _scope=$1; _user=$2; _env=$3; _app=$4; _path=${5:-}
  [ -n "${DOCKER_COMPOSE_PROJECT_NAME:-}" ] && { printf '%s' "$DOCKER_COMPOSE_PROJECT_NAME"; return 0; }
  case $_scope in
    host)
      printf '%s' "${HOST_COMPOSE_PROJECT_NAME:-${HOSTNAME:-localhost}}"; return 0 ;;
    user)
      if [ -n "${USER_COMPOSE_PROJECT_NAME:-}" ]; then printf '%s' "$USER_COMPOSE_PROJECT_NAME"
      else printf '%s' "$(myos_resu "${MAIL:-}" | tr '.' '-')"; fi
      return 0 ;;
    cluster)
      printf '%s' "${MYOS_CLUSTER_PROJECT:-$(myos_name "$_app")}"; return 0 ;;
  esac
  _n=$(myos_name "$_app")
  case ${MYOS_PROJECT_FORMAT:-user-env-app} in
    user-app-env) _out="$_user-$_n-$_env" ;;
    user-env-app) _out="$_user-$_env-$_n" ;;
    *) myos_die "$MYOS_E_USAGE" "unknown MYOS_PROJECT_FORMAT: ${MYOS_PROJECT_FORMAT}" ;;
  esac
  # the path fragment loses its slashes too (make: $(subst /,,$(subst -,,$(APP_PATH))))
  [ -n "$_path" ] && _out="$_out-$(myos_name "$_path" | tr -d /)"
  myos_lower "$_out" | tr -d '.'
}

# myos_service_name PROJECT  prefix of the SERVICE_<port>_NAME labels
myos_service_name() { printf '%s' "$1" | tr '_' '-'; }

# myos_network_default PROJECT
# The leading underscore keeps this network first in alphabetical order, so it
# is the first interface attached and service names never resolve across stacks.
# https://github.com/moby/libnetwork/issues/2093
myos_network_default() { printf '_%s' "$1"; }
myos_network_private() { printf '%s' "${DOCKER_NETWORK_PRIVATE:-${1}-${2}}"; }
myos_network_public()  { printf '%s' "${DOCKER_NETWORK_PUBLIC:-${1}}"; }

# myos_app_domain SCOPE USER DOMAIN
# The domain a stack is served on. A host stack is never prefixed by the user:
# it belongs to the machine.
myos_app_domain() {
  _scope=$1; _u=$2; _dom=$3
  if [ "$_scope" != host ] && [ "${APP_HOST_MULTI_USER:-false}" = true ]; then
    printf '%s.%s' "$_u" "$_dom"
  else
    printf '%s' "$_dom"
  fi
}

# myos_app_host SCOPE USER ENV APP DOMAIN HOSTNAME
# A host stack is served on <hostname>.<domain>; anything else is prefixed by
# the environment unless the environment is the main one.
myos_app_host() {
  _scope=$1; _u=$2; _env=$3; _app=$4; _dom=$5; _host=$6
  _multi_env=${APP_HOST_MULTI_ENV:-}
  if [ -z "$_multi_env" ]; then
    case $_env in local|master|main) _multi_env=false ;; *) _multi_env=true ;; esac
  fi
  _prefix=
  if [ "$_scope" = host ]; then _prefix="$_host."
  elif [ "$_multi_env" = true ]; then _prefix="$_env."
  fi
  _name=
  [ "${APP_HOST_MULTI_APP:-false}" = true ] && _name="$(myos_name "$_app")."
  _out="$_prefix$_name$(myos_app_domain "$_scope" "$_u" "$_dom")"
  # a host stack behind the load balancer also answers on the bare domain
  [ "$_scope" = host ] && [ -n "${HOST_LB:-}" ] && _out="$_out $_dom"
  printf '%s' "$_out"
}

# myos_app_uri HOST [PATH]  the base uri the fabio tags are built on;
# it always ends with a slash
myos_app_uri() {
  _out=
  for _h in $1; do _out="${_out:+$_out }$_h/${2:-}"; done
  printf '%s' "$_out"
}
