#!/bin/sh
# Run the golden suite with the /bin/sh of this system (dash, busybox ash...).
# Used by `make test-portability` inside the alpine and debian images.
set -e
cd "$(dirname "$0")/../.."
if command -v shellspec >/dev/null 2>&1; then
  shellspec --shell sh spec/golden
else
  # no shellspec in the image: replay the cases with the recorder and diff
  engine=${MYOS_ENGINE:-just}
  . spec/support/run.sh
  fails=$(mktemp)
  only="$*"
  cat spec/golden/cases*.txt | grep -v '^#' | while IFS='|' read -r name fixture args; do
    name=$(echo "$name" | tr -d ' '); fixture=$(echo "$fixture" | tr -d ' ')
    [ -z "$name" ] && continue
    if [ -n "$only" ]; then case " $only " in *" $name "*) ;; *) continue ;; esac; fi
    exp=spec/golden/expected/$name.txt
    [ "$engine" = just ] || { [ -f "spec/golden/expected.$engine/$name.txt" ] && exp=spec/golden/expected.$engine/$name.txt; }
    sb=$(myos_sandbox "$fixture"); eval "set -- $args"
    if myos_run_engine "$engine" "$sb" "$@" | diff - "$exp" > "$sb/diff" 2>&1; then :; else echo "FAIL $name" | tee -a "$fails"; [ -n "${PORTABILITY_VERBOSE:-}" ] && head -n 12 "$sb/diff"; fi
    rm -rf "$sb"
  done
  if [ -s "$fails" ]; then rm -f "$fails"; exit 1; fi
  rm -f "$fails"; echo ok
fi
