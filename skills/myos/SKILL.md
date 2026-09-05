---
name: myos
description: Deploy, inspect, back up, upgrade and troubleshoot docker compose stacks on a server or a fleet with myos (Make Your Own Stack). Use when asked to install myos, to start/stop/debug a stack (a host singleton, an application, a user stack), to back up or restore one, to check its ports or certificates, to write a stack for the catalogue, or to work on the myos engine itself.
---

# myos

myos runs docker compose stacks. It decides which compose files to load, under
which project name, with which values, and it carries a stack through its
life (bootstrap, up, upgrade, backup, restore, firewall, cert, doctor).
Everything else is docker.

## Is this the right tool

Use it when the repository or the host has one of: a `stack/` directory of
compose files, `/etc/conf.d/myos` or `/etc/default/myos`, the `myos` command
on PATH, a `justfile` whose recipes call `lib/main.sh`. Otherwise call
`docker compose` directly.

## Look before you touch

```sh
myos doctor <stack>          # what is missing here: docker, compose, .env keys, networks (exit 4 = something fails)
myos ls                      # the stacks and groups reachable from here, and the path
myos -n up <stack>           # print what `up` would run, without running it
myos config -n <stack>       # the files, the project name (dry run)
myos env <stack>             # every value the compose files will receive
myos firewall <stack>        # every published port, and to whom (public/private/mesh)
```

**Always run `myos -n` before `up`, `down`, `restart` or `upgrade` on a `host/`
stack.** Host stacks bind the privileged ports and are shared by everything
on the machine: taking `host/fabio` down drops every site the machine serves.
`myos clean` refuses a host stack without `--yes`: it removes the volumes.

## Working loop

```sh
myos ls                        # find the stack
myos up <stack>                # bootstrap the first time (.env rendered from .env.dist), then compose up
myos status <stack> --strict   # every service running and healthy, or exit 4
myos logs <stack>              # follow the logs
myos exec <stack> -- sh        # a shell in the service named after the stack (SERVICE=x for another)
myos backup <stack>            # before anything risky: one archive per volume + .env + manifest
myos upgrade <stack>           # backup, pull, build, up, wait for healthy; exit 1 lists what is not
myos restore <stack> --from latest --yes
myos down <stack>
```

Verbs chain and stop at the first failure: `myos build up logs myapp`.
`--json` turns every step into one JSON line (`{"verb","stack","step",
"target","status","detail"}`) and ends with `{"verb","status","exit",
"artifacts":[...]}`: read that, not the text.

Exit codes: 0 ok, 1 failure, 2 usage or unknown verb, 3 unknown stack, 4 an
audit found something (`doctor`, `--strict`), 5 the project is locked by
another run.

## Naming a stack

A reference is `[<scope>/]<name>[:<version>]`, or a path.

```sh
myos up                    # the current directory, when it holds compose files
myos up host               # a group: expands to host/consul host/fabio ...
myos up host/fabio         # one stack
myos up postgres:16        # the postgres stack with its 16 overlay
myos up a b                # two projects, in order
myos -C /opt/app up        # somewhere else
myos up myapp ENV=master   # in another environment (any KEY=VALUE is a value of the run)
```

Stacks are looked up along a path, by precedence: `/usr/share/myos/stack`,
`/usr/local/share/myos/stack`, `~/.local/share/myos/stack`, `../stack`,
`./stack` (`MYOS_PATH` overrides it). A stack present in several of them is
**merged**, the project last: a project adds `stack/postgres/postgres.local.yml`
next to the catalogue's `postgres.yml` and refines it. A reference names the
compose project: `up testing` (a group) is one project named `testing` holding
the files of every member.

| kind | reference | compose project | meaning |
|---|---|---|---|
| host | `host/*` | the hostname | one per machine: binds 80/443, consul, fabio, certificates. Shared. Production. |
| user | `User/*` | the user identity | one per user: ssh-agent, personal services |
| app | anything else | `<user>-<env>-<app>` | many per machine, one per user and environment |

A deployment created before this version keeps its names with
`MYOS_PROJECT_FORMAT=user-app-env` in its `.env` or in the machine config.

## Rules

- A port a stack publishes on `0.0.0.0` answers the world, and on linux the
  host firewall does not see it (docker writes its own rules). Only `host/*`
  stacks may do that; the others bind `${MYOS_BIND_PRIVATE}:<port>:<port>`
  (or `${MYOS_BIND_MESH}` for the overlay network). `myos firewall <stack>
  --strict` enforces it; `myos firewall apply host` writes the host rules.
- Certificates come from the routes: `myos cert list host` shows the names the
  `urlprefix-` tags need, `myos cert host` asks dehydrated for them, a wildcard
  needs `--wildcard` and a dns-01 hook. At bootstrap `myos cert host
  --self-signed` gives fabio something to start with.
- Secrets belong in `$WORKDIR/.env` (rendered from `.env.dist`, owner only),
  never in a compose file. `backup` copies it beside the archives.
- A stack of the catalogue is shared: change it in `myos-stacks`, not in place
  on a server.
- Before upgrading myos on a machine that runs stacks, pin the naming, or
  every project gets a new name.

## More

- `references/commands.md` — every verb, its options, and what the old make targets became
- `references/conventions.md` — files of a stack, the settings language, values and layers, networks, routes
- `references/authoring.md` — writing a stack (compose, `.env.dist`, `.settings`, hooks), and working on the engine
- `references/troubleshooting.md` — what each failure means and how to fix it
