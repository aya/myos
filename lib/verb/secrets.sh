#shellcheck shell=sh
# secrets [list]: which encrypted files this project carries, which provider
# reads them, and the names they define. Names only -- a verb that can print a
# secret ends up in a terminal recording, a CI log or a ticket.

myos_verb_secrets() {
  myos_secrets_files; _vs_files=$R
  myos_secrets_provider; _vs_p=$R
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
  [ -n "$_vs_files" ] || { printf 'no encrypted file (secrets.env, secrets.%s.env)\n' "$MYOS_ENV"; return 0; }
  _vs_ifs=$IFS; IFS=$NL; set -f
  for _vs_f in $_vs_files; do IFS=$_vs_ifs; set +f; printf '%s %s\n' "$_vs_p" "$_vs_f"; IFS=$NL; set -f; done
  IFS=$_vs_ifs; set +f
  set -f
  for _vs_x in $MYOS_SECRET_NAMES; do printf '  %s\n' "$_vs_x"; done
  set +f
}
