#shellcheck shell=sh
# doctor: what is missing or wrong on this host for the project
Describe 'doctor'
  setup() { sb=$(myos_sandbox lifecycle); }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  It 'reports the docker and compose versions as ok'
    When call myos_run_live "$sb" doctor app
    The output should include 'docker ok'
    The output should include 'compose ok'
  End
  It 'fails when a key of .env.dist is missing from .env'
    printf 'OTHER=1\n' > "$sb/wd/.env"
    When call myos_run_live "$sb" doctor app
    The output should include 'env fail'
    The output should include 'APP_DB_PASSWORD'
    The output should include '[exit 4]'
  End
  It 'runs the doctor hook of the stack and keeps its checks'
    When call myos_run_live "$sb" doctor app
    The output should include 'app-license ok'
    The output should include 'app-quota warn'
  End
  It 'warns when a network is missing and passes when nothing fails'
    printf 'APP_DB_PASSWORD=x\n' > "$sb/wd/.env"
    When call myos_run_live "$sb" doctor app
    The output should include 'network warn'
    The output should include '[exit 0]'
  End
End
