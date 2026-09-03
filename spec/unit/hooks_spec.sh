#shellcheck shell=sh
Include lib/str.sh
Include lib/core.sh
Include lib/tags.sh
Include lib/naming.sh
Include lib/config.sh
Include lib/hooks.sh

# A stack ships its computed settings as a shell hook, so the catalogue works
# on a machine without make. These check the hook and the uri it builds on.
Describe 'lib/hooks.sh'
  setup() {
    MYOS_TMP=$(mktemp -d "${TMPDIR:-/tmp}/myos-hook.XXXXXX")
    MYOS_TMP=$(cd "$MYOS_TMP" && pwd -P)
    ENV=local; DOMAIN=example.org; USER=tester; HOSTNAME=testhost
    APP_HOST=demo.example.org; APP_URI=demo.example.org/
  }
  cleanup() { rm -rf "$MYOS_TMP"; }
  BeforeEach setup
  AfterEach cleanup

  It 'loads plain values from a .env hook'
    printf 'DEMO_VERSION=1.2.3\n' > "$MYOS_TMP/demo.env"
    When run source spec/unit/hooks_helper.sh "$MYOS_TMP" demo DEMO_VERSION
    The output should equal "1.2.3"
  End

  It 'loads a computed value from a .sh hook'
    printf 'DEMO_TAGS=$(myos_tagprefix demo 8000)\n' > "$MYOS_TMP/demo.sh"
    When run source spec/unit/hooks_helper.sh "$MYOS_TMP" demo DEMO_TAGS
    The output should equal "urlprefix-demo.demo.example.org/*"
  End

  It 'lets a hook name the service it publishes'
    printf 'DEMO_SERVICE_8000_NAME=www\nDEMO_TAGS=$(myos_tagprefix demo 8000)\n' > "$MYOS_TMP/demo.sh"
    When run source spec/unit/hooks_helper.sh "$MYOS_TMP" demo DEMO_TAGS
    The output should equal "urlprefix-www.demo.example.org/*"
  End

  It 'lets the environment win over a hook default'
    printf 'DEMO_VERSION=${DEMO_VERSION:-1.2.3}\n' > "$MYOS_TMP/demo.sh"
    When run source spec/unit/hooks_helper.sh "$MYOS_TMP" demo DEMO_VERSION 9.9.9
    The output should equal "9.9.9"
  End

  It 'is quiet when a stack has no hook'
    When call myos_stack_hooks "$MYOS_TMP" nothing
    The status should be success
    The output should equal ""
  End
End

Describe 'lib/naming.sh service uris'
  BeforeEach 'ENV=local; unset APP_HOST_MULTI_APP APP_HOST_MULTI_USER APP_HOST_MULTI_ENV HOST_LB 2>/dev/null || true'

  It 'serves a host stack on <hostname>.<domain>'
    When call myos_app_host host aya local fabio example.org sonic
    The output should equal "sonic.example.org"
  End
  It 'adds the bare domain when the host is the load balancer'
    HOST_LB=true
    When call myos_app_host host aya local fabio example.org sonic
    The output should equal "sonic.example.org example.org"
  End
  It 'does not prefix a main environment'
    When call myos_app_host app aya master duniter example.org sonic
    The output should equal "example.org"
  End
  It 'prefixes any other environment'
    When call myos_app_host app aya staging duniter example.org sonic
    The output should equal "staging.example.org"
  End
  It 'prefixes the user when asked to'
    APP_HOST_MULTI_USER=true
    When call myos_app_host app aya master duniter example.org sonic
    The output should equal "aya.example.org"
  End
  It 'builds a uri that ends with a slash'
    When call myos_app_uri "a.example.org b.example.org"
    The output should equal "a.example.org/ b.example.org/"
  End
End
