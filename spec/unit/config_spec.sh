#shellcheck shell=sh
Include lib/str.sh
Include lib/core.sh
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
