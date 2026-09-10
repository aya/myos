#shellcheck shell=sh
# Which compose the engine calls. The plugin file being present does not mean
# it works: on this workstation the binary is in ~/.docker/cli-plugins and
# docker still answers `failed to fetch metadata: signal: killed`, so a
# detection by file presence picks a compose that cannot run. The engine asks
# the plugin whether it answers, once, and falls back to the standalone binary.
Describe 'the compose command'
  setup() {
    sb=$(myos_sandbox app-nogit)
    bin=$sb/bin; mkdir -p "$bin"
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  # a docker whose `compose` subcommand fails, as a broken plugin does
  broken_plugin() {
    cat > "$bin/docker" <<'EOF'
#!/bin/sh
for a in "$@"; do case $a in -*) ;; *) sub=$a; break ;; esac; done
[ "$sub" = compose ] && { echo 'docker: unknown command: docker compose' >&2; exit 1; }
echo mock-docker
EOF
    cat > "$bin/docker-compose" <<'EOF'
#!/bin/sh
echo standalone-compose "$@"
EOF
    chmod +x "$bin/docker" "$bin/docker-compose"
    mkdir -p "$sb/home/.docker/cli-plugins"
    : > "$sb/home/.docker/cli-plugins/docker-compose"
    chmod +x "$sb/home/.docker/cli-plugins/docker-compose"
  }

  # shellcheck disable=SC2046
  with_bin() { # ARGS...: the wrapper, with our fake docker first on the PATH
    ( cd "$sb/wd" && env -i $(myos_hermetic_env "$sb") MYOS_CONF=/dev/null \
        PATH="$bin:$SPEC_DIR/support/bin:/usr/bin:/bin" "$MYOS_ROOT/myos" "$@" 2>&1 )
  }

  It 'falls back to the standalone binary when the plugin does not answer'
    broken_plugin
    When call with_bin -n up
    The output should include 'docker-compose'
    The output should not include 'docker --log-level=error compose'
  End

  It 'still honours DOCKER_COMPOSE when the operator sets it'
    broken_plugin
    When call with_bin -n up DOCKER_COMPOSE=my-own-compose
    The output should include 'my-own-compose'
  End
End
