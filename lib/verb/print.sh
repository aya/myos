#shellcheck shell=sh
# print-NAME: the value of one name, as `NAME value` (what make print-% did)
myos_verb_print() { # NAME
  myos_var "$1"
  printf '%s %s\n' "$1" "$R"
}
