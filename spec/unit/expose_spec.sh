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

  Describe 'myos_expose_scope'
    It 'is private unless the stack says otherwise'
      When call myos_expose_scope HOST_FTPS ftps 21
      The output should equal "private"
    End
    It 'reads the scope of one port'
      HOST_FTPS_SERVICE_21_EXPOSE=public
      When call myos_expose_scope HOST_FTPS ftps 21
      The output should equal "public"
    End
    It 'reads the scope of a whole stack'
      HOST_FTPS_SERVICE_EXPOSE=mesh
      When call myos_expose_scope HOST_FTPS ftps 21
      The output should equal "mesh"
    End
    It 'prefers the port over the stack'
      HOST_FTPS_SERVICE_EXPOSE=mesh
      HOST_FTPS_SERVICE_21_EXPOSE=public
      When call myos_expose_scope HOST_FTPS ftps 21
      The output should equal "public"
    End
  End
End
