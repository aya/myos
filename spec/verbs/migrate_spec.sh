#shellcheck shell=sh
# migrate pin: the project names of a deployment made with the make engine
Describe 'migrate pin'
  setup() { sb=$(myos_sandbox app-nogit); }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  It 'writes MYOS_PROJECT_FORMAT=user-app-env into the .env, once'
    When call myos_run_live "$sb" migrate pin
    The output should include 'pin'
    The output should include '[exit 0]'
    The contents of file "$sb/wd/.env" should equal 'MYOS_PROJECT_FORMAT=user-app-env'
  End
  # That the pinned format actually NAMES the project cannot be proven here:
  # myos_run_live pins MYOS_PROJECT_FORMAT in the environment for every verb
  # spec, which is the path that always worked. The golden case
  # `pinned-project-name` exercises the .env path, the one migrate pin writes.
  It 'leaves a .env that already pins the format alone'
    printf 'MYOS_PROJECT_FORMAT=user-env-app\n' > "$sb/wd/.env"
    When call myos_run_live "$sb" migrate pin
    The output should include 'skip'
    The contents of file "$sb/wd/.env" should equal 'MYOS_PROJECT_FORMAT=user-env-app'
  End
End

# The fleet migration is the reason `migrate pin` exists, and the two harnesses
# pin MYOS_PROJECT_FORMAT in the ENVIRONMENT for every other spec -- the path
# that always worked. These run the wrapper without that pin, so the .env path
# (the one migrate pin writes) is the one under test.
Describe 'the pinned format, read from .env as migrate pin writes it'
  setup() { sb=$(myos_sandbox app-nogit); }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  # shellcheck disable=SC2046
  unpinned() { # ARGS...: the wrapper, with nothing pinned in the environment
    ( cd "$sb/wd" && env -i $(myos_hermetic_env "$sb") MYOS_CONF=/dev/null \
        "$MYOS_ROOT/myos" "$@" 2>&1 )
  }

  It 'names the project the historical way once .env pins it'
    printf 'MYOS_PROJECT_FORMAT=user-app-env\n' > "$sb/wd/.env"
    When call unpinned print-COMPOSE_PROJECT_NAME
    The output should include 'tester-wd-local'
  End

  It 'uses the new default when nothing pins it'
    When call unpinned print-COMPOSE_PROJECT_NAME
    The output should include 'tester-local-wd'
  End

  It 'still lets the command line win over .env'
    printf 'MYOS_PROJECT_FORMAT=user-app-env\n' > "$sb/wd/.env"
    When call unpinned print-COMPOSE_PROJECT_NAME MYOS_PROJECT_FORMAT=user-env-app
    The output should include 'tester-local-wd'
  End
End
