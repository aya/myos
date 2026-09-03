#shellcheck shell=sh
# Helper: myos_resu sets MYOS_RESU_NIAMOD/MYOS_RESU_PATH as a side effect;
# a subshell would lose them, so the assertion runs them here.
myos_resu "aya@github.com" >/dev/null
printf '%s %s\n' "$MYOS_RESU_NIAMOD" "$MYOS_RESU_PATH"
