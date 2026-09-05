# Restart protocol (2026-09-05)

The rewrite starts over from the make engine, not from `lib/`.

1. **Reference = `make/*` as it is**, bugs fixed one by one, each with a test
   that goes red then green. Known bugs and their locations are listed in the
   planning notes and in `git log --grep=fix` on this branch.
2. **Tests first, against make**: every target in scope gets a functional case
   in `spec/golden/cases.txt`, recorded from the make engine
   (`spec/golden/record.sh`, `spec/support/run.sh` engine `legacy`). That
   recording is the historical behaviour, defects included.
3. **Rewrite target by target in red/green**: the new implementation (`just`
   as the interface with line recipes, POSIX sh as the logic) must turn each
   case green under `MYOS_ENGINE=just`. A deliberate departure from the
   historical behaviour is written down in `spec/golden/DELTAS.md`.
4. The first attempt (`bin/myos`, `lib/`, `lib/cmd/`, `share/make/shim.mk`,
   `spec/golden/expected.cli/`, `spec/unit/`) is tagged `attempt-1-lib` and is
   not a base for the rewrite. What is worth keeping from it is ideas: port
   exposure by bind address (`expose --strict`), certificates derived from the
   route tags (dehydrated), `env-update` with forward references, stack
   directories merged along the search path, lazy defaults, command chaining,
   typed exit codes, the agent skill, the installer.
5. The catalogue readable by make is `myos-stacks@7289b83` (or `github/develop`
   here): the later hooks (`_stack.sh`) are not read by make.
6. Scope from real fleet usage (~15 targets): up down build config logs ps
   restart status, the `host` group, print-VAR, docker-build-<image>,
   setup-ufw, install bootstrap clean, apps-install. Never used: release,
   subrepo, git-*, deploy, ssh-*.
7. Keep and reuse: `spec/support/run.sh`, the docker mocks, the fixtures, the
   golden cases, `spec/bench/` (make 312 ms fixed + ~700 ms per stack; just
   line recipe 19 ms, shebang recipe 160 ms; shell hooks with command
   substitutions ~40 ms per computed setting on any engine).

Traps already paid for in POSIX sh, do not pay them again: `IFS=$'\n'` stops
argument splitting; `for w in $list` globs a `*` (use `set -f`); `[a-z]`
matches uppercase under fr_FR (use `[:lower:]`); a function called inside
`$( )` cannot return through a global; an environment variable must never be
taken for a stack group (lowercase names only); an unprefixed lazy default
named `host` runs `/usr/bin/host`; zsh does not split unquoted variables, so
test scripts run under `sh`.
