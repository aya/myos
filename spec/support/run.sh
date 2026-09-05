#!/bin/sh
# Helpers shared by the golden recorder and the shellspec suites.
# myos_run_engine ENGINE SANDBOX ARGS...  runs myos (legacy = the make engine,
# just = the rewrite) in a hermetic environment and prints normalized
# stdout+stderr followed by "[exit N]".

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
# APPS, BRANCH, VERSION, the image labels (git state, date, uid) and the ids of
# the user depend on the machine and on the git state of the checkout, so they
# are masked to keep the goldens reproducible. Credentials found in a URL are
# masked too, so that a golden can never carry a token.
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
      -e 's/--build-arg VERSION=[^ ]*/--build-arg VERSION=@VERSION@/' \
      -e 's/--build-arg BRANCH=[^ ]*/--build-arg BRANCH=@BRANCH@/' \
      -e 's/--build-arg COMPOSE_VERSION=[^ ]*/--build-arg COMPOSE_VERSION=@COMPOSE_VERSION@/' \
      -e 's/--build-arg GID=[^ ]*/--build-arg GID=@GID@/' \
      -e 's/--build-arg UID=[^ ]*/--build-arg UID=@UID@/' \
      -e 's/--build-arg SSH_[A-Z_]*=.* --build-arg GID/--build-arg SSH_@@ --build-arg GID/' \
      -e 's#\(https*://\)[^/@ ]*@#\1@CREDENTIALS@@#g' \
      -e 's/[0-9a-f]\{40\}/@COMMIT@/g' \
      -e 's/\(image\.created=\)[^ ]*/\1@DATE@/' \
      -e 's/\(image\.version=\)[^ ]*/\1@VERSION@/' \
      -e 's/\(os\.my\.version=\)[^ ]*/\1@VERSION@/' \
      -e 's/\(os\.my\.build\.status=\).* --label os\.my\.compose/\1@STATUS@ --label os.my.compose/' \
      -e 's/\(os\.my\.uid=\)[^ ]*/\1@UID@/' \
      -e 's/[[:space:]][[:space:]]*/ /g' \
      -e 's/[[:space:]]*$//'
}

# myos_run_engine ENGINE SANDBOX ARGS...
# shellcheck disable=SC2046  # myos_hermetic_env output is meant to be word-split
myos_run_engine() {
  _engine=$1; _sb=$2; shift 2
  # "@then CMD..." after the arguments: run CMD with sh in the project directory,
  # in the same hermetic environment (plus MYOS_ROOT), once the engine has
  # returned, and append its output (to look at a file the engine wrote).
  _then=; _seen=; _n=0
  for _a in "$@"; do
    if [ -n "$_seen" ]; then _then="$_then $_a"
    elif [ "$_a" = "@then" ]; then _seen=1
    else _n=$((_n + 1)); fi
  done
  _i=0; while [ "$_i" -lt "$_n" ]; do set -- "$@" "$1"; shift; _i=$((_i + 1)); done
  shift $(($# - _n))
  # "@make" as first arg = the project drives make itself: its Makefile includes
  # the legacy engine (make/include.mk) and make runs from the project directory.
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
    *) echo "unknown engine $_engine" >&2; return 2 ;;
  esac
  [ -n "$_then" ] && _out="$_out
[then]$(cd "$_sb/wd" && env -i $(myos_hermetic_env "$_sb") MYOS_ROOT="$MYOS_ROOT" sh -c "$_then" 2>&1)"
  printf '%s\n[exit %s]\n' "$_out" "$_rc" | myos_normalize "$_sb"
}
