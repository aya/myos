#!/bin/sh
# Run the golden suite with the /bin/sh of this system (dash, busybox ash...).
# Used by `make test-portability` inside the alpine and debian images.
set -e
cd "$(dirname "$0")/../.."
if command -v shellspec >/dev/null 2>&1; then
  shellspec --shell sh spec/golden
else
  # no shellspec in the image: replay the cases with the recorder and diff
  engine=${MYOS_ENGINE:-legacy}
  . spec/support/run.sh
  fails=$(mktemp)
  grep -v '^#' spec/golden/cases.txt | while IFS='|' read -r name fixture args; do
    name=$(echo "$name" | tr -d ' '); fixture=$(echo "$fixture" | tr -d ' ')
    [ -z "$name" ] && continue
    exp=spec/golden/expected/$name.txt
    [ "$engine" = legacy ] || { [ -f "spec/golden/expected.$engine/$name.txt" ] && exp=spec/golden/expected.$engine/$name.txt; }
    sb=$(myos_sandbox "$fixture"); eval "set -- $args"
    if myos_run_engine "$engine" "$sb" "$@" | diff -q - "$exp" >/dev/null; then :; else echo "FAIL $name" | tee -a "$fails"; fi
    rm -rf "$sb"
  done
  if [ -s "$fails" ]; then rm -f "$fails"; exit 1; fi
  rm -f "$fails"; echo ok
fi
