#shellcheck shell=sh
Include lib/str.sh
Include lib/core.sh
Include lib/var.sh
Include lib/tags.sh
Include lib/config.sh

Describe 'lib/config.sh'
  setup() { MYOS_TMP=$(mktemp -d "${TMPDIR:-/tmp}/myos-cfg.XXXXXX"); }
  cleanup() { rm -rf "$MYOS_TMP"; }
  BeforeEach setup
  AfterEach cleanup

  Describe 'myos_dotenv_parse'
    It 'keeps plain assignments, drops comments and blanks, trims around the ='
      printf '# a comment\n\nFOO=bar\n  BAZ = qux \nnot an assignment\n' > "$MYOS_TMP/.env"
      When call myos_dotenv_parse "$MYOS_TMP/.env"
      The line 1 should equal "FOO=bar"
      The line 2 should equal "BAZ=qux "
      The lines of output should equal 2
    End
    It 'strips one layer of quotes'
      printf 'A="quoted"\nB='"'"'single'"'"'\nC=bare\n' > "$MYOS_TMP/.env"
      When call myos_dotenv_parse "$MYOS_TMP/.env"
      The line 1 should equal "A=quoted"
      The line 2 should equal "B=single"
      The line 3 should equal "C=bare"
    End
    It 'keeps a value containing a hash, which the make include could not'
      printf 'PASS=aa#bb\n' > "$MYOS_TMP/.env"
      When call myos_dotenv_parse "$MYOS_TMP/.env"
      The output should equal "PASS=aa#bb"
    End
    It 'never executes the file'
      printf 'X=$(touch %s/pwned)\n' "$MYOS_TMP" > "$MYOS_TMP/.env"
      When call myos_dotenv_parse "$MYOS_TMP/.env"
      The output should equal 'X=$(touch '"$MYOS_TMP"'/pwned)'
      The path "$MYOS_TMP/pwned" should not be exist
    End
    It 'is empty for a missing file'
      When call myos_dotenv_parse "$MYOS_TMP/nope"
      The output should equal ""
    End
  End

  Describe 'myos_dotenv_load'
    It 'sets the variables of the file'
      printf 'LOADED=yes\n' > "$MYOS_TMP/.env"
      When run source spec/unit/config_load_helper.sh "$MYOS_TMP/.env"
      The output should equal "yes"
    End
    It 'never overrides a variable that already has a value'
      printf 'LOADED=fromfile\n' > "$MYOS_TMP/.env"
      When run source spec/unit/config_load_helper.sh "$MYOS_TMP/.env" preset
      The output should equal "preset"
    End
  End

  Describe 'myos_env_vars'
    It 'collects the variables referenced by a compose file'
      printf 'services:\n  a:\n    image: ${IMAGE}\n    environment:\n      X: ${FOO:-d}\n' > "$MYOS_TMP/c.yml"
      When call myos_env_vars "$MYOS_TMP/c.yml"
      The output should equal "FOO IMAGE"
    End
    It 'ignores the $$ compose escape'
      printf 'services:\n  a:\n    command: echo $$HOME ${REAL}\n' > "$MYOS_TMP/c.yml"
      When call myos_env_vars "$MYOS_TMP/c.yml"
      The output should equal "REAL"
    End
    It 'is empty without files'
      When call myos_env_vars
      The output should equal ""
    End
  End

  Describe 'myos_env_export'
    It 'prints only the variables that have a value'
      SET_ONE=x; SET_TWO=
      When call myos_env_export SET_ONE SET_TWO SET_MISSING
      The output should equal "SET_ONE=x"
    End
  End
End

Describe 'lib/config.sh robustness'
  setup() { MYOS_TMP=$(mktemp -d "${TMPDIR:-/tmp}/myos-cfg.XXXXXX"); }
  cleanup() { rm -rf "$MYOS_TMP"; }
  BeforeEach setup
  AfterEach cleanup

  It 'loads an empty .env without complaining'
    : > "$MYOS_TMP/.env"
    When call myos_dotenv_load "$MYOS_TMP/.env"
    The status should be success
    The stderr should equal ""
  End
  It 'ignores a line with an empty key'
    printf '=orphan\nGOOD=1\n' > "$MYOS_TMP/.env"
    When call myos_dotenv_parse "$MYOS_TMP/.env"
    The output should equal "GOOD=1"
  End
  It 'returns empty for an unnamed variable'
    When call myos_var ""
    The output should equal ""
    The status should be success
  End
End

