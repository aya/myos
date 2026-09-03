#shellcheck shell=sh
Include lib/core.sh
Include lib/var.sh

Describe 'lib/var.sh'
  Describe 'myos_var'
    It 'returns the value of a plain variable'
      SOME_VAR=plain
      When call myos_var SOME_VAR
      The output should equal "plain"
    End
    It 'returns empty for an unset variable'
      When call myos_var NEVER_SET
      The output should equal ""
    End
    It 'returns empty for an empty name'
      When call myos_var ""
      The output should equal ""
    End
    It 'never runs a command that happens to share the name'
      # `host` is a real program: a lazy default must never be confused with it
      When call myos_var host
      The output should equal ""
      The status should be success
      The stderr should equal ""
    End
  End

  Describe 'lazy defaults'
    lazy() {
      myos_default_LAZY_ONE() { printf 'from-%s' "$(myos_var LAZY_BASE)"; }
      myos_var LAZY_ONE
    }
    It 'computes the default when the variable has no value'
      LAZY_BASE=a
      When call lazy
      The output should equal "from-a"
    End
    It 'recomputes it against the current values'
      When run source spec/unit/var_lazy_helper.sh
      The line 1 should equal "from-first"
      The line 2 should equal "from-second"
      The line 3 should equal "pinned"
    End
    It 'declares a default from a string too'
      When run source spec/unit/var_default_helper.sh
      The output should equal "built-here"
    End
    It 'refuses a default written in terms of itself'
      When run source spec/unit/var_loop_helper.sh
      The stderr should include "defined in terms of itself"
      The status should equal 1
    End
  End

  Describe 'myos_var_is_lazy'
    It 'is true for a variable that only has a default'
      myos_default_ONLY_LAZY() { echo x; }
      When call myos_var_is_lazy ONLY_LAZY
      The status should be success
    End
    It 'is false once the variable has a value'
      myos_default_BOTH() { echo x; }
      BOTH=explicit
      When call myos_var_is_lazy BOTH
      The status should be failure
    End
    It 'is false for a program on PATH'
      When call myos_var_is_lazy host
      The status should be failure
    End
  End
End
