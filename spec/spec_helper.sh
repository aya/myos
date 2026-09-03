#shellcheck shell=sh
# shellspec helper: loaded before every spec file.
MYOS_ROOT=${MYOS_ROOT:-$SHELLSPEC_PROJECT_ROOT}
SPEC_DIR=$MYOS_ROOT/spec
export MYOS_ROOT SPEC_DIR
. "$SPEC_DIR/support/run.sh"