# The make engine generated a .env out of a .env.dist, expanding ${VAR} against
# the current values and running $(cmd). These check the shell equivalent.
Describe 'lib/config.sh templates'
  setup() { MYOS_TMP=$(mktemp -d "${TMPDIR:-/tmp}/myos-tpl.XXXXXX"); }
  cleanup() { rm -rf "$MYOS_TMP"; }
  BeforeEach setup
  AfterEach cleanup

  Describe 'myos_expand'
    It 'substitutes a variable'
      DOMAIN=example.org
      When call myos_expand 'https://app.${DOMAIN}/'
      The output should equal "https://app.example.org/"
    End
    It 'substitutes several, including twice the same'
      DOMAIN=example.org
      When call myos_expand '${DOMAIN}:${DOMAIN}'
      The output should equal "example.org:example.org"
    End
    It 'substitutes a lazy default like any other value'
      # shellcheck disable=SC2317
      myos_default_LAZY_DOMAIN() { printf 'lazy.example.org'; }
      When call myos_expand 'https://${LAZY_DOMAIN}/'
      The output should equal "https://lazy.example.org/"
    End
    It 'empties an unknown variable, as make does'
      When call myos_expand 'a${NOT_SET_ANYWHERE}b'
      The output should equal "ab"
    End
    It 'runs a command substitution'
      When call myos_expand 'pre-$(echo mid)-post'
      The output should equal "pre-mid-post"
    End
    It 'leaves a malformed reference alone'
      When call myos_expand 'a${not-a-name}b'
      The output should equal 'a${not-a-name}b'
    End
  End

  Describe 'myos_env_update'
    It 'adds the missing variables, expanded'
      printf 'DOMAIN=example.org\nAPP_URL=https://app.${DOMAIN}/\n' > "$MYOS_TMP/.env.dist"
      DOMAIN=chosen.org
      When call myos_env_update "$MYOS_TMP/.env" "$MYOS_TMP/.env.dist"
      The status should be success
      The contents of file "$MYOS_TMP/.env" should include "APP_URL=https://app.chosen.org/"
      The contents of file "$MYOS_TMP/.env" should include "DOMAIN=chosen.org"
    End
    It 'never touches a value already recorded'
      printf 'KEEP=default\n' > "$MYOS_TMP/.env.dist"
      printf 'KEEP=already-chosen\n' > "$MYOS_TMP/.env"
      When call myos_env_update "$MYOS_TMP/.env" "$MYOS_TMP/.env.dist"
      The contents of file "$MYOS_TMP/.env" should equal "KEEP=already-chosen"
    End
    It 'is idempotent'
      printf 'A=1\nB=${A}2\n' > "$MYOS_TMP/.env.dist"
      When run source spec/unit/config_update_helper.sh "$MYOS_TMP"
      The output should equal "2"
    End
    It 'does nothing without a template'
      When call myos_env_update "$MYOS_TMP/.env" "$MYOS_TMP/nope.dist"
      The status should be success
      The path "$MYOS_TMP/.env" should not be exist
    End
  End
End

Describe 'lib/config.sh forward references'
  setup() { MYOS_TMP=$(mktemp -d "${TMPDIR:-/tmp}/myos-fwd.XXXXXX"); }
  cleanup() { rm -rf "$MYOS_TMP"; }
  BeforeEach setup
  AfterEach cleanup

  It 'resolves a reference to a variable defined further down the template'
    printf 'IMAGE=alpine:${VERSION}\nVERSION=3.20\n' > "$MYOS_TMP/.env.dist"
    When call myos_env_update "$MYOS_TMP/.env" "$MYOS_TMP/.env.dist"
    The contents of file "$MYOS_TMP/.env" should include "IMAGE=alpine:3.20"
  End
  It 'resolves a chain of references'
    printf 'A=${B}\nB=${C}\nC=deep\n' > "$MYOS_TMP/.env.dist"
    When call myos_env_update "$MYOS_TMP/.env" "$MYOS_TMP/.env.dist"
    The contents of file "$MYOS_TMP/.env" should include "A=deep"
  End
  It 'still lets an explicit choice win over the template'
    printf 'IMAGE=alpine:${VERSION}\nVERSION=3.20\n' > "$MYOS_TMP/.env.dist"
    VERSION=3.19
    When call myos_env_update "$MYOS_TMP/.env" "$MYOS_TMP/.env.dist"
    The contents of file "$MYOS_TMP/.env" should include "IMAGE=alpine:3.19"
    The contents of file "$MYOS_TMP/.env" should include "VERSION=3.19"
  End
End
