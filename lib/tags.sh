#shellcheck shell=sh
# tags: fabio route tags derived from stack variables.
#
# Ported from make/apps/def.mk (uri, url, urlprefix, urlprefixs, tagprefix,
# envprefix, servicenvs). Registrator publishes the SERVICE_<port>_TAGS label
# to consul, fabio routes on the urlprefix- tags it finds there.
#
# Every lookup goes through myos_var (lib/var.sh), so a stack setting may be a
# plain value or a lazy default, and the two behave the same here.

# myos_uri SERVICE PORT [BASE_URI]
# <service>.<base uri>, unless <SERVICE>_SERVICE[_<port>]_NAME overrides the prefix
myos_uri() {
  _svc=$1; _port=${2:-}; _base=${3:-${APP_URI:-}}
  _u=$(myos_upper "$_svc")
  _name=$(myos_var "${_u}_SERVICE_${_port}_NAME")
  [ -n "$_name" ] || _name=$(myos_var "${_u}_SERVICE_NAME")
  [ -n "$_name" ] || _name=$_svc
  _out=
  for _b in $_base; do _out="${_out:+$_out }${_name}.${_b}"; done
  printf '%s' "$_out"
}

# myos_url SERVICE PORT [BASE_URI]
myos_url() {
  _out=
  for _u in $(myos_uri "$@"); do _out="${_out:+$_out }${APP_SCHEME:-http}://$_u"; done
  printf '%s' "$_out"
}

# myos_urlprefix [PATH] [OPTS] [URIS]
# one comma separated "urlprefix-<uri><path>* [opts]" per uri
myos_urlprefix() {
  _path=${1:-}; _opts=${2:-}; _uris=${3:-${APP_URI:-}}
  _out=
  for _u in $_uris; do
    _tag="urlprefix-${_u}${_path}${MYOS_URL_SUFFIX:-*}${_opts:+ $_opts}"
    _out="${_out:+$_out,}$_tag"
  done
  printf '%s' "$_out"
}

# myos_envprefix STACK PORT KEYS...
# "key=value" for each <STACK>_SERVICE_<port>_<KEY> that is set
myos_envprefix() {
  _stack=$1; _port=$2; shift 2
  _out=
  for _k in "$@"; do
    _v=$(myos_var "$(myos_upper "${_stack}_SERVICE_${_port}_${_k}")")
    [ -n "$_v" ] && _out="${_out:+$_out }${_k}=${_v}"
  done
  printf '%s' "$_out"
}

# myos_tagprefix STACK PORT [URI_KEYS...]
# the fabio tag of a service, assembled from its PATH, OPTS and URIS variables
myos_tagprefix() {
  _stack=$1; _port=$2; shift 2
  _u=$(myos_upper "$_stack")
  _path=$(myos_var "${_u}_SERVICE_${_port}_PATH"); [ -n "$_path" ] || _path=$(myos_var "${_u}_SERVICE_PATH")
  _opts=$(myos_var "${_u}_SERVICE_${_port}_OPTS"); [ -n "$_opts" ] || _opts=$(myos_var "${_u}_SERVICE_OPTS")
  [ -n "$_opts" ] || _opts=$(myos_envprefix "$_stack" "$_port" allow auth deny prepend proto register strip)
  _uris=
  for _k in "$@"; do
    _v=$(myos_var "${_u}_SERVICE_${_port}_${_k}"); [ -n "$_v" ] && _uris="${_uris:+$_uris }$_v"
  done
  [ -n "$_uris" ] || _uris=$(myos_var "${_u}_SERVICE_${_port}_URIS")
  [ -n "$_uris" ] || _uris=$(myos_uri "$_stack" "$_port")
  myos_urlprefix "$_path" "$_opts" "$_uris"
}

# myos_servicenvs STACK GROUP KEY
# Collect <STACK>_SERVICE_<env>_<KEY> for every env listed in
# <STACK>_SERVICE_<GROUP>_ENVS. Used to build a list of listeners out of one
# variable per protocol.
myos_servicenvs() {
  _s=$(myos_upper "$1"); _g=$(myos_upper "$2"); _k=$(myos_upper "$3")
  _out=
  for _e in $(myos_var "${_s}_SERVICE_${_g}_ENVS"); do
    _v=$(myos_var "${_s}_SERVICE_$(myos_upper "$_e")_${_k}")
    [ -n "$_v" ] && _out="${_out:+$_out }$_v"
  done
  printf '%s' "$_out"
}
