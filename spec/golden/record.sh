#!/bin/sh
# Record golden outputs into spec/golden/expected/ (MYOS_ENGINE=just, the
# default); another engine writes into spec/golden/expected.<engine>/.
# Usage: spec/golden/record.sh [case-name ...]
set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=spec/support/run.sh
. "$here/../support/run.sh"
MYOS_ROOT=${MYOS_ROOT:-$(cd "$here/../.." && pwd)}
only="$*"
engine=${MYOS_ENGINE:-just}
out="$here/expected"; [ "$engine" = just ] || out="$here/expected.$engine"
mkdir -p "$out"
cat "$here"/cases*.txt | grep -v '^#' | while IFS='|' read -r name fixture args; do
  name=$(echo "$name" | tr -d ' '); fixture=$(echo "$fixture" | tr -d ' ')
  [ -z "$name" ] && continue
  if [ -n "$only" ]; then case " $only " in *" $name "*) ;; *) continue ;; esac; fi
  sb=$(myos_sandbox "$fixture")
  eval "set -- $args"
  myos_run_engine "$engine" "$sb" "$@" > "$out/$name.txt"
  rm -rf "$sb"
  printf 'recorded %s (%s lines)\n' "$name" "$(wc -l < "$out/$name.txt" | tr -d ' ')"
done
