#shellcheck shell=sh
# firewall: which ports a project publishes and to whom; rules for the host
Describe 'firewall'
  setup() { sb=$(myos_sandbox lifecycle); export MYOS_DOCKER_LOG=$sb/docker.log; }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup

  It 'audits every published port with its scope, from the compose files'
    When call myos_run_live "$sb" firewall app
    The output should include 'app web 8080 public 0.0.0.0'
    The output should include 'app db 5432 private 127.0.0.1'
    The output should include '[exit 0]'
  End
  It 'exits 4 under --strict when a stack that is not a host stack publishes a public port'
    When call myos_run_live "$sb" firewall app --strict
    The output should include 'public'
    The output should include '[exit 4]'
  End
  It 'accepts the public ports of a host stack under --strict, and reads the bind variables'
    When call myos_run_live "$sb" firewall host --strict
    The output should include 'host fabio 443 public 0.0.0.0'
    The output should include 'host fabio 9998 private 127.0.0.1'
    The output should include '[exit 0]'
  End
  It 'prints the ufw rules of the host ports under apply -n'
    When call myos_run_live "$sb" firewall apply host -n MYOS_FIREWALL=ufw
    The output should include 'ufw allow 80/tcp'
    The output should include 'ufw allow 443/tcp'
    The output should not include '9998'
  End
  It 'prints nftables rules when asked'
    When call myos_run_live "$sb" firewall apply host -n MYOS_FIREWALL=nftables
    The output should include 'nft add rule inet filter input tcp dport 443 accept'
  End
  It 'reports the ports as JSON under --json'
    When call myos_run_live "$sb" firewall app --json
    The output should include '"port":"8080"'
    The output should include '"scope":"public"'
  End
End
