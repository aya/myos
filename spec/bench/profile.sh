#!/bin/sh
# profile.sh ARGS...: what one run of the engine forks (from an sh -x trace),
# in the benchmark environment: the trace length, then the commands by count
MYOS_ROOT=${MYOS_ROOT:-$(cd "$(dirname "$0")/../.." && pwd -P)}; export MYOS_ROOT
. "$(dirname "$0")/env.sh"
cd "$WORKDIR" || exit 1
trace=$(sh -x "$MYOS_ROOT/lib/main.sh" "$@" 2>&1 >/dev/null)
printf 'trace lines: %s\n' "$(printf '%s\n' "$trace" | wc -l | tr -d ' ')"
printf '%s\n' "$trace" | grep -E '^\++ [a-z][a-z0-9_-]* ' | sed 's/^+* //; s/ .*//' | grep -vE '^(myos_|fn_|fx_|set_|case|for|while|if|eval|shift|return|set|local|unset|export|read|trap|R|IFS)' | sort | uniq -c | sort -rn | head -20
