#shellcheck shell=sh
# A lazy default is re-evaluated at each reference, so it follows a value that
# changes later; an explicit value still wins over it.
myos_default_LAZY_ONE() { printf 'from-%s' "$(myos_var LAZY_BASE)"; }
LAZY_BASE=first;  myos_var LAZY_ONE; echo
LAZY_BASE=second; myos_var LAZY_ONE; echo
LAZY_ONE=pinned;  myos_var LAZY_ONE; echo
