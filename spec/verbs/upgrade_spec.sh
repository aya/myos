#shellcheck shell=sh
# upgrade: backup, pull, build, up, then wait for the services to be healthy
Describe 'upgrade'
  setup() { sb=$(myos_sandbox lifecycle); export MYOS_DOCKER_LOG=$sb/docker.log; }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup
  logged() { cat "$sb/docker.log"; }

  It 'backs up, pulls, brings up and checks the health'
    MOCK_VOLUMES="tester-app-local_data"
    When call myos_run_live "$sb" upgrade app
    The output should include 'upgrade app health ok'
    The output should include '[exit 0]'
    The result of function logged should include 'tar czf'
    The result of function logged should include '-p tester-app-local pull'
    The result of function logged should include '-p tester-app-local up -d'
    The result of function logged should include '-p tester-app-local ps --format json'
  End
  It 'fails when a service does not come up healthy'
    MOCK_PS_STATE=exited:db
    When call myos_run_live "$sb" upgrade app MYOS_UPGRADE_BACKUP=false
    The output should include 'health fail'
    The output should include 'db'
    The output should include '[exit 1]'
  End
  It 'does not run two upgrades of a project at once'
    mkdir -p "$sb/wd/.myos/lock.tester-app-local"
    When call myos_run_live "$sb" upgrade app
    The output should include 'locked'
    The output should include '[exit 5]'
  End
End
