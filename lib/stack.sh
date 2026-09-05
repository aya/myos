#shellcheck shell=sh
# stack: resolve a reference into directories, compose files, project name
# and networks. One call sets:
#   MYOS_STACK        the reference as given
#   MYOS_STACK_NAME   <name>            MYOS_STACK_SCOPE  host|user|app
#   MYOS_STACK_APP    what names the project (the first path segment, as the
#                     make engine did: every stack of host/ is one project)
#   MYOS_STACK_DIRS   NL list, ascending precedence
#   MYOS_STACK_OWN    NL list of the files of the stack directories
#   MYOS_STACK_OVERLAYS  the framework overlays (share/compose)
#   MYOS_STACK_FILES  both, in compose order (overlays last)
#   MYOS_PROJECT      compose project name
#   MYOS_NETWORK_DEFAULT/PRIVATE/PUBLIC

myos_scope() { # REF -> R: host|user|app
  case ${1%%/*} in host) R=host ;; User|user) R=user ;; *) R=app ;; esac
}

# myos_resu -> R: the user identity of the User stacks (make: RESU), derived
# from MAIL or USER@DOMAIN: <user>.<domain> lowercased, + and _ read as dots
myos_resu() {
  _sr_mail=${MAIL:-$MYOS_USER@$MYOS_DOMAIN}
  case $_sr_mail in
    *@*) myos_lower "${_sr_mail%%@*}"; _sr_u=$(printf '%s' "$R" | tr '+_' '..'); myos_lower "${_sr_mail##*@}"; _sr_d=$(printf '%s' "$R" | tr '+_' '..'); R=$_sr_u.$_sr_d ;;
    *) R=$MYOS_USER ;;
  esac
}

myos_project_name() { # SCOPE APP -> R
  if [ -n "${DOCKER_COMPOSE_PROJECT_NAME:-}" ]; then R=$DOCKER_COMPOSE_PROJECT_NAME; return 0; fi
  case $1 in
    host) R=${HOST_COMPOSE_PROJECT_NAME:-$MYOS_HOSTNAME} ;;
    user) if [ -n "${USER_COMPOSE_PROJECT_NAME:-}" ]; then R=$USER_COMPOSE_PROJECT_NAME; else myos_resu; R=$(printf '%s' "$R" | tr '.' '-'); fi ;;
    *)
      myos_name "$2"; _sr_n=$R
      case ${MYOS_PROJECT_FORMAT:-user-env-app} in
        user-app-env) R=$MYOS_USER-$_sr_n-$MYOS_ENV ;;
        *)            R=$MYOS_USER-$MYOS_ENV-$_sr_n ;;
      esac
      myos_lower "$R"; R=$(printf '%s' "$R" | tr -d '.')
      ;;
  esac
}

myos_stack_resolve() { # REF
  MYOS_STACK=$1
  myos_ref_parse "$1"
  MYOS_STACK_NAME=$MYOS_REF_NAME; MYOS_STACK_APP=$MYOS_REF_APP
  myos_scope "$1"; MYOS_STACK_SCOPE=$R
  myos_ref_dirs; MYOS_STACK_DIRS=$R
  if [ -z "$MYOS_STACK_DIRS" ]; then
    myos_path; myos_nl_join "$R" ' '
    myos_die 3 "stack $1 not found (searched: $R)"
  fi
  myos_suffixes; _sr_suf=$R
  _sr_ver=${MYOS_REF_VERSION:-latest}
  _sr_files=
  _sr_old=$IFS; IFS=$NL; set -f
  for _sr_d in $MYOS_STACK_DIRS; do
    IFS=$_sr_old; set +f
    myos_compose_files "$_sr_d" "docker-compose $MYOS_STACK_NAME" "$_sr_suf $_sr_ver" "$MYOS_ENV"
    [ -n "$R" ] && _sr_files="${_sr_files:+$_sr_files$NL}$R"
    IFS=$NL; set -f
  done
  IFS=$_sr_old; set +f
  myos_nl_uniq "$_sr_files"; MYOS_STACK_OWN=$R
  # framework overlays (networks and volumes of share/compose): always last,
  # after the files of every stack of the project
  MYOS_STACK_OVERLAYS=
  # a stack given as a path gets them when its files name a framework network
  if [ "$MYOS_REF_KIND" = search ] || { [ -n "$_sr_files" ] && grep -qs -E '(^|[[:space:]]|-[[:space:]])(private|public)([[:space:]]*:|[[:space:]]*$)' $_sr_files 2>/dev/null; }; then
    myos_compose_files "$MYOS/share/compose" "networks volumes" "$_sr_suf" "$MYOS_ENV"; MYOS_STACK_OVERLAYS=$R
  fi
  MYOS_STACK_FILES="$MYOS_STACK_OWN${MYOS_STACK_OVERLAYS:+$NL$MYOS_STACK_OVERLAYS}"
  myos_project_name "$MYOS_STACK_SCOPE" "$MYOS_STACK_APP"; MYOS_PROJECT=$R
  MYOS_NETWORK_DEFAULT=${DOCKER_NETWORK_DEFAULT:-_$MYOS_PROJECT}
  MYOS_NETWORK_PRIVATE=${DOCKER_NETWORK_PRIVATE:-$MYOS_USER-$MYOS_ENV}
  MYOS_NETWORK_PUBLIC=${DOCKER_NETWORK_PUBLIC:-$MYOS_HOSTNAME}
  if [ "$MYOS_STACK_SCOPE" = user ]; then MYOS_NETWORK=${DOCKER_NETWORK:-$MYOS_USER}; else MYOS_NETWORK=${DOCKER_NETWORK:-$MYOS_NETWORK_PRIVATE}; fi
  myos_settings_of_stack
}
