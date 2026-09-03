#!/bin/sh
# Helpers shared by the golden recorder and the shellspec suites.
# myos_run_engine ENGINE WORKDIR ARGS...  runs myos (legacy make engine or bin/myos CLI)
# in a hermetic environment and prints normalized stdout+stderr followed by "[exit N]".

MYOS_ROOT="${MYOS_ROOT:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
SPEC_DIR="${SPEC_DIR:-$MYOS_ROOT/spec}"

# myos_sandbox FIXTURE -> prints a temp dir containing a copy of the fixture (wd/) and of the home fixture (home/)
myos_sandbox() {
  _fixture=$1
  _tmp=$(mktemp -d "${TMPDIR:-/tmp}/myos-spec.XXXXXX"); _tmp=$(cd "$_tmp" && pwd -P)
  cp -R "$SPEC_DIR/fixtures/$_fixture" "$_tmp/wd"
  cp -R "$SPEC_DIR/fixtures/home" "$_tmp/home"
  printf '%s\n' "$_tmp"
}

# myos_hermetic_env SANDBOX -> prints the env(1) arguments for a hermetic run
myos_hermetic_env() {
  printf '%s\n' \
    "PATH=$SPEC_DIR/support/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    "HOME=$1/home" \
    "USER=tester" "HOSTNAME=testhost" "DOMAIN=example.test" \
    "DOCKER_MACHINE=x86_64" "DOCKER_SYSTEM=Linux" "DOCKER_SOCKET_LOCATION=/var/run/docker.sock" \
    "DRYRUN=true" "TERM=dumb" "LANG=C" "LC_ALL=C" \
    "MYOS_DOCKER_LOG=$1/docker.log"
}

# myos_normalize SANDBOX  (stdin -> stdout)
# APPS, BRANCH and VERSION depend on where the myos checkout lives and on its git state,
# so they are masked to keep the goldens reproducible across machines.
myos_normalize() {
  sed -e 's/\x1b\[[0-9;]*m//g' \
      -e "s#$MYOS_ROOT#@MYOS@#g" \
      -e "s#$1/wd#@WD@#g" \
      -e "s#$1/home#@HOME@#g" \
      -e "s#$1#@TMP@#g" \
      -e 's#/[^ ]*/bin/make#make#g' \
      -e 's/^APPS .*/APPS @APPS@/' \
      -e 's/^BRANCH .*/BRANCH @BRANCH@/' \
      -e 's/^VERSION .*/VERSION @VERSION@/' \
      -e 's/[[:space:]][[:space:]]*/ /g' \
      -e 's/[[:space:]]*$//'
}

# myos_run_engine ENGINE SANDBOX ARGS...
# shellcheck disable=SC2046  # myos_hermetic_env output is meant to be word-split
myos_run_engine() {
  _engine=$1; _sb=$2; shift 2
  # "@make" as first arg = include mode: the project Makefile includes make/include.mk
  # and make runs from the project dir (CURDIR = project). Same for both engines.
  if [ "${1:-}" = "@make" ]; then
    shift
    _out=$(cd "$_sb/wd" && env -i $(myos_hermetic_env "$_sb") MYOS_CONF=/dev/null \
      make -es MYOS="$MYOS_ROOT" "$@" 2>&1); _rc=$?
    printf '%s\n[exit %s]\n' "$_out" "$_rc" | myos_normalize "$_sb"
    return 0
  fi
  case $_engine in
    legacy)
      # what /usr/local/bin/myos does: env from system conf + MYOS=. WORKDIR=$PWD make -esC $MYOS
      _out=$(cd "$_sb/wd" && env -i $(myos_hermetic_env "$_sb") \
        make -esC "$MYOS_ROOT" MYOS=. WORKDIR="$_sb/wd" "$@" 2>&1); _rc=$?
      ;;
    cli)
      _out=$(cd "$_sb/wd" && env -i $(myos_hermetic_env "$_sb") MYOS_CONF=/dev/null \
        "$MYOS_ROOT/bin/myos" -C "$_sb/wd" "$@" 2>&1); _rc=$?
      ;;
    *) echo "unknown engine $_engine" >&2; return 2 ;;
  esac
  printf '%s\n[exit %s]\n' "$_out" "$_rc" | myos_normalize "$_sb"
}
