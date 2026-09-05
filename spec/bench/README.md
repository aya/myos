# Benchmark of the engine

Same work, five runs, median, measured by one python process (its own start
is not counted). Docker is the mock of `spec/support/bin`, the catalogue is
`spec/fixtures/catalogue` (the make-readable `myos-stacks`, converted), the
environment is `env.sh`.

    make bench                      # spec/bench/run.sh
    spec/bench/profile.sh up host   # what one run forks

## Results, 2026-09-05, Mac Studio M2 Ultra (a fork costs ~3 ms here, ~1 ms on linux)

| work | ms |
|---|---:|
| `myos --version` (load the engine) | 20 |
| `print-STACK_DIR host/consul` (path, one stack, its settings compiled) | 71 |
| `up host/consul`, dry run | 81 |
| `up host` (3 stacks, one project) | 111 |
| `up default` (memcached mysql rabbitmq redis: 4 directories of settings) | 177 |
| `env host` (every exported value of the host group, ~80 settings) | 215 |
| `print-HOST_FABIO_SERVICE_9998_TAGS` (one routed tag) | 106 |
| `status host` against the mock | 141 |

For the record, the same work on the make engine this replaced (measured on
2026-09-05 before its removal, python start included, ~80 ms to subtract):
312 ms for an empty target, 792 ms for `up` of one stack, 2201 ms for three
(it re-read itself once per stack).

## What costs

`spec/bench/profile.sh` counts the external commands of a run: about 15 for
one stack (the realpath of the path entries, the compilation of the settings
by awk, the sort of the suffixes, the `tr` of the names that are not already
uppercase). The rest is the shell interpreting the compiled settings (a few
thousand statements). A `tr` is skipped when the case is already right, a
settings file is compiled once per run, a computed value is memoised until
the stack changes.
