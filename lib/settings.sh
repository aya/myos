#shellcheck shell=sh
# settings: the computed defaults a stack ships (.settings files, compiled
# by settings.awk into sh functions once per run) and the plain defaults of
# its .env files. See settings.awk for the syntax.

# myos_settings_load FILES...: compile and eval the settings files
myos_settings_load() {
  [ $# -gt 0 ] || return 0
  _sl_code=$(awk -f "$MYOS_LIB/settings.awk" "$@") || myos_die 2 "settings: compilation failed"
  eval "$_sl_code"
}

# myos_stackenv_load FILE: the plain defaults of a stack (KEY=VALUE lines);
# a value already known from a higher layer is kept
myos_stackenv_load() {
  [ -f "$1" ] || return 0
  while IFS= read -r _se_line || [ -n "$_se_line" ]; do
    case $_se_line in ''|'#'*) continue ;; esac
    case $_se_line in export\ *) _se_line=${_se_line#export } ;; esac
    case $_se_line in *=*) ;; *) continue ;; esac
    _se_k=${_se_line%%=*}; _se_v=${_se_line#*=}
    case $_se_k in *[!A-Za-z0-9_]*|'') continue ;; esac
    case $_se_v in \"*\") _se_v=${_se_v#\"}; _se_v=${_se_v%\"} ;; \'*\') _se_v=${_se_v#\'}; _se_v=${_se_v%\'} ;; esac
    eval "MYOS_STACKENV_$_se_k=\$_se_v"
  done < "$1"
}

# myos_settings_of_stack: load the settings of the resolved stack directories
# (ascending precedence: a later file overrides an earlier definition) and
# of the engine
myos_settings_of_stack() {
  _ss_files="$MYOS/share/settings/engine.settings"
  myos_path; _ss_path=$R
  _ss_ifs=$IFS; IFS=$NL; set -f
  for _ss_d in $_ss_path; do
    IFS=$_ss_ifs; set +f
    [ -f "$_ss_d/_stack.settings" ] && _ss_files="$_ss_files$NL$_ss_d/_stack.settings"
    myos_stackenv_load "$_ss_d/_stack.env"
    IFS=$NL; set -f
  done
  for _ss_d in $MYOS_STACK_DIRS; do
    IFS=$_ss_ifs; set +f
    for _ss_f in "$_ss_d/_stack.settings" "$_ss_d/$MYOS_STACK_NAME.settings"; do
      [ -f "$_ss_f" ] && _ss_files="$_ss_files$NL$_ss_f"
    done
    for _ss_f in "$_ss_d/_stack.env" "$_ss_d/$MYOS_STACK_NAME.env" "$_ss_d/$MYOS_STACK_NAME.$MYOS_ENV.env"; do
      myos_stackenv_load "$_ss_f"
    done
    for _ss_f in "$_ss_d/_stack.sh" "$_ss_d/$MYOS_STACK_NAME.sh"; do
      # shellcheck disable=SC1090
      [ -f "$_ss_f" ] && . "$_ss_f"
    done
    IFS=$NL; set -f
  done
  IFS=$_ss_ifs; set +f
  # each file is compiled once per run; a stack loaded later may redefine a
  # name (last definition wins, as it did when make read every .mk)
  _ss_new=; _ss_ifs=$IFS; IFS=$NL; set -f
  for _ss_f in $_ss_files; do
    case "$NL$MYOS_SETTINGS_LOADED$NL" in *"$NL$_ss_f$NL"*) ;; *) _ss_new="$_ss_new$NL$_ss_f"; MYOS_SETTINGS_LOADED="$MYOS_SETTINGS_LOADED$NL$_ss_f" ;; esac
  done
  # shellcheck disable=SC2086
  [ -n "$_ss_new" ] && myos_settings_load $_ss_new
  IFS=$_ss_ifs; set +f
  myos_memo_clear
}
# myos_memo_clear: the values computed for the previous stack are forgotten
myos_memo_clear() {
  for _mc_n in ${MYOS_MEMO_NAMES:-}; do eval "unset MYOS_MEMO_$_mc_n MYOS_MEMO_ORIGIN_$_mc_n"; done
  MYOS_MEMO_NAMES=
}

# myos_setting NAME -> R and return 0 when NAME has a computed default
# (default kind); MYOS_ORIGIN is set. Guards against cycles.
myos_setting() {
  case "$MYOS_SET_NAMES" in *" $1 "*) ;; *) return 1 ;; esac
  myos_compute "$1"
}
myos_compute() {
  eval "[ -z \"\${MYOS_BUSY_$1:-}\" ]" || myos_die 2 "settings: $1 refers to itself (cycle)"
  eval "MYOS_BUSY_$1=1"
  "set_$1"
  eval "_sc_adds=\${MYOS_SET_ADDS_$1:-}"
  for _sc_a in $_sc_adds; do _sc_base=$R; "$_sc_a"; R="${_sc_base:+$_sc_base }$R"; done
  eval "unset MYOS_BUSY_$1"
  eval "MYOS_ORIGIN=\$MYOS_SET_ORIGIN_$1"
}
