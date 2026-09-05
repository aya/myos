# CHANGELOG

## v2.0.0-dev - 2026-09-05

The engine is rewritten in POSIX sh (`myos`, `lib/`), with `just` as the
interface for humans and agents; GNU make is gone. The behaviour of every make
target in use was recorded first (`spec/golden/`), the rewrite was driven by
those recordings, and every intentional difference is in `spec/golden/DELTAS.md`.

- one model of stack: a directory of compose files, found on a path ordered by
  precedence or given as a path (the project directory is a stack like any
  other); a reference names the compose project, a group expands into its
  members, references naming the same project are one compose call
- the computed defaults of a stack are `.settings` files (`NAME ?= expr` with
  `${X}` references and `@tagprefix(...)`-style calls of the routing macros),
  compiled by one awk into sh functions, lazy and memoised; the user's values
  always win. `share/tools/mk2settings.py` converts the `.mk` of the old
  catalogue
- `.env.dist` is rendered once into `$WORKDIR/.env` (missing keys only,
  `${X}` through every layer, `$(command)` run); `up` does it the first time
- lifecycle: `bootstrap`, `upgrade` (backup, pull, build, up, wait for healthy,
  under a lock), `backup` (one archive per volume, the `.env`, a manifest),
  `restore --from` (behind guards), `status`, `doctor` (exit 4 when a check
  fails), with hooks per stack (`actions/<phase>` or a justfile recipe) and
  events (text, or NDJSON under `--json`)
- `firewall` audits the published ports from the compose files (public,
  private, mesh) and applies rules through ufw, nftables or pf; the portable
  defence is the bind address, `${MYOS_BIND_PRIVATE}`
- `cert` derives the certificates a host needs from its `urlprefix-` routes and
  issues them through dehydrated (http-01; wildcards through a dns-01 hook);
  `--self-signed` for a bootstrap, `--check` for the expiry
- an unknown verb exits 2, an unknown stack exits 3
- default project name `<user>-<env>-<app>`; `MYOS_PROJECT_FORMAT=user-app-env`
  keeps the names of an existing deployment
- gone: `apps-install`, `ssh*`, `deploy*`, `release*`, `subrepo*`, `git-*`
  (never used), the make include of a project, `setup-*` (system setup is not
  the job of a stack tool)
- fixed in the make engine before the rewrite, and kept: credentials of a
  remote URL leaked into image labels; `exec` recipe was a bash syntax error;
  `clean` removed every image and ran `rm -i`; a versioned stack (`postgres:9.6`)
  broke every run; `JWT` always signed an empty payload; the `prepend` route
  option was misspelled; `space` was undefined so routes were joined by ` ,`

## v1.1 - 2026-09-03

- move the stack catalogue and the docker build contexts to the myos-stacks project
- keep the framework infra compose files in share/compose and the myos tool image in share/docker
- fix stack_path resolution: host/<svc> stacks were only found when the project
  stack directory sorted first
- drop the docker/compose image fallback: docker compose >= 2.24.4 or docker-compose is required
- add a shellspec golden test harness (make test)

## v1.0-beta - 2026-07-29

* split make files in `myos` project and docker files in `stack` project

## v1.0-alpha - 2022-11-29

* node is host

## v0.9.9 - 2022-11-22

* node name is `hostname`

## v0.9 - 2022-11-11

* split make files in `myos` project and install files in `yaip` project

## v0.1-beta - 2022-06-30

Beta release, welcome ipfs

* add arm64 support
* add ipfs stack
* add x2go with ssh ecryptfs homedir
* update docker-compose to v2.5.0

## v0.1-alpha - 2021-07-14

Public release, code is doc

* update license to GPL as freedom should not allow evil to move faster than god

## v0.0.1 - 2021-02-08

Initial import

* import previous `infra` project
* rename project to myos - make your own stack

## 2020

* makefile can be included in any project
* multi user/environment

## 2018

The `infra` project

* ansible : deploy docker to production
* aws : upload alpine iso to s3 and create ami
* packer : build alpine iso with docker daemon
* stack/services : docker stack for shared services
* subrepo : sync all git repositories with monorepo

## 2017

Initial work

* makefile for a monorepo with many docker-compose projects
