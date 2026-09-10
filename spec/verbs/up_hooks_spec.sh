#shellcheck shell=sh
# `up` runs the hooks of its stacks, like the other verbs. It is the verb one
# runs most, and the one after which a stack has something to say to the
# machine -- registering a route, priming a cache. Leaving it out meant a stack
# could only hook onto the verbs nobody types.
Describe 'up and its hooks'
  setup() {
    sb=$(myos_sandbox lifecycle); export MYOS_DOCKER_LOG=$sb/docker.log
    mkdir -p "$sb/wd/stack/app/actions"
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  hook() { # PHASE BODY
    printf '#!/bin/sh\n%s\n' "$2" > "$sb/wd/stack/app/actions/$1"
    chmod +x "$sb/wd/stack/app/actions/$1"
  }

  It 'runs a post-up hook after the stack is up'
    hook post-up 'echo LE-HOOK-A-TOURNE'
    When call myos_run_live "$sb" up app
    The output should include 'LE-HOOK-A-TOURNE'
    The output should include '[exit 0]'
  End

  It 'runs a pre-up hook, and its failure stops the verb'
    hook pre-up 'echo AVANT; exit 1'
    When call myos_run_live "$sb" up app
    The output should include 'AVANT'
    The output should not include '[exit 0]'
  End

  It 'gives the hook the values of the run'
    hook post-up 'echo "projet=$MYOS_PROJECT phase=$MYOS_PHASE"'
    When call myos_run_live "$sb" up app
    The output should include 'phase=post-up'
  End
End

# A hook that talks to docker needs to reach the same endpoint as the verb it
# hangs off. Without this, a `post-up` on a remote target runs its docker
# commands against the workstation -- silently, and against the wrong machine.
Describe 'a hook and the target'
  setup() {
    sb=$(myos_sandbox lifecycle); export MYOS_DOCKER_LOG=$sb/docker.log
    mkdir -p "$sb/wd/stack/app/actions"
    printf '#!/bin/sh\necho "endpoint=${DOCKER_HOST:-local}"\n' > "$sb/wd/stack/app/actions/post-up"
    chmod +x "$sb/wd/stack/app/actions/post-up"
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  It 'sees the endpoint of the run'
    When call myos_run_live "$sb" --target sonic up app
    The output should include 'endpoint=ssh://sonic'
  End

  It 'sees none when there is no target'
    When call myos_run_live "$sb" up app
    The output should include 'endpoint=local'
  End
End
