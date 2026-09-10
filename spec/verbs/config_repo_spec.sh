#shellcheck shell=sh
# The configuration repository: what a deployment needs that its own checkout
# must not carry. Laid out as the make engine had it, <env>/<app>/.env, plus a
# sops-encrypted secrets.env beside it. It is what lets a second workstation,
# or a CI runner, deploy the same thing without anyone copying a .env by hand.
Describe 'the configuration repository'
  setup() {
    sb=$(myos_sandbox app-nogit)
    cfg=$sb/config
    mkdir -p "$cfg/main/wd"
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  # shellcheck disable=SC2046
  with_config() { # ARGS...
    ( cd "$sb/wd" && env -i $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|USER)=') \
        MYOS_CONF=/dev/null MYOS_CONFIG="$cfg" "$MYOS_ROOT/myos" "$@" 2>&1 )
  }

  It 'reads the values of <env>/<app>/.env'
    printf 'FROM_CONFIG=the-shared-value\n' > "$cfg/main/wd/.env"
    When call with_config print-FROM_CONFIG ENV=main
    The output should include 'the-shared-value'
  End

  It 'decrypts the secrets beside them'
    printf 'ciphertext\n#PLAINTEXT\nA_SECRET=out-of-the-store\n' > "$cfg/main/wd/secrets.env"
    When call with_config print-A_SECRET ENV=main
    The output should include 'out-of-the-store'
  End

  It 'prefers the values of the env and app over the shared ones'
    printf 'SHARED=everywhere\n' > "$cfg/.env"
    printf 'SHARED=this-env\n' > "$cfg/main/.env"
    printf 'SHARED=this-app\n' > "$cfg/main/wd/.env"
    When call with_config print-SHARED ENV=main
    The output should include 'this-app'
  End

  # not merely "does not generate a new one": it must not copy the store's
  # value into a plaintext .env either. A secret that the store holds
  # encrypted has no business being written in clear on every machine that
  # deploys -- it is decrypted in memory, for the length of the call.
  It 'writes nothing at all for a key the store provides'
    printf 'A_SECRET=$(echo generated-locally)\nPLAIN=kept\n' > "$sb/wd/.env.dist"
    printf 'ciphertext\n#PLAINTEXT\nA_SECRET=out-of-the-store\n' > "$cfg/main/wd/secrets.env"
    with_config env-update ENV=main >/dev/null 2>&1
    When call cat "$sb/wd/.env"
    The output should not include 'A_SECRET'
    The output should include 'PLAIN=kept'
  End

  It 'still lets the local .env win, for the run one is debugging'
    printf 'FROM_CONFIG=the-shared-value\n' > "$cfg/main/wd/.env"
    printf 'FROM_CONFIG=what-i-am-testing\n' > "$sb/wd/.env"
    When call with_config print-FROM_CONFIG ENV=main
    The output should include 'what-i-am-testing'
  End

  It 'lists where its values come from'
    printf 'FROM_CONFIG=the-shared-value\n' > "$cfg/main/wd/.env"
    When call with_config secrets ENV=main
    The output should include 'config/main/wd/.env'
  End
End

Describe 'secrets pull'
  setup() {
    sb=$(myos_sandbox app-nogit)
    # a repository standing for the configuration repository
    up=$sb/upstream; mkdir -p "$up/main/wd"
    printf 'FROM_CONFIG=from-the-clone\n' > "$up/main/wd/.env"
    ( cd "$up" && git init -q && git add -A &&
      git -c user.email=t@t -c user.name=t commit -qm init ) >/dev/null 2>&1
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  # the hermetic environment pins DRYRUN=true, so a run that has to really
  # clone says otherwise; `dry` keeps the pinned value on purpose
  # shellcheck disable=SC2046
  live() {
    ( cd "$sb/wd" && env -i $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|USER|DRYRUN)=') \
        DRYRUN=false PATH="/usr/bin:/bin:$SPEC_DIR/support/bin" \
        MYOS_CONF=/dev/null MYOS_CONFIG="$sb/config" \
        MYOS_CONFIG_REPOSITORY="$up" "$MYOS_ROOT/myos" "$@" 2>&1 )
  }
  # shellcheck disable=SC2046
  dry() {
    ( cd "$sb/wd" && env -i $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|USER)=') \
        PATH="/usr/bin:/bin:$SPEC_DIR/support/bin" \
        MYOS_CONF=/dev/null MYOS_CONFIG="$sb/config" \
        MYOS_CONFIG_REPOSITORY="$up" "$MYOS_ROOT/myos" "$@" 2>&1 )
  }
  # shellcheck disable=SC2046
  no_repo() {
    ( cd "$sb/wd" && env -i $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|USER)=') \
        MYOS_CONF=/dev/null "$MYOS_ROOT/myos" "$@" 2>&1; printf '[exit %s]\n' "$?" )
  }

  It 'clones the repository, and then its values are read'
    live secrets pull ENV=main >/dev/null 2>&1
    When call live print-FROM_CONFIG ENV=main
    The output should include 'from-the-clone'
  End

  It 'fast-forwards a clone it already has'
    live secrets pull ENV=main >/dev/null 2>&1
    When call live secrets pull ENV=main
    The output should include 'pull ok'
  End

  It 'says what it would do under a dry run, without cloning'
    When call dry secrets pull ENV=main
    The output should include 'git clone'
    The path "$sb/config" should not be exist
  End

  It 'fails plainly when no repository is declared'
    When call no_repo secrets pull
    The output should include 'MYOS_CONFIG_REPOSITORY'
    The output should include '[exit 2]'
  End
End
