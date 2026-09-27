#shellcheck shell=sh
# `build` goes to the target like every other docker call. It did not: with
# --target the image was built by the docker of the workstation (or failed,
# when the workstation has no daemon), and `up` then ran on the target an
# image it did not have. Found deploying redroid to aynic (arm64), whose image
# has to be built there.
Describe 'build and the target'
  setup() { sb=$(myos_sandbox demo-project); }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup
  It 'builds on the target'
    When call myos_run_engine just "$sb" -n --target sonic docker-build-web
    The output should include 'DOCKER_HOST=ssh://sonic docker build'
    The output should include '[exit 0]'
  End
  It 'builds here without one'
    When call myos_run_engine just "$sb" -n docker-build-web
    The output should include 'docker build --build-arg'
    The output should not include 'DOCKER_HOST='
  End
  It 'attaches on the target'
    When call myos_run_engine just "$sb" -n --target sonic attach
    The output should include 'DOCKER_HOST=ssh://sonic docker attach'
  End
End
