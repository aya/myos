#shellcheck shell=sh
# vendoring an upstream compose: the file is loaded first and never edited, the
# overlay is loaded after it and wins. The two things that used to break that
# promise are checked here.
Describe 'a vendored upstream compose'
  setup() { sb=$(myos_sandbox vendored); export MYOS_DOCKER_LOG=$sb/docker.log; }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  It 'loads the upstream file first and the overlay after it'
    When call myos_run_live "$sb" print-COMPOSE_FILE app
    The output should include 'stack/app/docker-compose.yml'
    The output should include 'stack/app/app.yml'
    The output should include '[exit 0]'
  End

  # the audit reads the raw files, so it has to honour the merge tags itself:
  # upstream publishes 8080 on every address and the overlay replaces the list
  It 'sees through a ports: !override of the overlay'
    When call myos_run_live "$sb" firewall app --strict
    The output should include 'app app random private 127.0.0.1'
    The output should not include 'public'
    The output should include '[exit 0]'
  End

  # a name the engine always answers (here DOCKER_IMAGE_TAG, default latest):
  # its default is not an answer, a .env.dist line is what initialises it
  It 'lets a .env.dist line beat the default the engine holds'
    myos_run_live "$sb" env-update app >/dev/null
    When call cat "$sb/wd/.env"
    The output should include 'DOCKER_IMAGE_TAG=pinned-by-the-dist'
  End

  It 'still loses to the command line'
    When call myos_run_live "$sb" print-TAG app DOCKER_IMAGE_TAG=from-the-command-line
    The output should include 'TAG from-the-command-line'
  End
End
