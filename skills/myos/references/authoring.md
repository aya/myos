# Writing a stack, and working on the engine

## A stack

1. `stack/myapp/myapp.yml`: the compose file. Reference values, never
   literals: `image: myimage:${MYAPP_VERSION}`, `ports:
   ["${MYOS_BIND_PRIVATE:-127.0.0.1}:8080:80"]`, `labels: [SERVICE_80_TAGS=${MYAPP_SERVICE_80_TAGS}]`,
   `networks: [private]`.
2. `stack/myapp/.env.dist`: what the user must provide, with defaults that
   compute themselves, rendered once into `$WORKDIR/.env` by the first `up`:
   ```
   MYAPP_VERSION=1.4
   MYAPP_HOST=myapp.${DOMAIN}
   MYAPP_SECRET=$(head -c 30 /dev/urandom | base64)
   ```
3. `stack/myapp/myapp.settings`: what is recomputed every run:
   ```
   export MYAPP_SERVICE_80_TAGS
   MYAPP_SERVICE_80_NAME ?= myapp
   MYAPP_SERVICE_80_TAGS ?= @tagprefix(MYAPP,80)
   ```
4. Hooks the lifecycle needs: `actions/pre-backup` dumping the database into
   a volume before the archive, `actions/doctor` checking a licence or a
   quota, or the same as recipes of a `justfile`.
5. Check: `myos -n up myapp`, `myos env myapp`, `myos firewall myapp --strict`,
   `myos doctor myapp`; then `myos up myapp` and `myos status myapp --strict`.

A host stack (`stack/host/<name>.yml`) may publish public ports and declares
what the host firewall must open: `HOST_<NAME>_FIREWALL ?= 443/tcp`.

## Converting an old `.mk`

`share/tools/mk2settings.py stack/x/x.mk` writes the `.settings` (and the
groups into `.env`); conditional blocks and targets are left as comments to
rewrite by hand (a target becomes a hook). Check every value against the old
engine with `myos print-NAME x`.

## The engine

`myos` (wrapper) -> `lib/main.sh` (arguments, chaining) -> `lib/path.sh`,
`ref.sh`, `files.sh`, `stack.sh` (resolution) -> `lib/values.sh`,
`settings.sh` + `settings.awk`, `fn.sh`, `env.sh` (values) -> `lib/verb/*.sh`
with `hooks.sh`, `events.sh`, `lock.sh`. POSIX sh only; a function returns
through `R`; temporaries are prefixed per function. Tests: `make test`
(golden: `spec/golden/cases.txt` -> `expected/`, re-recorded with `make
golden-record CASES=...` and justified in `DELTAS.md`; verbs: `spec/verbs/`
against `spec/support/bin/docker`; unit: `spec/unit/`), `make lint`, `make
test-portability`, `make bench`. See `AGENTS.md`.
