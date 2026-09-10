#shellcheck shell=sh
# secrets [list]: which files hold the values of this deployment, which
#                 provider reads them, and the names they define. Names only --
#                 a verb that can print a secret ends up in a terminal
#                 recording, a CI log or a ticket.
# secrets pull:   clone or fast-forward the configuration repository, so that a
#                 second workstation or a CI runner runs the same command as
#                 the operator and gets the same result.

myos_secrets_pull() {
  myos_var MYOS_CONFIG_REPOSITORY; _sp_url=$R
  [ -n "$_sp_url" ] || { myos_var CONFIG_REPOSITORY; _sp_url=$R; }
  [ -n "$_sp_url" ] || myos_die 2 "no configuration repository (set MYOS_CONFIG_REPOSITORY)"
  myos_config_dir; _sp_dir=$R
  [ -n "$_sp_dir" ] || { myos_var MYOS_CONFIG; _sp_dir=$R; }
  [ -n "$_sp_dir" ] || _sp_dir=$MYOS_WORKDIR/config
  if [ -d "$_sp_dir/.git" ]; then
    myos_run git -C "$_sp_dir" pull --ff-only --quiet || { myos_event pull "$_sp_dir" fail; return 1; }
  else
    myos_run git clone --quiet "$_sp_url" "$_sp_dir" || { myos_event pull "$_sp_dir" fail; return 1; }
  fi
  myos_event pull "$_sp_dir" ok
}

myos_secrets_list() {
  myos_secrets_provider; _vs_p=$R
  _vs_files=$MYOS_SECRET_FILES
  if [ "$MYOS_OUTPUT" = json ]; then
    _vs_n=; set -f
    for _vs_x in $MYOS_SECRET_NAMES; do myos_json_str "$_vs_x"; _vs_n="$_vs_n${_vs_n:+,}$R"; done
    set +f
    _vs_fl=; _vs_ifs=$IFS; IFS=$NL; set -f
    for _vs_f in $_vs_files; do IFS=$_vs_ifs; set +f; myos_json_str "$_vs_f"; _vs_fl="$_vs_fl${_vs_fl:+,}$R"; IFS=$NL; set -f; done
    IFS=$_vs_ifs; set +f
    printf '{"verb":"secrets","stack":"%s","provider":"%s","files":[%s],"names":[%s]}\n' \
      "$MYOS_STACK" "$_vs_p" "$_vs_fl" "$_vs_n"
    return 0
  fi
  [ -n "$_vs_files" ] || { printf 'no value file for %s in %s\n' "$MYOS_STACK" "$MYOS_ENV"; return 0; }
  _vs_ifs=$IFS; IFS=$NL; set -f
  for _vs_f in $_vs_files; do
    IFS=$_vs_ifs; set +f
    if myos_secrets_encrypted "$_vs_f"; then printf '%s %s\n' "$_vs_p" "$_vs_f"; else printf 'plain %s\n' "$_vs_f"; fi
    IFS=$NL; set -f
  done
  IFS=$_vs_ifs; set +f
  set -f
  for _vs_x in $MYOS_SECRET_NAMES; do printf '  %s\n' "$_vs_x"; done
  set +f
}

myos_verb_secrets() {
  case ${MYOS_SUB:-list} in
    pull) myos_secrets_pull ;;
    *)    myos_secrets_list ;;
  esac
}
