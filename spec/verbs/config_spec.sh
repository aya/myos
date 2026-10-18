#shellcheck shell=sh
# config: what compose renders for the stack, and what it is given after `--`.
# `config --hash '*'` is how a deployment made by another engine is compared
# with what this one would run: the same hash per service, and the first `up`
# recreates nothing (chantiers/reprise-sonic).
Describe 'config'
  setup() { sb=$(myos_sandbox vendored); export MYOS_DOCKER_LOG=$sb/docker.log; }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  It 'renders the stack through compose'
    When call myos_run_live "$sb" config app
    The output should include '[exit 0]'
    The contents of file "$sb/docker.log" should include ' config'
  End

  It 'hands what follows -- to compose'
    When call myos_run_live "$sb" config app -- --hash '*'
    The output should include '[exit 0]'
    The contents of file "$sb/docker.log" should include ' config --hash *'
  End
End
