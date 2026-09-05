#shellcheck shell=sh
Include lib/core.sh
Include lib/str.sh
Include lib/var.sh
Include lib/tags.sh
Include lib/naming.sh
Include lib/stack.sh
Include lib/expose.sh

# Docker writes its own firewall rules, so a port published to 0.0.0.0 answers
# the internet whatever the host firewall says. Binding the publication is the
# portable answer: it behaves the same on linux and on macOS, without root.
Describe 'lib/expose.sh'
  Describe 'myos_bind'
    It 'binds the private scope to the loopback'
      When call myos_bind private
      The output should equal "127.0.0.1"
    End
    It 'binds the public scope to every address'
      When call myos_bind public
      The output should equal "0.0.0.0"
    End
    It 'takes an explicit address over the default'
      MYOS_BIND_PRIVATE=10.0.0.1
      When call myos_bind private
      The output should equal "10.0.0.1"
    End
    It 'keeps an unknown scope private rather than public'
      When call myos_bind nonsense
      The output should equal "127.0.0.1"
    End
    It 'falls back to the private address when there is no mesh'
      MYOS_MESH_IFACE=nosuchiface0
      When call myos_bind mesh
      The output should equal "127.0.0.1"
    End
    It 'uses the mesh address when one is given'
      MYOS_BIND_MESH=10.144.0.2
      When call myos_bind mesh
      The output should equal "10.144.0.2"
    End
  End

  Describe 'myos_stack_prefix'
    Parameters
      "host/fabio"  "HOST_FABIO"
      "User/ipfs"   "USER_IPFS"
      "supabase"    "SUPABASE"
      "drone/drone" "DRONE"
    End
    It "prefixes the settings of $1 with $2"
      When call myos_stack_prefix "$1"
      The output should equal "$2"
    End
  End

  Describe 'myos_expose_declared'
    setup() { MYOS_TMP=$(mktemp -d "${TMPDIR:-/tmp}/myos-exp.XXXXXX"); }
    cleanup() { rm -rf "$MYOS_TMP"; }
    BeforeEach setup
    AfterEach cleanup

    # The scope is not declared on the side: it is which binding the compose
    # file asks for. Reading the resolved configuration instead would lose the
    # difference, since every form ends up as a plain address.
    It 'reads the scope out of the binding each port asks for'
      printf 'services:\n  a:\n    ports:\n' > "$MYOS_TMP/c.yml"
      printf '      - "${MYOS_BIND_PUBLIC}:443:443"\n' >> "$MYOS_TMP/c.yml"
      printf '      - "${MYOS_BIND_PRIVATE}::8080"\n' >> "$MYOS_TMP/c.yml"
      printf '      - "${MYOS_BIND_MESH}::7946"\n' >> "$MYOS_TMP/c.yml"
      printf '      - "127.0.0.1:5432:5432"\n' >> "$MYOS_TMP/c.yml"
      printf '      - 80\n' >> "$MYOS_TMP/c.yml"
      When call myos_expose_declared "$MYOS_TMP/c.yml"
      The line 1 should equal "a|443|public"
      The line 2 should equal "a|8080|private"
      The line 3 should equal "a|7946|mesh"
      The line 4 should equal "a|5432|pinned"
      The line 5 should equal "a|80|unbound"
    End

    It 'calls a plain host:container mapping unbound, because it is'
      printf 'services:\n  a:\n    ports:\n      - "9000:9000"\n      - 25:25\n' > "$MYOS_TMP/c.yml"
      When call myos_expose_declared "$MYOS_TMP/c.yml"
      The line 1 should equal "a|9000|unbound"
      The line 2 should equal "a|25|unbound"
    End

    It 'keeps the protocol out of the port'
      printf 'services:\n  a:\n    ports:\n      - 4001/udp\n' > "$MYOS_TMP/c.yml"
      When call myos_expose_declared "$MYOS_TMP/c.yml"
      The output should equal "a|4001|unbound"
    End

    It 'reports nothing for a service that publishes nothing'
      printf 'services:\n  a:\n    image: alpine\n' > "$MYOS_TMP/c.yml"
      When call myos_expose_declared "$MYOS_TMP/c.yml"
      The output should equal ""
    End
  End
End
