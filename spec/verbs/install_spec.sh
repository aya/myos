#shellcheck shell=sh
# install.sh is meant to be piped: `curl -fsSL .../install.sh | sh -s -- ...`.
# So it cannot read itself through $0 (that is `sh`), and what it writes must
# be what the myos it installs reads -- a configuration written where nothing
# looks is the "accepted, then ignored" class of defect.
Describe 'install.sh'
  setup() {
    sb=$(myos_sandbox app-nogit)
    # the working tree as a repository to clone, so the test installs the code
    # under test rather than the last commit
    src=$sb/src; mkdir -p "$src"
    ( cd "$MYOS_ROOT" && tar cf - --exclude .git --exclude spec . ) | tar xf - -C "$src"
    git -C "$src" init -q -b tdd && git -C "$src" add -A \
      && git -C "$src" -c user.name=t -c user.email=t@t commit -qm tree
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  # shellcheck disable=SC2046
  hermetic() { env -i $(myos_hermetic_env "$sb" | grep -vE '^(DOMAIN|DOCKER_SOCKET_LOCATION)=') "$@"; }

  It 'prints its usage when it is piped to sh'
    When run sh -c "sh -s -- --help < '$MYOS_ROOT/install.sh'"
    The status should be success
    The output should include 'curl -fsSL'
    The output should include '--prefix'
    The error should equal ''
  End

  # the wrapper reads a system configuration; a user without root gets one in
  # ~/.config/myos/config, and it has to count
  # the value goes into the file the installer says it wrote, never into a
  # path the test would create itself
  user_config() {
    _uc_out=$(hermetic sh "$MYOS_ROOT/install.sh" --prefix "$sb/p" --repository "$src" --conf 2>&1) || return 1
    _uc_conf=$(printf '%s\n' "$_uc_out" | sed -n 's/^wrote //p')
    [ -f "$_uc_conf" ] || { echo "no configuration written: $_uc_out"; return 1; }
    printf 'DOMAIN=from-the-user-config\n' >> "$_uc_conf"
    ( cd "$sb/wd" && hermetic "$sb/p/bin/myos" print-DOMAIN 2>&1 )
  }
  machine_has_conf() { [ -r /etc/conf.d/myos ] || [ -r /etc/default/myos ] || [ "$(id -u)" = 0 ]; }
  Skip if 'this machine has its own myos configuration, which ranks first' machine_has_conf
  It 'writes a configuration that the installed myos reads'
    When call user_config
    The output should include 'from-the-user-config'
  End
End
