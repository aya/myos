#shellcheck shell=sh
Include lib/str.sh
Include lib/core.sh
Include lib/tags.sh

# The expectations below are the very examples left as comments in
# make/apps/def.mk, which were never executed by anything.
Describe 'lib/tags.sh'
  # APP_URI is "<host>/<path>" in the framework, so it always ends with a slash
  # (make: APP_URI ?= $(patsubst %,%/$(APP_PATH),$(APP_HOST))).
  BeforeEach 'APP_URI=app.domain/; APP_SCHEME=http'

  Describe 'myos_urlprefix'
    It 'routes the whole app by default'
      When call myos_urlprefix
      The output should equal "urlprefix-app.domain/*"
    End
    It 'routes a sub path'
      When call myos_urlprefix "admin/"
      The output should equal "urlprefix-app.domain/admin/*"
    End
    It 'carries fabio options'
      When call myos_urlprefix ":443/" "proto=https" "app.domain"
      The output should equal "urlprefix-app.domain:443/* proto=https"
    End
    It 'emits one comma separated tag per uri'
      When call myos_urlprefix "" "" "a.domain/ b.domain/"
      The output should equal "urlprefix-a.domain/*,urlprefix-b.domain/*"
    End
  End

  Describe 'myos_uri'
    It 'prefixes the base uri with the service name'
      When call myos_uri kong 8000
      The output should equal "kong.app.domain/"
    End
    It 'prefers an explicit service name'
      SUPABASE_SERVICE_8000_NAME=studio
      When call myos_uri supabase 8000
      The output should equal "studio.app.domain/"
    End
    It 'expands every base uri'
      When call myos_uri api 80 "a.tld b.tld"
      The output should equal "api.a.tld api.b.tld"
    End
  End

  Describe 'myos_url'
    It 'prepends the scheme'
      When call myos_url api 80
      The output should equal "http://api.app.domain/"
    End
  End

  Describe 'myos_envprefix'
    It 'collects the fabio options that are set'
      HOST_NGINX_SERVICE_443_PROTO="https tlsskipverify=true"
      HOST_NGINX_SERVICE_443_STRIP="/api"
      When call myos_envprefix HOST_NGINX 443 allow proto strip
      The output should equal "proto=https tlsskipverify=true strip=/api"
    End
    It 'is empty when nothing is set'
      When call myos_envprefix HOST_NGINX 443 allow proto strip
      The output should equal ""
    End
  End

  Describe 'myos_tagprefix'
    It 'builds the tag of a service from its own uri'
      When call myos_tagprefix supabase 8000
      The output should equal "urlprefix-supabase.app.domain/*"
    End
    It 'uses the explicit URIS when there is one'
      SUPABASE_SERVICE_8000_URIS="supabase.example.org/"
      When call myos_tagprefix supabase 8000
      The output should equal "urlprefix-supabase.example.org/*"
    End
    It 'appends the options collected from the SERVICE_<port>_* variables'
      DUNITER_V2S_SERVICE_9944_STRIP="/ws"
      DUNITER_V2S_SERVICE_9944_URIS="g1.example.org/"
      When call myos_tagprefix duniter_v2s 9944
      The output should equal "urlprefix-g1.example.org/* strip=/ws"
    End
    It 'honours an explicit PATH and OPTS'
      HOST_FABIO_SERVICE_9998_PATH="admin/"
      HOST_FABIO_SERVICE_9998_OPTS="proto=https"
      HOST_FABIO_SERVICE_9998_URIS="fabio.example.org/"
      When call myos_tagprefix host_fabio 9998
      The output should equal "urlprefix-fabio.example.org/admin/* proto=https"
    End
  End
End

# Two deviations from the make macros, both documented in spec/golden/DELTAS.md:
# the make template leaves a stray space before the comma when it joins several
# uris, and it appends the url suffix after the options instead of after the
# path. Neither shape is used by anything on the fleet.
Describe 'lib/tags.sh deviations from the make macros'
  BeforeEach 'APP_URI=app.domain/'
  It 'joins several uris without a stray space'
    When call myos_urlprefix "" "" "a.domain/ b.domain/"
    The output should equal "urlprefix-a.domain/*,urlprefix-b.domain/*"
    The output should not include " ,"
  End
  It 'keeps the url suffix right after the path when options are given'
    When call myos_urlprefix ":443/" "proto=https" "app.domain"
    The output should equal "urlprefix-app.domain:443/* proto=https"
  End
End
