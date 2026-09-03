---
name: myos
description: Deploy, inspect and troubleshoot docker compose stacks on a server or a fleet with the myos CLI (Make Your Own Stack). Use when asked to install myos, to start/stop/debug a stack (a host singleton, an application, a user stack), to add a stack to the catalogue, or to work on the myos framework itself.
---

# myos

myos runs docker compose stacks. It decides which compose files to load, under
which project name, with which variables. Everything else is docker.

## Is this the right tool

Use it when the repository or the host has one of:
- a `stack/` directory holding compose files,
- a `Makefile` that includes `make/include.mk`,
- `/etc/conf.d/myos` or `/etc/default/myos`,
- the `myos` command on PATH.

Otherwise call `docker compose` directly.

## Look before you touch

```sh
myos doctor              # requirements, config layers, stack path
myos ls                  # stacks reachable from here
myos ls --groups         # groups and what they expand to
myos env                 # resolved variables
myos -n up host          # print what `up` would run, without running it
```

**Always run `myos -n` before `up`, `down` or `restart` on a `host/` stack.**
Host stacks bind privileged ports and are shared by everything on the machine:
taking `host/fabio` down drops every site the machine serves.

## Working loop

```sh
myos ls                       # find the stack
myos -n config <stack>        # check the file list and the project name
myos up <stack>               # create and start
myos ps <stack>               # what is running
myos logs <stack>             # follow the logs
myos exec <stack> -- sh       # a shell in the service named after the stack
myos down <stack>             # remove the containers
```

## Naming a stack

A reference is `[<group>/]<name>[:<version>]`, or a path.

Commands chain: `myos build up logs host/fabio` runs the three in order and
stops at the first failure.

```sh
myos up                    # the current directory, when it holds a compose file
myos up host               # a group: expands to host/consul host/fabio ...
myos up host/fabio         # one stack
myos up postgres:9.6       # the 9.6 overlay of the postgres stack
myos -C /opt/app up        # somewhere else
myos -e master up          # in another environment
```

Stacks are looked up along the stack path: `./stack`, `../stack`,
`~/.local/share/myos/stack`, `/usr/local/share/myos/stack`, `/usr/share/myos/stack`.
`myos doctor` prints the resolved path.

A stack found in several of them is **merged**, the project last, so a project
adds `stack/postgres/postgres.local.yml` next to the catalogue's `postgres.yml`
and refines it instead of replacing it. The same goes for the settings hooks.

## Three kinds of stack

| kind | reference | compose project | meaning |
|---|---|---|---|
| host | `host/*` | the hostname | one per machine: binds 80/443, consul, certbot. Shared. Treat as production. |
| user | `User/*` | the user identity | one per user: ssh-agent, personal services |
| app | anything else | `<user>-<env>-<app>` | many per machine, one per user and environment |

Set `MYOS_PROJECT_FORMAT=user-app-env` on a deployment created before the
rename, otherwise its containers and volumes look like a different project.
See `references/conventions.md`.

## Rules

- Never run `myos clean` on a host stack: it removes images **and volumes**,
  including the certificates.
- Secrets belong in a file outside the repository, never in a compose file.
- A stack of the catalogue is shared: change it in `myos-stacks`, not in place
  on a server.
- Before upgrading myos on a machine that already runs stacks, pin the naming
  (`references/conventions.md`), or every project gets a new name.

## More

- `references/commands.md` — every command, and its equivalent in the old make targets
- `references/conventions.md` — file layout, naming, networks, variables, tags
- `references/troubleshooting.md` — what each failure means and how to fix it
- `references/authoring.md` — writing a stack, and working on myos itself
