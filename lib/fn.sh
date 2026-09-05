#shellcheck shell=sh
# fn: the functions a .settings expression can call (@name), ports of the
# make macros the catalogue was written with. Every function returns in R.
# Lists are space separated words; a word may be a pattern (no globbing).
# A call may omit trailing arguments: every function reads ${2:-} and ${3:-} as ${2:-}.

fn_lower() { myos_lower "$1"; }
fn_upper() { case $1 in *[[:lower:]\-.]*) R=$(printf '%s' "$1" | tr '[:lower:]-.' '[:upper:]__') ;; *) R=$1 ;; esac; }
fn_name()  { myos_name "$1"; }
fn_strip() { set -f; set -- $1; R=$*; set +f; }
fn_words() { set -f; set -- $1; R=$#; set +f; }
fn_firstword() { set -f; set -- $1; R=${1:-}; set +f; }
fn_lastword()  { set -f; R=; for _fl_w in $1; do R=$_fl_w; done; set +f; }
fn_wordlist() { # START END LIST
  set -f; _wl_i=0; R=
  for _wl_w in ${3:-}; do _wl_i=$((_wl_i + 1)); [ "$_wl_i" -ge "$1" ] && [ "$_wl_i" -le "${2:-}" ] && R="${R:+$R }$_wl_w"; done
  set +f
}
fn_or()  { R=; for _or_a in "$@"; do fn_strip "$_or_a"; [ -n "$R" ] && { R=$_or_a; return 0; }; done; R=; }
fn_and() { R=; for _an_a in "$@"; do fn_strip "$_an_a"; [ -n "$R" ] || { R=; return 0; }; done; R=$_an_a; }
fn_if()  { fn_strip "$1"; if [ -n "$R" ]; then R=${2:-}; else R=${3:-}; fi; }
fn_addprefix() { set -f; R=; for _ap_w in ${2:-}; do R="${R:+$R }$1$_ap_w"; done; set +f; }
fn_addsuffix() { set -f; R=; for _as_w in ${2:-}; do R="${R:+$R }$_as_w$1"; done; set +f; }
fn_dir()    { set -f; R=; for _dr_w in $1; do case $_dr_w in */*) R="${R:+$R }${_dr_w%/*}/" ;; *) R="${R:+$R }./" ;; esac; done; set +f; }
fn_notdir() { set -f; R=; for _nd_w in $1; do R="${R:+$R }${_nd_w##*/}"; done; set +f; }
fn_join()   { set -f; R=; for _jn_w in ${2:-}; do R="${R:+$R$1}$_jn_w"; done; set +f; }

# fn_subst FROM TO TEXT: every occurrence of FROM becomes TO
fn_subst() {
  R=; _sb_t=${3:-}
  [ -n "$1" ] || { R=${3:-}; return 0; }
  while :; do
    case $_sb_t in
      *"$1"*) R="$R${_sb_t%%"$1"*}${2:-}"; _sb_t=${_sb_t#*"$1"} ;;
      *) R="$R$_sb_t"; return 0 ;;
    esac
  done
}

