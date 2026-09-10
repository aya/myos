#shellcheck shell=sh
# Which builder the engine asks for. BuildKit has been docker's default for
# years and the classic builder is deprecated; a Dockerfile that writes
# `RUN --mount=type=cache` -- ordinary in 2026 -- simply fails on the classic
# one. Compose does not always pick BuildKit by itself (over an ssh endpoint it
# was observed falling back), so the engine says which it wants rather than
# leaving it to chance.
Describe 'the builder'
  setup() { sb=$(myos_sandbox lifecycle); export MYOS_DOCKER_LOG=$sb/docker.log; }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  It 'asks compose for BuildKit'
    myos_run_live "$sb" up app >/dev/null 2>&1
    When call grep -c '^DOCKER_BUILDKIT=1$' "$sb/env.log"
    The output should equal '1'
  End

  It 'lets the operator ask for the classic one'
    myos_run_live "$sb" up app DOCKER_BUILDKIT=0 >/dev/null 2>&1
    When call grep -c '^DOCKER_BUILDKIT=0$' "$sb/env.log"
    The output should equal '1'
  End
End
