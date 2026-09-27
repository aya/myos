#shellcheck shell=sh
# The system configuration (/etc/conf.d/myos, /etc/default/myos) is a fallback
# for the machine, so it ranks BELOW the project: a project that declares its
# own domain must not be overridden by the default of the host it is driven
# from. It still has to reach the docker CLI as a real environment variable,
# which is why the wrapper exports it and marks it rather than hiding it.
Describe 'the system configuration'
  setup() {
    sb=$(myos_sandbox app-nogit)
    conf=$sb/myos.conf
    printf 'DOMAIN=from-the-system\n' > "$conf"
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  # The hermetic environment pins DOMAIN and DOCKER_SOCKET_LOCATION, and the
  # wrapper only fills a name the environment does not already hold -- so the
  # names under test are dropped from it rather than contradicted. Setting them
  # empty would not do: the wrapper reads "set but empty" as provided.
  # shellcheck disable=SC2046
  with_conf() { # ARGS...: the wrapper, reading the sandbox's system config
    ( cd "$sb/wd" && env -i \
        $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|DOCKER_SOCKET_LOCATION)=') \
        MYOS_CONF="$conf" "$MYOS_ROOT/myos" "$@" 2>&1 )
  }

  It 'answers for a name nobody else provides'
    When call with_conf print-DOMAIN
    The output should include 'from-the-system'
  End

  It 'loses to the .env of the project'
    printf 'DOMAIN=from-the-project\n' > "$sb/wd/.env"
    When call with_conf print-DOMAIN
    The output should include 'from-the-project'
  End

  It 'loses to the command line'
    When call with_conf print-DOMAIN DOMAIN=from-the-command-line
    The output should include 'from-the-command-line'
  End

  # what the machine config is really for: pointing the docker CLI somewhere.
  # It has to stay a real environment variable for that.
  It 'still reaches the docker call it is meant for'
    printf 'DOCKER_SOCKET_LOCATION=/run/somewhere.sock\n' > "$conf"
    When call with_conf print-DOCKER_SOCKET_LOCATION
    The output should include '/run/somewhere.sock'
  End
End

# A user who installed myos without root (in ~/.local) has no /etc to write
# to: ~/.config/myos/config stands for the machine, and only when the machine
# says nothing itself.
Describe 'the user configuration'
  setup() {
    sb=$(myos_sandbox app-nogit)
    mkdir -p "$sb/home/.config/myos"
    printf 'DOMAIN=from-the-user\n' > "$sb/home/.config/myos/config"
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  # shellcheck disable=SC2046
  with_home() {
    ( cd "$sb/wd" && env -i \
        $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|DOCKER_SOCKET_LOCATION)=') \
        "$@" "$MYOS_ROOT/myos" print-DOMAIN 2>&1 )
  }
  machine_has_conf() { [ -r /etc/conf.d/myos ] || [ -r /etc/default/myos ]; }

  Context 'on a machine without a system configuration'
    Skip if 'this machine has /etc/conf.d/myos or /etc/default/myos' machine_has_conf
    It 'answers for a name nobody else provides'
      When call with_home
      The output should include 'from-the-user'
    End
  End

  It 'gives way to MYOS_CONF'
    printf 'DOMAIN=from-myos-conf\n' > "$sb/myos.conf"
    When call with_home MYOS_CONF="$sb/myos.conf"
    The output should include 'from-myos-conf'
  End
End

# The machine's configuration describes the machine; everything the project
# commits is more specific. So it is the lowest layer above the engine's own
# defaults -- below the stack values a project versions, and below the
# .env.dist line that initialises a name.
Describe 'the system configuration against what a project commits'
  setup() {
    sb=$(myos_sandbox app-nogit)
    conf=$sb/myos.conf
    printf 'DOMAIN=from-the-system\n' > "$conf"
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  # shellcheck disable=SC2046
  with_conf() {
    ( cd "$sb/wd" && env -i \
        $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|DOCKER_SOCKET_LOCATION)=') \
        MYOS_CONF="$conf" "$MYOS_ROOT/myos" "$@" 2>&1 )
  }

  It 'loses to a value the project versions in _stack.env'
    mkdir -p "$sb/wd/stack"
    printf 'DOMAIN=from-the-project-stack\n' > "$sb/wd/stack/_stack.env"
    When call with_conf print-DOMAIN
    The output should include 'from-the-project-stack'
  End

  It 'does not poison the .env rendered from a .env.dist'
    printf 'DOMAIN=from-the-dist\n' > "$sb/wd/.env.dist"
    ( cd "$sb/wd" && env -i \
        $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|DOCKER_SOCKET_LOCATION)=') \
        MYOS_CONF="$conf" "$MYOS_ROOT/myos" env-update >/dev/null 2>&1 )
    When call cat "$sb/wd/.env"
    The output should include 'DOMAIN=from-the-dist'
  End
End
