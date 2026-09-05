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
  It 'leaves a .env that already pins the format alone'
    printf 'MYOS_PROJECT_FORMAT=user-env-app\n' > "$sb/wd/.env"
    When call myos_run_live "$sb" migrate pin
    The output should include 'skip'
    The contents of file "$sb/wd/.env" should equal 'MYOS_PROJECT_FORMAT=user-env-app'
  End
End
