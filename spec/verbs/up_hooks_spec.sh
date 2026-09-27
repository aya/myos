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

  # conventions.md: a hook runs "with every exported value", and what reaches
  # compose includes "the names the settings export". Only the names the
  # compose files reference got there: a value meant for a hook alone -- the
  # legacy project a pre-upgrade hands over -- arrived empty.
  It 'gives the hook a name the settings export, that no compose file references'
    printf 'export APP_FOR_THE_HOOK\nAPP_FOR_THE_HOOK ?= from-the-settings\n' >> "$sb/wd/stack/app/app.settings"
    hook post-up 'echo "valeur=${APP_FOR_THE_HOOK:-vide}"'
    When call myos_run_live "$sb" up app
    The output should include 'valeur=from-the-settings'
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

  # $MYOS_COMPOSE is what a hook runs. With a target it carried a
  # `DOCKER_HOST=ssh://...` prefix, which a shell never reads as an assignment
  # once it comes out of a variable: the hook died on "not found", and a
  # backup hook that died let the default archive every volume.
  It 'can run $MYOS_COMPOSE as a command on a target'
    printf '#!/bin/sh\n$MYOS_COMPOSE ps && echo COMPOSE-OK\n' > "$sb/wd/stack/app/actions/post-up"
    When call myos_run_live "$sb" --target sonic up app
    The output should include 'COMPOSE-OK'
    The output should not include 'not found'
  End
End
