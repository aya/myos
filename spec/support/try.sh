#!/bin/sh
# try.sh FIXTURE ARGS...  run one command of the engine on a fresh sandbox of
# FIXTURE and print its normalized output (what a golden case would record).
# MYOS_ENGINE selects the engine (legacy by default).
set -u
MYOS_ROOT=${MYOS_ROOT:-$(cd "$(dirname "$0")/../.." && pwd -P)}
export MYOS_ROOT
. "$MYOS_ROOT/spec/support/run.sh"
fixture=$1; shift
sb=$(myos_sandbox "$fixture")
myos_run_engine "${MYOS_ENGINE:-legacy}" "$sb" "$@"
[ -n "${KEEP:-}" ] && echo "sandbox kept: $sb" || rm -rf "$sb"
