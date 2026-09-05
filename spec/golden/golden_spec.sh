#shellcheck shell=sh
# Golden tests: every case of cases.txt must produce the recorded output.
# MYOS_ENGINE=legacy (default) runs the make engine, MYOS_ENGINE=just the rewrite.
# For another engine, spec/golden/expected.<engine>/<case>.txt overrides the
# legacy expectation when a delta is intentional (documented in DELTAS.md).
Describe 'golden'
  engine=${MYOS_ENGINE:-legacy}
  expected_file() {
    if [ "$engine" != legacy ] && [ -f "$SHELLSPEC_PROJECT_ROOT/spec/golden/expected.$engine/$1.txt" ]; then
      printf '%s\n' "$SHELLSPEC_PROJECT_ROOT/spec/golden/expected.$engine/$1.txt"
    else
      printf '%s\n' "$SHELLSPEC_PROJECT_ROOT/spec/golden/expected/$1.txt"
    fi
  }
  run_case() {
    sb=$(myos_sandbox "$2")
    eval "set -- $3"
    myos_run_engine "$engine" "$sb" "$@"
    rm -rf "$sb"
  }
  Parameters:dynamic
    while IFS='|' read -r name fixture args; do
      name=$(echo "$name" | tr -d ' '); fixture=$(echo "$fixture" | tr -d ' ')
      [ -z "$name" ] || [ "${name#\#}" != "$name" ] && continue
      %data "$name" "$fixture" "$args"
    done <<-CASES
	$(cat "$SHELLSPEC_PROJECT_ROOT"/spec/golden/cases*.txt)
	CASES
  End
  pending() { [ -f "$SHELLSPEC_PROJECT_ROOT/spec/golden/pending.$engine" ] && grep -qx "$1" "$SHELLSPEC_PROJECT_ROOT/spec/golden/pending.$engine"; }
  It "matches recorded output: $1 ($engine)"
    Skip if "listed in pending.$engine (not implemented yet)" pending "$1"
    When call run_case "$1" "$2" "$3"
    The output should equal "$(cat "$(expected_file "$1")")"
  End
End
