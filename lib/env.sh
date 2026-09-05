#shellcheck shell=sh
# env: render the .env.dist of the stacks into $WORKDIR/.env, once.
# A .env.dist line KEY=VALUE is the developer's default for what the user
# must provide. A key already present in .env (or set in the environment)
# is kept as it is; a missing one is appended, its ${X} references resolved
# through every layer (values, settings, the other keys of the same
# .env.dist, forward references allowed) and its $(command) substitutions
# run. The result is what the user edits from then on.

myos_env_file() { R=$MYOS_WORKDIR/.env; }

# myos_env_has KEY FILE -> 0 when FILE defines KEY
myos_env_has() { [ -f "$2" ] && grep -q "^$1=" "$2"; }

# myos_env_dist_value KEY -> R: the raw value of KEY in the dists being rendered
myos_env_dist_value() {
  R=; _dv_ifs=$IFS; IFS=$NL; set -f
  for _dv_l in $MYOS_DIST_LINES; do [ "${_dv_l%%=*}" = "$1" ] && R=${_dv_l#*=}; done
  IFS=$_dv_ifs; set +f
}

# myos_env_resolve VALUE -> R: ${X} and ${X:-fallback} replaced, $(cmd) run.
# The function recurses through myos_env_lookup: its temporaries are named
# after the depth.
myos_env_resolve() {
  MYOS_ER_D=$((${MYOS_ER_D:-0} + 1)); _er_d=$MYOS_ER_D
  eval "_er_v_$_er_d=\$1; _er_out_$_er_d="
  while :; do
    eval "_er_v=\$_er_v_$_er_d; _er_out=\$_er_out_$_er_d"
    case $_er_v in
      *'${'*)
        _er_out="$_er_out${_er_v%%\$\{*}"; _er_v=${_er_v#*\$\{}
        _er_ref=${_er_v%%\}*}; _er_v=${_er_v#*\}}
        _er_fb=; case $_er_ref in *:-*) _er_fb=${_er_ref#*:-}; _er_ref=${_er_ref%%:-*} ;; esac
        eval "_er_v_$_er_d=\$_er_v; _er_out_$_er_d=\$_er_out; _er_fb_$_er_d=\$_er_fb"
        myos_env_lookup "$_er_ref"; _er_val=$R; _er_d=$MYOS_ER_D
        eval "_er_fb=\$_er_fb_$_er_d; _er_out=\$_er_out_$_er_d"
        [ -n "$_er_val" ] || _er_val=$_er_fb
        eval "_er_out_$_er_d=\$_er_out\$_er_val" ;;
      *) eval "_er_out_$_er_d=\$_er_out\$_er_v"; break ;;
    esac
  done
  eval "_er_v=\$_er_out_$_er_d"; R=
  while :; do
    case $_er_v in
      *'$('*)
        R="$R${_er_v%%\$\(*}"; _er_v=${_er_v#*\$\(}
        _er_cmd=${_er_v%%\)*}; _er_v=${_er_v#*\)}
        _er_out=$R; R="$_er_out$(sh -c "$_er_cmd" 2>/dev/null)" ;;
      *) R="$R$_er_v"; break ;;
    esac
  done
  MYOS_ER_D=$((MYOS_ER_D - 1))
}

# myos_env_lookup KEY -> R: a value of the run, or the resolved dist value
myos_env_lookup() {
  myos_var "$1"; [ -n "$MYOS_ORIGIN" ] && return 0
  myos_env_dist_value "$1"; [ -n "$R" ] || return 0
  eval "[ -z \"\${MYOS_DIST_BUSY_$1:-}\" ]" || myos_die 2 ".env.dist: $1 refers to itself"
  eval "MYOS_DIST_BUSY_$1=1"; _el_raw=$R; myos_env_resolve "$_el_raw"; eval "unset MYOS_DIST_BUSY_$1"
}

# myos_env_render DISTFILES...: append the missing keys to $WORKDIR/.env
myos_env_render() {
  myos_env_file; _rn_env=$R
  MYOS_DIST_LINES=
  for _rn_f in "$@"; do
    [ -f "$_rn_f" ] || continue
    while IFS= read -r _rn_l || [ -n "$_rn_l" ]; do
      case $_rn_l in ''|'#'*) continue ;; *=*) ;; *) continue ;; esac
      _rn_k=${_rn_l%%=*}; case $_rn_k in *[!A-Za-z0-9_]*|'') continue ;; esac
      MYOS_DIST_LINES="${MYOS_DIST_LINES:+$MYOS_DIST_LINES$NL}$_rn_l"
    done < "$_rn_f"
  done
  [ -n "$MYOS_DIST_LINES" ] || return 0
  _rn_new=
  _rn_ifs=$IFS; IFS=$NL; set -f
  for _rn_l in $MYOS_DIST_LINES; do
    IFS=$_rn_ifs; set +f
    _rn_k=${_rn_l%%=*}
    if myos_env_has "$_rn_k" "$_rn_env" || eval "[ -n \"\${$_rn_k+set}\" ]"; then IFS=$NL; set -f; continue; fi
    case "$NL$_rn_new" in *"$NL$_rn_k="*) IFS=$NL; set -f; continue ;; esac
    myos_env_lookup "$_rn_k"
    _rn_new="$_rn_new$NL$_rn_k=$R"
    IFS=$NL; set -f
  done
  IFS=$_rn_ifs; set +f
  [ -n "$_rn_new" ] || return 0
  if [ "$MYOS_DRYRUN" = true ] && [ -z "${MYOS_RENDER_ALWAYS:-}" ]; then :; fi
  ( umask 077; [ -f "$_rn_env" ] || : > "$_rn_env" )
  printf '%s\n' "$_rn_new" | sed '/^$/d' | LC_ALL=C sort >> "$_rn_env"
  myos_event env-update "$_rn_env" ok "$(printf '%s\n' "$_rn_new" | sed '/^$/d' | wc -l | tr -d ' ') keys added"
}

# the dist files of the current project: every stack directory, then the project
myos_env_dists() {
  R=; _ed_ifs=$IFS; IFS=$NL; set -f
  for _ed_d in $MYOS_STACK_DIRS; do R="${R:+$R$NL}$_ed_d/.env.dist"; done
  IFS=$_ed_ifs; set +f
  case "$NL$R$NL" in *"$NL$MYOS_WORKDIR/.env.dist$NL"*) ;; *) R="${R:+$R$NL}$MYOS_WORKDIR/.env.dist" ;; esac
}
myos_verb_env_update() {
  myos_env_dists; _eu_ifs=$IFS; IFS=$NL; set -f
  # shellcheck disable=SC2086
  myos_env_render $R
  IFS=$_eu_ifs; set +f
}