# fn_patsubst PATTERN REPLACEMENT LIST: % in PATTERN matches any text, and
# stands for it in REPLACEMENT; a word that does not match is kept
fn_patsubst() {
  set -f; R=
  _ps_pre=${1%%%*}; _ps_suf=${1#*%}; case $1 in *%*) _ps_pct=1 ;; *) _ps_pct= ;; esac
  _ps_rpre=${2%%%*}; _ps_rsuf=${2#*%}; case ${2:-} in *%*) _ps_rpct=1 ;; *) _ps_rpct= ;; esac
  for _ps_w in ${3:-}; do
    if [ -n "$_ps_pct" ]; then
      case $_ps_w in
        "$_ps_pre"*"$_ps_suf")
          _ps_stem=${_ps_w#"$_ps_pre"}; _ps_stem=${_ps_stem%"$_ps_suf"}
          [ "${#_ps_w}" -ge $((${#_ps_pre} + ${#_ps_suf})) ] || { R="${R:+$R }$_ps_w"; continue; }
          if [ -n "$_ps_rpct" ]; then R="${R:+$R }$_ps_rpre$_ps_stem$_ps_rsuf"; else R="${R:+$R }${2:-}"; fi ;;
        *) R="${R:+$R }$_ps_w" ;;
      esac
    else
      [ "$_ps_w" = "$1" ] && R="${R:+$R }${2:-}" || R="${R:+$R }$_ps_w"
    fi
  done
  set +f
}

# fn_filter PATTERNS LIST / fn_filter_out PATTERNS LIST (% wildcard)
fn_match_() { # WORD PATTERNS -> 0 when WORD matches one of PATTERNS
  for _fm_p in ${2:-}; do
    case $_fm_p in
      *%*) _fm_pre=${_fm_p%%%*}; _fm_suf=${_fm_p#*%}
           case $1 in "$_fm_pre"*"$_fm_suf") [ "${#1}" -ge $((${#_fm_pre} + ${#_fm_suf})) ] && return 0 ;; esac ;;
      *) [ "$1" = "$_fm_p" ] && return 0 ;;
    esac
  done
  return 1
}
fn_filter()     { set -f; R=; for _ft_w in ${2:-}; do fn_match_ "$_ft_w" "$1" && R="${R:+$R }$_ft_w"; done; set +f; }
fn_filter_out() { set -f; R=; for _fo_w in ${2:-}; do fn_match_ "$_fo_w" "$1" || R="${R:+$R }$_fo_w"; done; set +f; }

# fn_patsublist PATTERN REPLACEMENT LIST: patsubst per word, joined by commas
fn_patsublist() {
  set -f; R=
  for _pl_w in ${3:-}; do fn_patsubst_one_ "$1" "${2:-}" "$_pl_w"; R="${R:+$R,}$_pl_x"; done
  set +f
}
fn_patsubst_one_() { _pl_r=$R; fn_patsubst "$1" "${2:-}" "${3:-}"; _pl_x=$R; R=$_pl_r; }

# The routing macros: a service SVC publishes PORT behind the load balancer
# with consul tags urlprefix-<host>/<path>* [options]. The settings of a
# service are <SVC>_SERVICE_<PORT>_<X> (uppercased) with the fallbacks
# <SVC>_SERVICE_<X>.
fn_uvar_() { fn_upper "$1"; myos_var "$R"; }   # value of an uppercased name
fn_envprefix() { # SVC PORT ENVS -> "env=value ..." for every env that is set
  R=; _ep_out=
  for _ep_e in ${3:-}; do
    fn_uvar_ "$1_SERVICE_${2:-}_$_ep_e"
    [ -n "$R" ] && _ep_out="${_ep_out:+$_ep_out }$_ep_e=$R"
  done
  R=$_ep_out
}
fn_servicenvs() { # SVC PORT [SUFFIX]: the values of the envs listed in <SVC>_SERVICE_<PORT>_ENVS
  myos_var "$1_SERVICE_${2:-}_ENVS"; fn_upper "$R"; _sn_envs=$R; _sn_out=; _sn_first=1
  for _sn_e in $_sn_envs; do
    if [ -n "${3:-}" ]; then myos_var "$1_SERVICE_${_sn_e}_$3"; else myos_var "$1_SERVICE_${2:-}_$_sn_e"; fi
    if [ -n "$_sn_first" ]; then _sn_out=$R; _sn_first=; else _sn_out="$_sn_out $R"; fi
  done
  R=$_sn_out
}
fn_uri() { # SVC PORT [HOSTS]: <name>.<host>/<path> for every host (APP_URI by default)
  _ur_out=
  if [ -n "${3:-}" ]; then _ur_hosts=${3:-}; else myos_var APP_URI; _ur_hosts=$R; fi
  for _ur_s in $1; do
    fn_uvar_ "${_ur_s}_SERVICE_${2:-}_NAME"; _ur_n=$R
    [ -n "$_ur_n" ] || { fn_uvar_ "${_ur_s}_SERVICE_NAME"; _ur_n=$R; }
    [ -n "$_ur_n" ] || _ur_n=$_ur_s
    fn_patsubst % "$_ur_n.%" "$_ur_hosts"
    _ur_out="${_ur_out:+$_ur_out }$R"
  done
  R=$_ur_out
}
fn_url() { # SVC PORT [HOSTS]
  fn_uri "$1" "${2:-}" "${3:-}"; _ul_u=$R; myos_var APP_SCHEME; fn_patsubst % "$R://%" "$_ul_u"
}
fn_urlprefix() { # PATH OPTS URIS: one urlprefix-<uri><path>* [opts] per uri, comma joined
  if [ -n "${3:-}" ]; then _up_uris=${3:-}; else myos_var APP_URI; _up_uris=$R; fi
  _up_out=; set -f
  for _up_u in $_up_uris; do
    _up_out="${_up_out:+$_up_out,}urlprefix-$_up_u$1*${2:+ ${2:-}}"
  done
  set +f; R=$_up_out
}
fn_tagprefix() { # SVC PORT [ENVS]
  fn_uvar_ "$1_SERVICE_${2:-}_PATH"; _tp_path=$R
  [ -n "$_tp_path" ] || { fn_uvar_ "$1_SERVICE_PATH"; _tp_path=$R; }
  fn_uvar_ "$1_SERVICE_${2:-}_OPTS"; _tp_opts=$R
  [ -n "$_tp_opts" ] || { fn_uvar_ "$1_SERVICE_OPTS"; _tp_opts=$R; }
  [ -n "$_tp_opts" ] || { fn_envprefix "$1" "${2:-}" "allow auth deny prepend proto register strip"; _tp_opts=$R; }
  _tp_uris=
  for _tp_e in ${3:-}; do fn_uvar_ "$1_SERVICE_${2:-}_$_tp_e"; _tp_uris="${_tp_uris:+$_tp_uris }$R"; done
  fn_strip "$_tp_uris"; _tp_uris=$R
  [ -n "$_tp_uris" ] || { fn_uvar_ "$1_SERVICE_${2:-}_URIS"; _tp_uris=$R; }
  [ -n "$_tp_uris" ] || { fn_uri "$1" "${2:-}"; _tp_uris=$R; }
  fn_urlprefix "$_tp_path" "$_tp_opts" "$_tp_uris"
}

# Functions that run a subprocess (!name)
fx_shell()  { R=$(sh -c "$1" 2>/dev/null); }
fx_random() { R=$(head -c "${1:-30}" /dev/urandom | base64 | tr -d '\n' | sed 's/+/-/g;s#/#_#g;s/=*$//'); }
fx_b64url_() { R=$(printf '%s' "$1" | openssl enc -A -base64 | tr '+/' '-_' | tr -d '='); }
fx_jwt() { # HEADER PAYLOAD SECRET (HS256)
  _jw_hdr='{"alg":"HS256","typ":"JWT"}'; [ -n "$1" ] && _jw_hdr=$1
  fx_b64url_ "$_jw_hdr"; _jw_h=$R
  fx_b64url_ "${2:-}"; _jw_p=$R
  R=$(printf '%s' "$_jw_h.$_jw_p" | openssl dgst -sha256 -binary -hmac "${3:-}" | openssl enc -A -base64 | tr '+/' '-_' | tr -d '=')
  R=$_jw_h.$_jw_p.$R
}
fx_git() { R=$(cd "${2:-$MYOS_WORKDIR}" 2>/dev/null && git "$1" 2>/dev/null); }
