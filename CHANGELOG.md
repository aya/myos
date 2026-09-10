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
- `--target NAME` names the docker endpoint of a run: the value
  `MYOS_TARGET_<NAME>` holds `ssh://user@host`, `tcp://...` or
  `context:<name>`, so a deployment declares the machine it goes to in the
  repository that holds the stacks. Resolved before anything runs; an
  undeclared name exits 3. What the model derives from the host -- `HOSTNAME`,
  the public network, the project of a host stack -- is named after the target,
  not after the machine running the command
- `--backend swarm` deploys to a Docker Swarm: the resolved files are rendered
  by `compose config` and piped into `docker stack deploy`, the networks are
  created as attachable overlays, `down` is `stack rm` and `ps` is `stack
  services`. The resolution is untouched — same references, same values, same
  overlays, and N references to one project are still one deployment. The verbs
  a swarm service has no equivalent for exit 2 rather than do something else
- `policy [audit]` is the gate of a shared cluster: per service it reports what
  cannot be granted -- `privileged`, `cap_add`, a host namespace, `devices`, an
  unconfined `security_opt`, a bind mount of the host, the docker socket (deny),
  and the missing `healthcheck` / `deploy.resources.limits` (warn, promoted by
  `MYOS_POLICY_REQUIRE`). `--strict` exits 4; `MYOS_POLICY_ENFORCE=true` puts it
  in front of `up`. Access to a manager's docker socket is root on the cluster
  and swarm has no RBAC, so nothing below the engine refuses these
- `secrets.<ENV>.env` / `secrets.env` are sops files, decrypted into a layer
  between `$WORKDIR/.env` and the defaults of the stacks: one age key pair per
  cluster, so a cluster cannot read the secrets of another and the private key
  never leaves the machine that applies. `myos secrets` lists the provider, the
  files and the names -- never the values. `MYOS_SECRETS` is the seam an
  OpenBao provider would use
- `apply` is the deployment verb: converge a checkout to `--from <remote>/<ref>`
  (fetch, `git verify-commit` under `MYOS_APPLY_VERIFY`, hard reset), run the
  policy gate, deploy, wait for healthy -- under the lock and the `*-apply`
  hooks. A reconciler loops on it and an operator runs it by hand when the
  forge is down: one execution path, several triggers. It refuses a dirty
  checkout without `--force`
- a service declares its route once and it renders twice: `@tagprefix` the
  canonical `urlprefix-` form, `@traefikrule` the same route as a traefik rule,
  selected by `MYOS_ROUTER`. `cert` reads the canonical form either way, so
  certificates do not depend on which proxy is in front
- `myos_verb_with_hooks` keeps the exit code of the verb instead of collapsing
  every failure to 1: 4 is an audit finding, not a failure
- vendoring an upstream compose works as advertised: `firewall audit` honours
  the merge tags (`ports: !override` in an overlay replaces the list rather
  than adding to it), and a `.env.dist` line now initialises a name the engine
  answers with a default of its own (`DOMAIN`, `ENV`, `USER`, `HOSTNAME`,
  `DOCKER_IMAGE_TAG`) instead of being silently overwritten by that default
- `migrate pin` fonctionne : le format de nommage écrit dans `.env` nomme
  vraiment le projet. `myos_project_name` lisait la variable du shell, jamais
  la couche `.env` où `migrate pin` l'écrit, donc le levier qui préserve les
  noms d'une flotte existante n'avait aucun effet tout en rapportant un succès
- la configuration système est un repli de la machine et non un ordre : elle est
  marquée (`MYOS_CONF_<nom>`) et classée sous le `.env` du projet, tout en
  restant exportée pour le CLI docker. Un `DOMAIN=` de `/etc/default/myos`
  écrasait le domaine que le projet déclare
- un dépôt de configuration alimente les valeurs (`<env>/<app>/.env` et
  `secrets.env` chiffré, la disposition du moteur make), `myos secrets pull` le
  clone ou le met à jour : une CI et un opérateur tapent la même commande et
  obtiennent le même résultat. `env-update` n'écrit plus une clé qu'une couche
  réelle fournit, les littéraux de `.env.dist` sont lus avant tout rendu, et
  `MYOS_USER` dit à qui appartient un déploiement plutôt que le compte qui
  lance la commande
- le moteur demande BuildKit à compose (`DOCKER_BUILDKIT=1`, surchargeable) :
  c'est le builder par défaut de docker et le seul qui lise `RUN --mount=`
- `up` exécute les hooks de ses stacks comme les autres verbes de cycle de vie,
  et un hook reçoit l'endpoint du run, de sorte qu'un `post-up` qui appelle
  docker parle à la cible et non au poste de travail
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
