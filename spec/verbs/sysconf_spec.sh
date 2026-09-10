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
