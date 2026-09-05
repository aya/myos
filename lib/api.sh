#shellcheck shell=sh
# api: what a hook written in sh may source (. "$MYOS_LIB/api.sh"): the
# values of the run (myos_var), a runner honouring the dry run (myos_run),
# events in the format of the engine (myos_event) and a failure (myos_fail).
MYOS_LIB=${MYOS_LIB:-$(dirname "$0")}
for _api_m in core values settings fn events; do . "$MYOS_LIB/$_api_m.sh"; done
myos_fail() { printf 'myos %s: %s\n' "${MYOS_PHASE:-hook}" "$*" >&2; exit 1; }
myos_run() { if [ "${MYOS_DRYRUN:-false}" = true ]; then printf '%s\n' "$*"; else "$@"; fi; }
