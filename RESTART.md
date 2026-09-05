# Where the rewrite stands

Branch `tdd`. The plan (context, decisions, model, verbs, test strategy, phases)
is the file `~/.wclaude/plans/je-souhaite-creer-un-whimsical-treasure.md`;
this note only says what is in the repository and what to trust.

- `make/` is the **reference**: the historical engine, with bugs fixed one by one.
  `spec/golden/expected/` is its recorded behaviour, never edited by hand
  (`make golden-record CASES=...` re-records).
- The rewrite lives in `lib/` (POSIX sh) behind `justfile` and the `myos`
  wrapper. `MYOS_ENGINE=just make test-golden` runs the same cases on it; an
  intentional difference is recorded in `spec/golden/expected.just/` and listed
  in `spec/golden/DELTAS.md`.
- Verbs with no make history (`backup restore upgrade cert firewall doctor
  status`) are specified by `spec/verbs/*_spec.sh` against the docker mock of
  `spec/support/bin/`.
- The first rewrite attempt (`bin/myos`, the old `lib/`, `share/make/shim.mk`)
  is the tag `attempt-1-lib`; it is not a base, only a source of ideas.
- The catalogue readable by make is `myos-stacks@7289b83` (a copy is the
  fixture `spec/fixtures/catalogue`); the hooks written later (`_stack.sh`) are
  not read by make.

Traps already paid for in POSIX sh, do not pay them again: `IFS=$'\n'` stops
argument splitting; `for w in $list` globs a `*` (use `set -f`); `[a-z]`
matches uppercase under fr_FR (use `[:lower:]`); a function called inside
`$( )` cannot return through a global; an environment variable must never be
taken for a stack group (lowercase names only); an unprefixed lazy default
named `host` runs `/usr/bin/host`; zsh does not split unquoted variables, so
test scripts run under `sh`; `case` inside a shellspec `Parameters:dynamic`
breaks the example count; `MYOS_DOCKER_LOG` must be exported for the mock.
