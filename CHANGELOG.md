# CHANGELOG

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
