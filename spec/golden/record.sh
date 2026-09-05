#!/bin/sh
# Record golden outputs: MYOS_ENGINE=legacy (default) writes the historical
# behaviour into spec/golden/expected/; another engine writes the intentional
# deltas into spec/golden/expected.<engine>/ (each one listed in DELTAS.md).
# Usage: [MYOS_ENGINE=just] spec/golden/record.sh [case-name ...]
set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=spec/support/run.sh
. "$here/../support/run.sh"
MYOS_ROOT=${MYOS_ROOT:-$(cd "$here/../.." && pwd)}
only="$*"
engine=${MYOS_ENGINE:-legacy}
out="$here/expected"; [ "$engine" = legacy ] || out="$here/expected.$engine"
mkdir -p "$out"
grep -v '^#' "$here/cases.txt" | while IFS='|' read -r name fixture args; do
  name=$(echo "$name" | tr -d ' '); fixture=$(echo "$fixture" | tr -d ' ')
  [ -z "$name" ] && continue
  if [ -n "$only" ]; then case " $only " in *" $name "*) ;; *) continue ;; esac; fi
  sb=$(myos_sandbox "$fixture")
  eval "set -- $args"
  myos_run_engine "$engine" "$sb" "$@" > "$out/$name.txt"
  rm -rf "$sb"
  printf 'recorded %s (%s lines)\n' "$name" "$(wc -l < "$out/$name.txt" | tr -d ' ')"
done
