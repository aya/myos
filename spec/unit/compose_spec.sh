#shellcheck shell=sh
Include lib/str.sh
Include lib/core.sh
Include lib/tags.sh
Include lib/config.sh
Include lib/compose.sh

# These assertions look at what is actually executed, not at what --dry-run
# prints: the two used to disagree, because the execution path set IFS to a
# newline and so never split "-f a -f b", nor the two words "docker compose".
Describe 'lib/compose.sh execution'
  setup() {
    MYOS_TMP=$(mktemp -d "${TMPDIR:-/tmp}/myos-compose.XXXXXX")
    MYOS_TMP=$(cd "$MYOS_TMP" && pwd -P)
    printf 'services:\n  a:\n    image: ${IMAGE}\n' > "$MYOS_TMP/a.yml"
    printf 'services:\n  b:\n    image: alpine\n' > "$MYOS_TMP/b.yml"
    # exported, otherwise the mock (a child process) never sees it
    export MYOS_DOCKER_LOG=$MYOS_TMP/docker.log
    export PATH=$SPEC_DIR/support/bin:$PATH
    DRYRUN=false
    IMAGE=alpine:3.20
    unset MYOS_COMPOSE_BIN 2>/dev/null || true
  }
  cleanup() { rm -rf "$MYOS_TMP"; }
  BeforeEach setup
  AfterEach cleanup

  logged() { cat "$MYOS_DOCKER_LOG"; }

  two_files() { myos_compose demo "$(printf '%s\n%s' "$MYOS_TMP/a.yml" "$MYOS_TMP/b.yml")" -- config; }

  It 'passes every -f as its own argument'
    When call two_files
    The status should be success
    The result of function logged should include "-f $MYOS_TMP/a.yml -f $MYOS_TMP/b.yml"
    The result of function logged should include "-p demo"
    The result of function logged should include "--project-directory $MYOS_TMP"
    The result of function logged should end with "config"
  End

  It 'splits the two words of the docker compose plugin'
    MYOS_COMPOSE_BIN="docker compose"
    When call myos_compose demo "$MYOS_TMP/a.yml" -- config
    The status should be success
    The result of function logged should start with "docker compose --ansi=auto"
  End

  It 'runs the docker-compose binary as one word'
    MYOS_COMPOSE_BIN="docker-compose"
    When call myos_compose demo "$MYOS_TMP/a.yml" -- config
    The status should be success
    The result of function logged should start with "docker-compose --ansi=auto"
  End

  It 'passes the variables the compose files reference'
    MYOS_COMPOSE_BIN="docker-compose"
    When call myos_compose demo "$MYOS_TMP/a.yml" -- config
    The status should be success
    The contents of file "$MYOS_TMP/env.log" should include "IMAGE=alpine:3.20"
  End

  It 'keeps a value that contains spaces in one piece'
    MYOS_COMPOSE_BIN="docker-compose"
    IMAGE="alpine with spaces"
    When call myos_compose demo "$MYOS_TMP/a.yml" -- config
    The status should be success
    The contents of file "$MYOS_TMP/env.log" should include "IMAGE=alpine with spaces"
  End

  It 'refuses to run without a compose file'
    When call myos_compose demo "" -- config
    The status should equal 3
    The stderr should include "no compose file"
  End
End
