#shellcheck shell=sh
# cert: the certificates a host needs, derived from what it routes
Describe 'cert'
  setup() { sb=$(myos_sandbox lifecycle); export MYOS_DOCKER_LOG=$sb/docker.log; }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup
  logged() { cat "$sb/docker.log"; }

  It 'lists the names routed by the host stacks, wildcards apart'
    When call myos_run_live "$sb" cert list host
    The output should include 'fabio.testhost.example.test'
    The output should include 'www.example.test'
    The output should include '*.apps.example.test wildcard'
    The output should not include 'acme-challenge'
    The output should include '[exit 0]'
  End
  It 'issues the concrete names through dehydrated (http-01)'
    When call myos_run_live "$sb" cert host
    The result of function logged should include 'cat > /host/dehydrated/domains.txt'
    The result of function logged should include 'exec -T dehydrated dehydrated -c'
    The output should include 'cert host issue ok'
  End
  It 'refuses a wildcard without a dns hook, naming it'
    When call myos_run_live "$sb" cert host --wildcard
    The output should include '*.apps.example.test'
    The output should include 'dns-01'
    The output should include '[exit 1]'
  End
  It 'creates self-signed certificates for every name under --self-signed'
    When call myos_run_live "$sb" cert host --self-signed
    The result of function logged should include 'subjectAltName=DNS:www.example.test'
    The result of function logged should include '/host/certs/www.example.test-cert.pem'
    The output should include '[exit 0]'
  End
End
