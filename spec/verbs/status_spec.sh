#shellcheck shell=sh
# status: the services of a project, from compose ps, machine readable
Describe 'status'
  setup() { sb=$(myos_sandbox lifecycle); }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  It 'lists every service with its state and health'
    When call myos_run_live "$sb" status app
    The output should include 'web running healthy'
    The output should include 'db running healthy'
    The output should include '[exit 0]'
  End
  It 'exits 4 under --strict when a service is not running'
    MOCK_PS_STATE=exited:db
    When call myos_run_live "$sb" status app --strict
    The output should include 'db exited'
    The output should include '[exit 4]'
  End
  It 'prints one JSON object per service under --json'
    When call myos_run_live "$sb" status app --json
    The output should include '"service":"web"'
    The output should include '"state":"running"'
  End
End
