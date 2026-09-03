#shellcheck shell=sh
# Helper: myos_dotenv_load sets variables in the caller's scope.
[ -n "${2:-}" ] && LOADED=$2
myos_dotenv_load "$1"
printf '%s\n' "$LOADED"
