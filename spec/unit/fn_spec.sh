#shellcheck shell=sh
# The functions a .settings expression can call, on the examples the make
# macros were documented with (make/apps/def.mk, in the history).
Describe 'fn'
  Include lib/core.sh
  Include lib/values.sh
  Include lib/settings.sh
  Include lib/fn.sh
  setup() {
    MYOS_WORKDIR=/nonexistent MYOS_ENV=local MYOS_USER=tester MYOS_HOSTNAME=testhost MYOS_DOMAIN=example.test
    MYOS_STACK_SCOPE=app MYOS_STACK_NAME=app MYOS_STACK_APP=app MYOS_STACK_FILES= MYOS_STACK_DIRS= MYOS_PROJECT=tester-app-local
    MYOS_NETWORK= MYOS_NETWORK_DEFAULT= MYOS_NETWORK_PRIVATE= MYOS_NETWORK_PUBLIC= MYOS_SET_NAMES= MYOS_SET_EXPORT= MYOS_MEMO_NAMES=
    APP_URI=app.domain/ APP_SCHEME=https
  }
  BeforeEach setup
  v() { "$@"; printf '%s' "$R"; }

  It 'urlprefix: one route per uri, the options after a space'
    When call v fn_urlprefix "" "" "app.domain/"
    The output should equal 'urlprefix-app.domain/*'
  End
  It 'urlprefix: a path and options'
    When call v fn_urlprefix "admin/" "strip=/admin" "app.domain/"
    The output should equal 'urlprefix-app.domain/admin/* strip=/admin'
  End
  It 'urlprefix: several uris are joined by commas, without a space before the comma'
    When call v fn_urlprefix "" "" "a.domain/ b.domain/"
    The output should equal 'urlprefix-a.domain/*,urlprefix-b.domain/*'
  End
  It 'tagprefix: the name of the service, the route options from the settings'
    APP_SERVICE_80_NAME=web APP_SERVICE_80_PROTO=https APP_SERVICE_80_STRIP=/web
    When call v fn_tagprefix APP 80
    The output should equal 'urlprefix-web.app.domain/* proto=https strip=/web'
  End
  It 'patsubst: % stands for the stem, a word that does not match is kept'
    When call v fn_patsubst '%.yml' '%' 'a.yml b.yaml c.yml'
    The output should equal 'a b.yaml c'
  End
  It 'subst: every occurrence'
    When call v fn_subst ' ' ',' 'a b c'
    The output should equal 'a,b,c'
  End
  It 'filter-out keeps the words matching no pattern'
    When call v fn_filter_out 'local master main' 'local staging main'
    The output should equal 'staging'
  End
  It 'if: a non-empty condition (even the word false) selects the first branch'
    When call v fn_if false yes no
    The output should equal 'yes'
  End
  It 'if: a blank condition selects the second branch'
    When call v fn_if ' ' yes no
    The output should equal 'no'
  End
  It 'or: the first non-empty argument'
    When call v fn_or '' ' ' third
    The output should equal 'third'
  End
  It 'jwt: HS256 of a payload with commas'
    When call v fx_jwt '' '{"role":"anon","iss":"demo"}' secret
    The output should equal 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6ImRlbW8ifQ.p5Px2v9JNbUBbZy1rR3gP_uJVcBjdoD6oxgO8c4Ckfc'
  End
End
