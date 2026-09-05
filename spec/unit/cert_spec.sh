#shellcheck shell=sh
Include lib/core.sh
Include lib/str.sh
Include lib/var.sh
Include lib/tags.sh
Include lib/naming.sh
Include lib/stack.sh
Include lib/cert.sh

# The hostnames a server must certify are already declared in the fabio route
# tags. Reading them there rather than in a domains.txt keeps one source of
# truth, and decides on its own which name needs a wildcard.
Describe 'lib/cert.sh'
  Describe 'myos_cert_parse'
    one_tag() { printf 'urlprefix-a.ex.org/x/*\n' | myos_cert_parse; }
    It 'reads a hostname out of a route tag'
      When call one_tag
      The output should equal "a.ex.org"
    End
    It 'drops the path, the port and the options'
      When run source spec/unit/cert_parse_helper.sh
      The line 1 should equal "*.ipns.ex.org"
      The line 2 should equal "ex.org"
      The line 3 should equal "ipfs.ex.org"
      The lines of output should equal 3
    End
  End

  Describe 'myos_cert_covers'
    Parameters
      "ex.org"  "a.ex.org"        success
      "ex.org"  "ex.org"          failure
      "ex.org"  "a.b.ex.org"      failure
      "ex.org"  "other.org"       failure
    End
    It "*.$1 against $2"
      When call myos_cert_covers "$1" "$2"
      The status should be "$3"
    End
  End

  Describe 'myos_cert_groups'
    It 'asks for a wildcard where a tag uses one, and absorbs what it covers'
      When run source spec/unit/cert_groups_helper.sh auto
      The line 1 should equal "ipns.ex.org *.ipns.ex.org"
      The output should include "ipfs.ex.org"
      The output should not include "a.ipns.ex.org *"
    End
    It 'never asks for a wildcard in per-site mode'
      When run source spec/unit/cert_groups_helper.sh per-site
      The output should not include "*"
      The output should include "a.ipns.ex.org"
    End
    It 'asks for one per domain in wildcard mode'
      When run source spec/unit/cert_groups_helper.sh wildcard
      The output should include "ex.org *.ex.org"
    End
    It 'says nothing when nothing is routed'
      When run source spec/unit/cert_groups_helper.sh auto ""
      The output should equal ""
    End
  End

  Describe 'myos_cert_needs_dns'
    It 'is true when a wildcard is asked for'
      When run source spec/unit/cert_dns_helper.sh auto
      The output should equal "yes"
    End
    It 'is false without one'
      When run source spec/unit/cert_dns_helper.sh per-site
      The output should equal "no"
    End
  End
End
