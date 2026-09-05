#shellcheck shell=sh
# events: how a verb reports a step. Text on stderr, or one JSON object per
# line on stdout under --json, the same fields either way.
myos_event() { # STEP TARGET STATUS [DETAIL]
  if [ "$MYOS_OUTPUT" = json ]; then
    myos_json_str "$1"; _ev_s=$R; myos_json_str "$2"; _ev_t=$R; myos_json_str "${4:-}"; _ev_d=$R
    printf '{"verb":"%s","stack":"%s","step":%s,"target":%s,"status":"%s","detail":%s}\n' "$MYOS_VERB" "$MYOS_STACK" "$_ev_s" "$_ev_t" "$3" "$_ev_d"
  else
    printf 'myos %s %s %s %s%s\n' "$MYOS_VERB" "${MYOS_STACK:-}" "$1" "$3" "${4:+ ($4)}" >&2
  fi
}
myos_json_str() { # STRING -> R: a JSON string literal
  R=$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' | awk 'BEGIN{ORS=""} NR>1{print "\\n"} {print}')
  R="\"$R\""
}
