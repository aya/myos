# Benchmark of the engines

Same work, four engines, five runs, median. Docker is the mock of
`spec/support/bin`, the catalogue is `myos-stacks` reached through
`$HOME/.local/share/myos/stack`, the environment is `env.sh`.

    sh spec/bench/run.sh

`justfile` is a prototype of just as the engine: shebang recipes that source
`lib/*.sh` once. `go/main.go` is a prototype of the core in Go: stack path,
groups, compose files, project name, dry-run command; `export` runs one `sh`
per stack directory to evaluate the shell hooks.

## Results, 2026-09-05, Mac Studio M2 Ultra

| work | make | sh (bin/myos) | just | go |
|---|---:|---:|---:|---:|
| fixed cost, empty target | 312 ms | 50 ms | 170 ms | 23 ms |
| `up` 1 / 3 stacks, no hooks in the stack | 792 / 2201 | 177 / 332 | 204 / 268 | 23 / 23 |
| `up` 1 / 3 stacks, real catalogue with hooks | — | 353 / 855 | (prototype does not load hooks) | (idem) |
| `export`, 80 settings of the `host` group | — | 1477 | 1314 | 720 (1 sh) |
| same, `MYOS_VAR_MEMO=1` | — | 1503 | 1318 | 774 |
| one computed setting (`HOST_FABIO_SERVICE_9998_TAGS`) | — | ~43 ms net (69 − 26) | | |

Reference points: `sh -c :` 24 ms, `just --version` 27 ms, sourcing `lib/*.sh` +2 ms.

## What it says

- The engine's own cost: go flat at 23 ms; sh 177 ms + ~63 ms per stack; just
  204 ms + ~32 ms per stack; make 792 ms + ~700 ms per stack (it re-reads
  itself for every stack).
- The shell hooks cost ~40 ms per computed setting, on every engine: 80
  settings ≈ 0.7 s even from Go, which runs the very same `sh`. Memoisation
  changes nothing, because the cost is not repeated lookups: each `tagprefix`
  spawns 15-20 command substitutions for distinct, mostly empty, variables.
- `bin/myos` doubles that to 1.5 s by loading the hooks of a directory once
  per stack reference instead of once per directory: `host/consul`,
  `host/fabio` and `host/registrator` share `stack/host/_stack.sh`.
- just's fixed cost (170 ms for a shebang recipe, against 27 ms for `just
  --version`) is its own overhead of writing and running the recipe script.
