#shellcheck shell=sh
Include lib/str.sh

Describe 'lib/str.sh'
  Describe 'myos_lower / myos_upper'
    Parameters
      "Foo-Bar"   "foo-bar"  "FOO_BAR"
      "MYOS"      "myos"     "MYOS"
      "a.b-c"     "a.b-c"    "A_B_C"
    End
    It "converts $1"
      When call myos_lower "$1"
      The output should equal "$2"
    End
    It "upcases $1 (- and . become _, as the make macro does)"
      When call myos_upper "$1"
      The output should equal "$3"
    End
  End

  Describe 'myos_name'
    Parameters
      "Duniter"      "duniter"
      "my-app"       "myapp"
      "my_app.v2"    "myappv2"
      "host"         "host"
    End
    It "normalizes $1 to a compose project fragment"
      When call myos_name "$1"
      The output should equal "$2"
    End
  End

  Describe 'myos_reverse'
    It 'reverses word order'
      When call myos_reverse "com github aya"
      The output should equal "aya github com"
    End
    It 'handles a single word'
      When call myos_reverse "aya"
      The output should equal "aya"
    End
  End

  Describe 'myos_verle'
    Parameters
      "2.24.4"  "2.29.0"  success
      "2.24.4"  "2.24.4"  success
      "2.29.0"  "2.24.4"  failure
      "2.5"     "2.10"    success
      ""        "2.24.4"  failure
      "2.24.4"  ""        failure
    End
    It "compares $1 <= $2"
      When call myos_verle "$1" "$2"
      The status should be "$3"
    End
  End

  Describe 'myos_verlt'
    It 'is false for equal versions'
      When call myos_verlt "1.2.3" "1.2.3"
      The status should be failure
    End
    It 'is true for a lower version'
      When call myos_verlt "1.2.3" "1.10.0"
      The status should be success
    End
  End
End
