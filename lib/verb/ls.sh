#shellcheck shell=sh
# ls: the path, the stacks and the groups it holds
myos_verb_ls() {
  myos_path; _ls_path=$R
  _ls_old=$IFS; IFS=$NL; set -f
  for _ls_d in $_ls_path; do
    IFS=$_ls_old; set +f
    printf '%s\n' "$_ls_d"
    for _ls_f in "$_ls_d"/*/*.yml "$_ls_d"/*/*.yaml; do
      [ -f "$_ls_f" ] || continue
      _ls_n=${_ls_f#"$_ls_d"/}; _ls_n=${_ls_n%.y*ml}
      case $_ls_n in *.*) continue ;; esac
      printf '  %s\n' "$_ls_n"
    done
    IFS=$NL; set -f
  done
  IFS=$_ls_old; set +f
  myos_groups
  [ -n "$R" ] && { printf 'groups\n'; printf '%s\n' "$R" | sed 's/^/  /'; }
  return 0
}
