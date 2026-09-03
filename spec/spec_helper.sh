#shellcheck shell=sh
# shellspec helper: loaded before every spec file.
MYOS_ROOT=${MYOS_ROOT:-$SHELLSPEC_PROJECT_ROOT}
SPEC_DIR=$MYOS_ROOT/spec
export MYOS_ROOT SPEC_DIR
. "$SPEC_DIR/support/run.sh"

# Specs under spec/integration and spec/e2e drive a real docker daemon.
# They are skipped unless MYOS_INTEGRATION=1 / MYOS_E2E=1 (make test-integration).
myos_needs_docker() { [ -n "${MYOS_INTEGRATION:-}" ]; }
myos_needs_swarm()  { [ -n "${MYOS_E2E:-}" ]; }
