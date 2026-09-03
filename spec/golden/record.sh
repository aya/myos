#!/bin/sh
# Record golden outputs of the LEGACY make engine into spec/golden/expected/.
# Usage: spec/golden/record.sh [case-name ...]
set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=spec/support/run.sh
. "$here/../support/run.sh"
MYOS_ROOT=${MYOS_ROOT:-$(cd "$here/../.." && pwd)}
only="$*"
grep -v '^#' "$here/cases.txt" | while IFS='|' read -r name fixture args; do
  name=$(echo "$name" | tr -d ' '); fixture=$(echo "$fixture" | tr -d ' ')
  [ -z "$name" ] && continue
  if [ -n "$only" ]; then case " $only " in *" $name "*) ;; *) continue ;; esac; fi
  sb=$(myos_sandbox "$fixture")
  eval "set -- $args"
  myos_run_engine legacy "$sb" "$@" > "$here/expected/$name.txt"
  rm -rf "$sb"
  printf 'recorded %s (%s lines)\n' "$name" "$(wc -l < "$here/expected/$name.txt" | tr -d ' ')"
done
