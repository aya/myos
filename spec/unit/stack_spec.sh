#shellcheck shell=sh
Include lib/str.sh
Include lib/core.sh
Include lib/tags.sh
Include lib/stack.sh

Describe 'lib/stack.sh'
  setup() {
    MYOS_SANDBOX=$(myos_sandbox host-project)
    WORKDIR=$MYOS_SANDBOX/wd
    HOME=$MYOS_SANDBOX/home
    MYOS_PATH=
    ENV=local
    unset COMPOSE_FILE_WWW COMPOSE_FILE_DNS 2>/dev/null || true
  }
  cleanup() { rm -rf "$MYOS_SANDBOX"; }
  BeforeEach setup
  AfterEach cleanup

  Describe 'myos_path'
    It 'puts the project stacks before the shared catalogue'
      When call myos_path
      The output should equal "$WORKDIR/stack:$HOME/.local/share/myos/stack"
    End
    It 'is overridable'
      MYOS_PATH=/opt/stacks
      When call myos_path
      The output should equal "/opt/stacks"
    End
  End

  Describe 'myos_stack_resolve'
    It 'resolves a stack of the project'
      When call myos_stack_resolve host/consul
      The output should equal "$WORKDIR/stack/host"
    End
    It 'resolves a stack of the shared catalogue'
      When call myos_stack_resolve postgres
      The output should equal "$HOME/.local/share/myos/stack/postgres"
    End
    It 'resolves a versioned reference'
      When run source spec/unit/stack_version_helper.sh
      The output should equal "postgres 9.6"
    End
    It 'resolves a directory reference'
      When call myos_stack_resolve "$WORKDIR/stack/host"
      The output should equal "$WORKDIR/stack/host"
    End
    It 'fails loudly on an unknown stack'
      When run myos_stack_resolve nosuchstack
      The status should equal 3
      The stderr should include "stack not found: nosuchstack"
    End
  End

  Describe 'myos_compose_files'
    It 'loads the stack file and its env overlay'
      When call myos_compose_files "$HOME/.local/share/myos/stack/postgres" "docker-compose postgres" "" local
      The line 1 should equal "$HOME/.local/share/myos/stack/postgres/postgres.yml"
      The line 2 should equal "$HOME/.local/share/myos/stack/postgres/postgres.local.yml"
      The lines of output should equal 2
    End
    It 'skips the env overlay of another env'
      When call myos_compose_files "$HOME/.local/share/myos/stack/postgres" "docker-compose postgres" "" master
      The output should equal "$HOME/.local/share/myos/stack/postgres/postgres.yml"
    End
    It 'loads the version overlay as a suffix'
      When call myos_compose_files "$HOME/.local/share/myos/stack/postgres" "docker-compose postgres" "9.6" master
      The line 2 should equal "$HOME/.local/share/myos/stack/postgres/postgres.9.6.yml"
    End
    It 'loads the suffix overlays in order'
      When call myos_compose_files "$HOME/.local/share/myos/stack/host" "docker-compose nginx" "www dns" master
      The line 1 should equal "$HOME/.local/share/myos/stack/host/nginx.yml"
      The line 2 should equal "$HOME/.local/share/myos/stack/host/nginx.www.yml"
      The line 3 should equal "$HOME/.local/share/myos/stack/host/nginx.dns.yml"
    End
    It 'is empty for a directory without compose files'
      When call myos_compose_files "$WORKDIR" "docker-compose nothing" "" local
      The output should equal ""
    End
  End

  Describe 'myos_compose_suffixes'
    It 'keeps the enabled suffixes and drops the false ones'
      COMPOSE_FILE_LABELS=true; COMPOSE_FILE_WWW=false; COMPOSE_FILE_DNS=true
      When call myos_compose_suffixes
      The output should include "labels"
      The output should include "dns"
      The output should not include "www"
    End
    It 'adds <suffix>.<value> when the value is not a boolean'
      COMPOSE_FILE_WWW=nginx
      When call myos_compose_suffixes
      The output should include "www"
      The output should include "www.nginx"
    End
  End

  Describe 'myos_group_expand'
    It 'expands a group defined in the environment'
      host="host/consul host/fabio"
      When call myos_group_expand host
      The line 1 should equal "host/consul"
      The line 2 should equal "host/fabio"
    End
    It 'expands a group defined in a legacy .mk of the project'
      When call myos_group_expand host
      The line 1 should equal "host/consul"
      The line 3 should equal "host/registrator"
      The lines of output should equal 3
    End
    It 'expands a group of the shared catalogue'
      When call myos_group_expand testing
      The line 1 should equal "drone/drone"
      The line 2 should equal "redis"
    End
    It 'expands recursively'
      # shellcheck disable=SC2034
      all="testing extra"; extra="redis"
      When call myos_group_expand all
      The lines of output should equal 3
    End
    It 'leaves a plain stack reference alone'
      When call myos_group_expand postgres host/fabio
      The line 1 should equal "postgres"
      The line 2 should equal "host/fabio"
    End
    It 'refuses an endless group loop'
      # shellcheck disable=SC2034
      loop="loop"
      When run myos_group_expand loop
      The status should equal 2
      The stderr should include "nested too deep"
    End
  End
End
