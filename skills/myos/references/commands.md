# Commands

`myos [options] VERB... [REF...] [KEY=VALUE...] [-- ARGS...]`. Verbs chain
and stop at the first failure. No reference means the current directory.
`STACK="a b"` is accepted (the make spelling).

| option | meaning |
|---|---|
| `-n`, `DRYRUN=true` | print every command instead of running it |
| `-C DIR` | work in DIR (the project directory, `$WORKDIR`) |
| `--json` | one JSON line per step, a JSON summary at the end |
| `--strict` | `status`, `firewall`: exit 4 on a finding |
| `--yes` | `restore`, `clean` of a host stack: confirm |
| `--bootstrap` | `up`: run the bootstrap even when `.env` exists |
| `--pause`, `--keep N` | `backup`: pause the project around the archive; keep N backups |
| `--from DIR\|latest`, `--no-backup`, `--force` | `restore` |
| `--wildcard`, `--self-signed`, `--check` | `cert` |
| `--target NAME`, `MYOS_TARGET=NAME` | the docker endpoint of the run: the value `MYOS_TARGET_<NAME>` holds `ssh://user@host`, `tcp://host:2376` (`DOCKER_HOST=`) or `context:<name>` (`DOCKER_CONTEXT=`). Declared in `$WORKDIR/.env` or the environment, not in a stack; an undeclared name is exit 3, before anything runs |
| `--backend compose\|swarm`, `MYOS_BACKEND=` | which engine applies the resolved files: `compose` (the default) or a Docker Swarm |
| `--prune` | `up --backend swarm`: pass `--prune` to `stack deploy`, removing the services the files no longer declare. Off by default, a project being deployed one reference at a time |
| `MYOS_POLICY_REQUIRE="limits healthcheck"` | `policy`: turn those two warnings into denials, so a cluster tightens on its own schedule |
| `MYOS_POLICY_ENFORCE=true` | run `policy --strict` before `up` and stop at exit 4 without deploying. Off by default; this is what the reconciler of a shared cluster sets |
| `SERVICE=x`, `NUM=n`, `ENV=e`, `-- args` | the service, the scale, the environment, the arguments of exec/run |

## Verbs

| verb | does |
|---|---|
| `up` | bootstrap when there is no `.env` yet (or `--bootstrap`), ensure the networks, `compose up -d`; with a firewall adapter asked for, apply the rules of a host project |
| `down`, `start`, `stop`, `restart`, `recreate` | the compose verb on the project |
| `build [image[:variant]]` | `docker build` of `docker/<image>/Dockerfile` in the stack directories (tag `<user>/<stack>/<env>/<image>`), `compose build` when the stack builds nothing itself |
| `config`, `ps`, `logs`, `exec`, `run`, `scale`, `connect`, `attach` | as compose; `exec` and `run` take `SERVICE=` and `-- args`; `status` reads `compose ps` as JSON |
| `bootstrap` | render `.env` from the `.env.dist` of the stacks, create the networks, build the images |
| `env-update` | render the missing keys of `.env` again (after a new `.env.dist` key) |
| `upgrade` | lock, backup, `git pull --ff-only` where a stack directory is a checkout, `compose pull`, `compose build --pull` when needed, `compose up -d`, wait for every service to be running and healthy (`MYOS_HEALTH_TIMEOUT`, 120 s); `MYOS_UPGRADE_BACKUP=false` skips the backup |
| `backup` | `pre-backup` hooks, one `tar.gz` per volume of the project (through an alpine container), the `.env` (mode 600), `manifest.json`, `post-backup` hooks; into `${MYOS_BACKUP_ROOT:-$WORKDIR/backup}/<project>/<date>/` |
| `restore --from` | refuses a manifest of another project (`--force`), needs `--yes` when not interactive, takes a safety backup (`--no-backup`), `down`, recreates the missing volumes, extracts, `up`, `post-restore` hooks |
| `firewall [audit]` | every published port of the compose files: service, host port, scope (public/private/mesh/address), address; `--strict` exits 4 when a stack that is not a host stack publishes a public port |
| `firewall apply` | the rules of a host stack (its public ports and `<SVC>_FIREWALL`, or the old `<SVC>_UFW_UPDATE`) through `MYOS_FIREWALL=auto\|ufw\|nftables\|pf\|none`; `-n` prints them |
| `policy [audit]` | per service, what a shared cluster cannot grant: `privileged`, `cap_add`, a host namespace (`pid`, `ipc`, `userns_mode`, `network_mode`), `devices`, an unconfined `security_opt`, a bind mount of the host and the docker socket are `deny`; no `healthcheck` and no `deploy.resources.limits` are `warn`. `--strict` exits 4 on a denial. The escalations of a `host/` stack are warnings — it is the trusted layer, but a proxy reading the docker API still wants a read-only socket proxy |
| `cert list` | the names the `urlprefix-` routes of the stacks need, wildcards marked |
| `cert [issue]` | `domains.txt` into the host volume, `dehydrated -c` in the dehydrated service (http-01); `--wildcard` adds the wildcards through `actions/cert-dns` or `MYOS_CERT_DNS_HOOK` (dns-01); `--self-signed` an openssl certificate per name; `--check` the expiry |
| `doctor` | docker, compose >= 2.21, just, jq, the path, `.env` against `.env.dist`, empty values the files reference, networks, locks, the `doctor` hooks of the stacks; exit 4 when a check fails |
| `clean` | `compose down --rmi all --volumes`; a host stack needs `--yes`; `.env` is kept |
| `shutdown` | `down` of the host and user projects of this machine |
| `install [URL [DIR]]` | clone a project, then bootstrap it |
| `ls`, `env`, `print-NAME`, `--version`, `-h` | the path, stacks and groups; the exported values; one value; the version; the usage |

