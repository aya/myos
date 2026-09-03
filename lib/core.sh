#shellcheck shell=sh
# core: logging, error handling and command execution.
#
# Every myos command goes through myos_run, which honours DRYRUN by printing
# the command instead of running it. Messages go to stderr so that stdout stays
# usable for data (myos env, myos config, myos ls).

# Exit codes and colors are consumed by the other lib/ files and by bin/myos.
# shellcheck disable=SC2034
MYOS_E_OK=0        # success
MYOS_E_FAIL=1      # command failed
MYOS_E_USAGE=2     # bad invocation
MYOS_E_NOSTACK=3   # stack not found
MYOS_E_NOREQ=4     # missing requirement

# myos_colors  decide whether to emit colour.
# MYOS_COLOR=always|never|auto (default auto: only when stdout is a terminal).
# The make engine always emitted the escape codes, even into a pipe.
myos_colors() {
  _want=${MYOS_COLOR:-auto}
  [ -n "${NO_COLOR:-}" ] && _want=never
  case $_want in
    never) _want=no ;;
    always) _want=yes ;;
    *) if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then _want=yes; else _want=no; fi ;;
  esac
  if [ "$_want" = yes ]; then
    MYOS_C_ERROR=$(printf '\033[31m');   MYOS_C_WARN=$(printf '\033[01;33m')
    MYOS_C_INFO=$(printf '\033[33m');    MYOS_C_DEBUG=$(printf '\033[01;34m')
    MYOS_C_VALUE=$(printf '\033[36m');   MYOS_C_RESET=$(printf '\033[0m')
    MYOS_C_HIGHLIGHT=$(printf '\033[32m')
  else
    MYOS_C_ERROR=; MYOS_C_WARN=; MYOS_C_INFO=; MYOS_C_DEBUG=; MYOS_C_VALUE=; MYOS_C_RESET=
    MYOS_C_HIGHLIGHT=
  fi
}

myos_error()   { printf '%sERROR:%s %s\n'   "$MYOS_C_ERROR" "$MYOS_C_RESET" "$*" >&2; }
myos_warning() { printf '%sWARNING:%s %s\n' "$MYOS_C_WARN"  "$MYOS_C_RESET" "$*" >&2; }
myos_info()    { [ -n "${VERBOSE:-}" ] && printf '%s%s%s\n' "$MYOS_C_INFO" "$*" "$MYOS_C_RESET" >&2; return 0; }
myos_debug()   { [ -n "${DEBUG:-}" ]   && printf '%s%s%s\n' "$MYOS_C_DEBUG" "$*" "$MYOS_C_RESET" >&2; return 0; }

# myos_die CODE MESSAGE...
myos_die() { _code=$1; shift; myos_error "$*"; exit "$_code"; }

# myos_run CMD...  run a command, or print it when DRYRUN is true
myos_run() {
  if [ "${DRYRUN:-false}" = true ]; then
    printf '%s\n' "$*"
    return 0
  fi
  myos_debug "+ $*"
  "$@"
}

# myos_have CMD  is a command available?
myos_have() { command -v "$1" >/dev/null 2>&1; }

myos_colors
