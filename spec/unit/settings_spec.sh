#shellcheck shell=sh
# The .settings compiler: what a line becomes
Describe 'settings.awk'
  compile() { printf '%s\n' "$1" | awk -f lib/settings.awk; }
  It 'compiles a reference into a lookup and the value'
    When call compile 'A ?= x${B}y'
    The output should include 'myos_var B; _t_A_1=$R'
    The output should include 'R="x${_t_A_1}y"'
    The output should include 'MYOS_SET_KIND_A=default'
  End
  It 'compiles a call with nested arguments into straight-line statements'
    When call compile 'T ?= @tagprefix(HOST_FABIO,9998,@or(${X},host))'
    The output should include 'fn_or "${_t_T_1}" "host"; _t_T_2=$R'
    The output should include 'fn_tagprefix "HOST_FABIO" "9998" "${_t_T_2}"; _t_T_3=$R'
  End
  It 'keeps the special characters and raw parentheses'
    When call compile 'C := a${comma}b${space}c $$((1+1))'
    The output should include 'R="a,b c \$((1+1))"'
    The output should include 'MYOS_SET_KIND_C=forced'
  End
  It 'lists the exports and appends'
    When call compile 'export A B
A += more'
    The output should include 'MYOS_SET_EXPORT=" A B "'
    The output should include 'MYOS_SET_ADDS_A=" set_A__a1"'
  End
  It 'fails on a line that is not a setting'
    When call compile 'not a setting'
    The status should equal 1
    The error should include 'not a setting'
  End
End
