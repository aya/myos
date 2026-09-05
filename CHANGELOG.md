# CHANGELOG

## v2.0.0-dev - 2026-09-03

- new bash CLI (`bin/myos`, `lib/`): one model for a project directory, a
  catalogue stack, a group and a host singleton
- unknown command or unknown stack now fails, instead of succeeding silently
- default compose project is `<user>-<env>-<app>`; set
  `MYOS_PROJECT_FORMAT=user-app-env` on deployments created before this
- `myos ls`, `myos env`, `myos doctor` to inspect an installation
- `install.sh`, and the catalogue is looked up beside the installation
- agent skill in `skills/myos/`, contributor notes in `AGENTS.md`
- stacks carry their settings in `<name>.env` and `<name>.sh` hooks, so the
  catalogue no longer needs make to be installed
- lazy defaults (`myos_default_<VAR>` functions) give the recursive `?=` of
  make in pure shell: an explicit value wins, and the default is recomputed
  at each reference
- `myos env-update` generates a `.env` from the `.env.dist` templates,
  expanding `${VAR}` and `$(command)`, including forward references
- the project `.env` now wins over `/etc/conf.d/myos`, as documented;
  `MYOS_CONF_PRIORITY=system` restores the previous order
- `share/make/shim.mk`: make as an optional front end over the same shell code
- `myos expose` reports what each stack publishes and to whom, and `--strict`
  fails when a port faces the world without saying so. `MYOS_BIND_PUBLIC`,
  `_PRIVATE` and `_MESH` let a stack bind its published ports, which replaces
  the linux-only ufw-docker patching with something that behaves the same on
  macOS and needs no privilege
- commands chain: `myos build up logs host/fabio`, as make targets did
- the stack catalogue no longer needs make at all: its settings are hooks, and
  only six stacks keep a .mk, for targets
- a stack found in several directories of the stack path is merged, project
  last, so a project refines a catalogue stack instead of replacing it
- `--color always|never|auto`, and no colour when the output is piped
- verified under the /bin/sh of Alpine (busybox) and Debian (dash)
- the make engine still works and is still covered by the golden tests

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
