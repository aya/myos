#shellcheck shell=sh
# values: what the user set, layered. Highest first: the command line
# (KEY=VALUE), the environment, $WORKDIR/.env.<ENV>, $WORKDIR/.env, then the
# defaults of the stacks and of the engine. A value already known is never
# overwritten by a lower layer.

myos_values_load() {
  MYOS_VALUES=
  for _vl_f in "$MYOS_WORKDIR/.env.$MYOS_ENV" "$MYOS_WORKDIR/.env"; do
    [ -f "$_vl_f" ] || continue
    while IFS= read -r _vl_line || [ -n "$_vl_line" ]; do
      case $_vl_line in ''|'#'*|export\ *) case $_vl_line in export\ *) _vl_line=${_vl_line#export } ;; *) continue ;; esac ;; esac
      case $_vl_line in *=*) ;; *) continue ;; esac
      _vl_k=${_vl_line%%=*}; _vl_v=${_vl_line#*=}
      case $_vl_k in *[!A-Za-z0-9_]*|'') continue ;; esac
      case $_vl_v in \"*\") _vl_v=${_vl_v#\"}; _vl_v=${_vl_v%\"} ;; \'*\') _vl_v=${_vl_v#\'}; _vl_v=${_vl_v%\'} ;; esac
      eval "[ -n \"\${MYOS_CLI_$_vl_k+set}\" ] || [ -n \"\${$_vl_k+set}\" ] || [ -n \"\${MYOS_ENVFILE_$_vl_k+set}\" ] || MYOS_ENVFILE_$_vl_k=\$_vl_v"
    done < "$_vl_f"
  done
}

# myos_var NAME -> R (empty when unknown); origin in MYOS_ORIGIN
myos_var() {
  MYOS_ORIGIN=
  # a name built from a word that is not an identifier (*.ipns_SERVICE_NAME)
  # is simply unknown, as it was for make
  case $1 in *[!A-Za-z0-9_]*|'') R=; return 0 ;; esac
  eval "if [ -n \"\${MYOS_CLI_$1+set}\" ]; then R=\$MYOS_CLI_$1; MYOS_ORIGIN=cli
        elif [ -n \"\${$1+set}\" ]; then R=\$$1; MYOS_ORIGIN=env
        elif [ -n \"\${MYOS_ENVFILE_$1+set}\" ]; then R=\$MYOS_ENVFILE_$1; MYOS_ORIGIN=.env
        else R=; fi"
  [ -n "$MYOS_ORIGIN" ] && return 0
  eval "if [ -n \"\${MYOS_MEMO_$1+set}\" ]; then R=\$MYOS_MEMO_$1; MYOS_ORIGIN=\$MYOS_MEMO_ORIGIN_$1; fi"
  [ -n "$MYOS_ORIGIN" ] && return 0
  # a setting the stack forces, then its plain defaults, then its computed ones
  eval "_vv_kind=\${MYOS_SET_KIND_$1:-}"
  if [ "$_vv_kind" = forced ]; then myos_compute "$1"
  else
    eval "if [ -n \"\${MYOS_STACKENV_$1+set}\" ]; then R=\$MYOS_STACKENV_$1; MYOS_ORIGIN=stack; fi"
    [ -n "$MYOS_ORIGIN" ] || [ -z "$_vv_kind" ] || myos_compute "$1"
  fi
  if [ -n "$MYOS_ORIGIN" ]; then eval "MYOS_MEMO_$1=\$R; MYOS_MEMO_ORIGIN_$1=\$MYOS_ORIGIN"; MYOS_MEMO_NAMES="$MYOS_MEMO_NAMES $1"; return 0; fi
  # engine values
  case $1 in
    COMPOSE_FILE) myos_nl_join "$MYOS_STACK_FILES" ' ' ;;
    COMPOSE_PROJECT_NAME) R=$MYOS_PROJECT ;;
    COMPOSE_SERVICE_NAME) R=$(printf '%s' "$MYOS_PROJECT" | tr '_' '-') ;;
    COMPOSE_FILE_SUFFIX) myos_suffixes ;;
    STACK_DIR) myos_path; myos_nl_join "$R" ' ' ;;
    MYOS_STACK_DIR) R=${MYOS_STACK_DIRS##*"$NL"} ;;
    STACK) R=$MYOS_STACKS ;;
    APP) R=$MYOS_STACK_NAME ;;
    APP_NAME) myos_name "$MYOS_STACK_APP" ;;
    ENV) R=$MYOS_ENV ;;
    USER) R=$MYOS_USER ;;
    HOSTNAME) R=$MYOS_HOSTNAME ;;
    DOMAIN) R=$MYOS_DOMAIN ;;
    HOST_STACK) [ "$MYOS_STACK_SCOPE" = host ] && R=host || R= ;;
    HOST_COMPOSE_PROJECT_NAME) R=$MYOS_HOSTNAME ;;
    USER_COMPOSE_PROJECT_NAME) myos_resu; R=$(printf '%s' "$R" | tr '.' '-') ;;
    RESU) myos_resu ;;
    MAIL) R=${MAIL:-} ;;
    USER_STACK) [ "$MYOS_STACK_SCOPE" = user ] && R=User || R= ;;
    DOCKER_NETWORK) R=$MYOS_NETWORK ;;
    DOCKER_NETWORK_DEFAULT) R=$MYOS_NETWORK_DEFAULT ;;
    DOCKER_NETWORK_PRIVATE) R=$MYOS_NETWORK_PRIVATE ;;
    DOCKER_NETWORK_PUBLIC) R=$MYOS_NETWORK_PUBLIC ;;
    DOCKER_REPOSITORY) R=$(printf '%s' "$MYOS_PROJECT" | tr '_-' '//') ;;
    DOCKER_IMAGE_TAG) R=latest ;;
    DOCKER_IMAGES) myos_images ;;
    ENV_VARS) myos_env_vars ;;
    DRYRUN) R=$MYOS_DRYRUN ;;
    *) R= ;;
  esac
  [ -n "$R" ] && MYOS_ORIGIN=engine
}

# myos_images -> R: the images the stack directories can build (docker/<image>/Dockerfile)
myos_images() {
  R=; _vl_old=$IFS; IFS=$NL; set -f
  for _vl_d in $MYOS_STACK_DIRS $MYOS_WORKDIR; do
    IFS=$_vl_old; set +f
    for _vl_f in "$_vl_d"/docker/*/Dockerfile; do [ -f "$_vl_f" ] && { _vl_i=${_vl_f%/Dockerfile}; R="${R:+$R }${_vl_i##*/}"; }; done
    IFS=$NL; set -f
  done
  IFS=$_vl_old; set +f
  myos_uniq "$R"
}

# myos_env_vars -> R: the names referenced by the compose files (${VAR}, $VAR),
# plus the network names the framework overlay needs, sorted
myos_env_vars() {
  _vl_v="DOCKER_NETWORK_DEFAULT DOCKER_NETWORK_PRIVATE DOCKER_NETWORK_PUBLIC"
  if [ -n "$MYOS_STACK_FILES" ]; then
    # shellcheck disable=SC2086
    _vl_old=$IFS; IFS=$NL; set -f
    _vl_v="$_vl_v $(sed 's/\$\$//g' $MYOS_STACK_FILES | grep -oE '\$\{?[A-Z0-9_]+' | tr -d '{$' | tr '\n' ' ')"
    IFS=$_vl_old; set +f
  fi
  myos_sort_words "$_vl_v"
}
