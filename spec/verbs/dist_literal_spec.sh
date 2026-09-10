#shellcheck shell=sh
# A .env.dist line is the project's declaration. When its value is a literal,
# it is usable straight away -- before the first bootstrap has rendered .env.
# Otherwise a project cannot say who it belongs to or which domain it serves
# until after the deployment that needed to know it. A computed value
# ($(command), ${reference}) is still rendered once, on bootstrap.
Describe 'a literal of .env.dist'
  setup() { sb=$(myos_sandbox app-nogit); }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  # shellcheck disable=SC2046
  fresh() { # ARGS...: the wrapper on a checkout that has no .env yet
    ( cd "$sb/wd" && env -i $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|USER)=') \
        MYOS_CONF=/dev/null "$MYOS_ROOT/myos" "$@" 2>&1 )
  }

  It 'is readable before any .env exists'
    printf 'DOMAIN=declared.example\n' > "$sb/wd/.env.dist"
    When call fresh print-DOMAIN
    The output should include 'declared.example'
  End

  It 'names the tenant of the project through MYOS_USER'
    printf 'MYOS_USER=hco\nDOMAIN=declared.example\n' > "$sb/wd/.env.dist"
    When call fresh print-COMPOSE_PROJECT_NAME ENV=main
    The output should include 'hco-main-wd'
  End

  It 'leaves a computed value to the bootstrap'
    printf 'A_SECRET=$(echo generated)\n' > "$sb/wd/.env.dist"
    When call fresh print-A_SECRET
    The output should not include 'echo generated'
  End

  It 'still loses to .env'
    printf 'DOMAIN=declared.example\n' > "$sb/wd/.env.dist"
    printf 'DOMAIN=from-dot-env\n' > "$sb/wd/.env"
    When call fresh print-DOMAIN
    The output should include 'from-dot-env'
  End
End
