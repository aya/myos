# Troubleshooting

Start with `myos doctor`, then `myos -n <command>` to see what would run.

## `stack not found: <name>` (exit 3)

The reference is not on the stack path, which the message prints.
- `myos ls` shows what is reachable.
- The catalogue may not be installed: `git clone <myos-stacks> /usr/local/share/myos`.
- A stack of the project is only found from the project: use `myos -C /path/to/project`.

## `docker compose >= 2.24.4 not found` (exit 4)

Install the compose plugin, or a `docker-compose` binary of that version.
myos no longer falls back to a compose image.

## `unknown command: <x>` (exit 2)

Check the spelling against `myos help`. The make engine accepted any target
and exited 0 after printing a warning, so typos used to look like successes.

## The containers came back under a different name

The default project name changed from `<user>-<app>-<env>` to
`<user>-<env>-<app>`. The old containers and volumes are still there, under the
old project. Put `MYOS_PROJECT_FORMAT=user-app-env` in the `.env` of the
deployment (or in `/etc/conf.d/myos`) and bring it up again.

Check first: `myos env COMPOSE_PROJECT_NAME` against `docker ps --format '{{.Names}}'`.

## `network <name> declared as external, but could not be found`

The `private` or `public` network is missing. `myos up` creates them; a bare
`docker compose up` does not. Or create it by hand:
`docker network create <user>-<env>`.

## A service is up but not routed

In order: the port must be `expose`d (registrator ignores what it cannot see),
the labels must be on the service, the consul check must pass, and only then
does fabio route the `urlprefix-` tag.

```sh
myos config <stack> | grep -A5 labels      # what the labels resolve to
myos exec host/consul -- consul catalog services
myos logs host/registrator
```

## A variable is empty in the container

myos only passes the variables the compose files actually mention. Check with
`myos env` and `myos config <stack>`. A variable set in a `.env` of another
directory is not read: only the workdir's `.env` is.

## On macOS with Colima

The daemon lives in a VM: a bind mount only works for a path the VM shares, and
`host.docker.internal` is the way back to the host. `myos doctor` prints the
`DOCKER_HOST` in use.

## Something changed after upgrading myos

`spec/golden/DELTAS.md` in the myos repository lists every intentional
difference between the make engine and the CLI, with the reason.