## The swarm backend

`--backend swarm` changes the call, never the resolution: the same references,
the same path, the same six layers of values, the same overlays. `docker stack
deploy` reads one file, so the resolved files are rendered first:

```sh
myos -n --backend swarm up host/consul
# docker ... compose -f ... -p testhost config | docker ... stack deploy \
#   --with-registry-auth --detach=false -c - testhost
```

| verb | swarm |
|---|---|
| `up` | render, then `stack deploy`; the networks are created `--driver overlay --attachable`; no build (swarm ignores `build:`, so the image must be pushed and pinned beforehand) |
| `down` | `stack rm <project>` |
| `ps` | `stack services <project>` |
| `logs` | `service logs <project>_<service>`; `SERVICE=` is required |
| `config` | the render — it is exactly what gets deployed |

`build recreate restart start stop run scale connect exec attach install clean
bootstrap backup restore upgrade shutdown` are exit 2 here: a swarm service is
not a container one can restart or exec into by project name. `status
--strict` too — the replica counts of `stack services` are not the
state/health pairs the audit reads.

What swarm silently drops from a compose file is not this backend's business:
`build:`, `depends_on:`, `container_name:` and `restart:` (it reads
`deploy.restart_policy`), and a named volume is local to the node the task
lands on, so a service with state needs a placement constraint.

## What the make targets became

| make | now |
|---|---|
| `make up STACK=host/fabio` | `myos up host/fabio` |
| `make host` | `myos up host` |
| `make stack-host-config` | `myos stack-host-config` (kept) or `myos config host` |
| `make print-COMPOSE_FILE STACK=x` | `myos print-COMPOSE_FILE x` |
| `make docker-build-web` | `myos build web` (`docker-build-web` is kept) |
| `make bootstrap`, `make install` | `myos bootstrap`, `myos install` (no system setup: `doctor` says what the host lacks) |
| `make .env-update` | `myos env-update` |
| `make setup-ufw`, `SETUP_UFW=true` | `myos firewall apply host`, `MYOS_FIREWALL=ufw` |
| `host-certbot`, `host-ssl-certs`, acme | `myos cert host`, `myos cert host --self-signed` |
| `make clean` | `myos clean` (`--yes` for a host stack; keeps `.env`) |
| `apps-install`, `ssh*`, `deploy*`, `release*`, `subrepo*`, `git-*`, `setup-*` | gone |
