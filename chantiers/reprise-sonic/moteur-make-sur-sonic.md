# myos (moteur Makefile) sur sonic — analyse en lecture seule

Date de l'analyse : 2026-10-18. Machine : `sonic` (hostname `sonic`, domaine
`asycn.io`, docker 29.9.1, plugin compose 2.26.1, aya uid 123, groupe docker 115).

Méthode : lecture du code (copié par `tar` vers le Mac, sans `.git`), `git
log/status/diff`, `docker inspect`, `docker network ls`, `docker images`,
`~/.bash_history` d'aya. **Aucune commande `make` ni `myos` n'a été lancée**,
aucun conteneur ni fichier n'a été modifié sur sonic.

Convention : **[C]** = constaté (sortie de commande ou code lu), **[D]** = déduit
(raisonnement à partir du constaté, non prouvé par exécution).

---

## 0. Ce qu'il faut savoir avant tout

1. **[C] Il y a deux moteurs sur sonic, et `myos` n'est pas `make`.**
   - `/usr/local/bin/myos` → lien vers `/usr/local/lib/myos/myos`. Ce checkout
     est la branche `lightning`, commit `0e09506` (2026-07-28, « move docker and
     stack dir », CHANGELOG `v1.0-beta`), remotes `github.com/aya/myos` et
     `git.open.us.org/aya/myos`. Il **ne contient ni `stack/host` ni les stacks** :
     seulement `make/`, `docker/{myos,compose}`, `stack/myos/`.
   - `make …` lancé dans `/home/aya/Sources/myos` utilise le `make/` de **ce**
     dépôt (branche `tmp`, commit `429270f` 2026-02-20, remote
     `git.open.us.org/ACL/myos`), plus ancien.
   - Les deux lisent le même `.env` et les mêmes `stack/` quand on est dans
     `/home/aya/Sources/myos`, mais **pas avec les mêmes défauts** : le moteur
     `lightning` met `DOCKER_IMAGE_TAG ?= latest` (et `ENV ?= local`), le moteur
     de `Sources/myos` met `DOCKER_IMAGE_TAG ?= $(ENV)` (donc `local` via `.env`).
2. **[C] Chronologie qui le prouve** (heures UTC) :
   - 2026-09-26 12:22 : images `sonic/fabio:latest`, `sonic/consul:latest`,
     `sonic/registrator:latest` construites par compose (label projet `sonic`) →
     **[D]** par `myos up STACK=host host='host/fabio host/consul host/registrator'`
     (moteur `lightning`, tag `latest`), présent dans l'historique.
   - 2026-10-07 22:18 : `.env` de `Sources/myos` modifié (mtime 2026-10-08 00:18 +02).
   - 22:23:37 : `sonic-nginx-1` recréé, fichiers compose = nginx seul (7 fichiers)
     → **[D]** `make host host=host/nginx` (historique ligne 196).
   - 22:24:53 : image `sonic/ufw-docker:local` construite → effet de bord de
     `ufw-update` → `setup-ufw` → `ufw-build` (voir §1.6).
   - 22:28:45 : `sonic-acme-1`, `sonic-consul`, `sonic-fabio`, `sonic-registrator`
     recréés avec la liste complète (21 fichiers) et les images **`:local`**
     → **[D]** `make host` (historique ligne 198). Fabio/consul/registrator sont
     donc **revenus** sur les images `:local` d'août 2025 (`sonic/fabio:local`
     construite le 2025-08-10) ; les images `:latest` du 26/09 ne tournent plus.
   - **[C]** La commande de `sonic-fabio` contient bien les `realm=pilot/erp/banksync`
     de `HOST_FABIO_PROXY_AUTH` du `.env` actuel.
3. **[D] Conséquence pratique** : pour recréer à l'identique ce qui tourne, il
   faut utiliser **`make` depuis le checkout d'origine**, pas `myos`. Un
   `myos up STACK=host …` remettrait fabio/consul/registrator sur `:latest`
   (images différentes → recréation).

---

## 1. Comment fonctionne ce myos

### 1.1 Point d'entrée

- **[C]** `/usr/local/bin/myos` (bash) : `MYOS=$(dirname $(readlink $0))`
  = `/usr/local/lib/myos`, source `/etc/default/myos`, puis
  `exec env $(cat /etc/default/myos) MYOS=. WORKDIR="$PWD" make -esC "$MYOS" "$@"`.
  `-e` : l'environnement prime sur les affectations des makefiles ; `-s` : silencieux.
- **[C]** `/etc/default/myos` ne contient qu'une ligne commentée
  (`#MYOS=/usr/local/lib/myos`) : aucune valeur système.
- **[C]** `Makefile` = `include make/include.mk`. Lancé par `make` dans
  `Sources/myos`, `CURDIR` = le checkout, `MYOS` se calcule à `.` (le dépôt est
  myos lui-même), `APP` = `myos` (il y a un `.git`), `RELATIVE` = `../`.

### 1.2 Ordre de chargement (`make/include.mk`) [C]

1. `make/env.mk`, `make/def.mk`, `make/def.*.mk` (`def.app.mk`, `def.docker.mk`).
2. `make/<subdir>/def*.mk` pour `MAKE_SUBDIRS` = `apps apps/myos` (APP défini,
   type `myos` car `MYOS=.`).
3. `make/*.mk` (`common.mk help.mk myos.mk utils.mk`), puis `make/apps/*.mk`
   et `make/apps/myos/*.mk`.
4. Comme `MYOS=.` : **`stack/*.mk stack/*/*.mk` de tous les stacks** (d'où la
   fuite de variables d'un stack à l'autre, et la définition des groupes).
5. `make/end.mk` (transforme les mots après certaines cibles en arguments).

### 1.3 Fichiers de `make/` et rôle [C]

| Fichier | Rôle |
|---|---|
| `include.mk` | ordre d'inclusion ci-dessus |
| `env.mk` | cible `.env` (rendu de `.env.dist`), `-include .env`, fonctions `.env`/`.env_update`, construction de `env_args` / `docker_env_args` (variables `ENV_VARS` + `.env.dist` + contenu de `ENV_FILE`) |
| `def.mk` | variables de base (APP, ENV `?= master`, USER, HOSTNAME, DOMAIN par `dnsdomainname`, UID/GID, ENV_FILE, ENV_VARS…), `DRYRUN` → `RUN=echo`, `include $(ENV_FILE)`, macros (`make`, `env-exec`, `conf`, `pop`, `JWT`, `RESU`, `force`…), cibles `%:env` / `%@env` |
| `def.docker.mk` | réseaux (`DOCKER_NETWORK_DEFAULT/PRIVATE/PUBLIC`), `HOST_*`/`USER_*` (projet hôte = hostname), `STACK ?= $(APP)`, `HOST_STACK`/`USER_STACK`, détection IP hôte (`/sbin/ip`), fonctions `docker-run/exec/rm/start/stop/logs/volume-copy` |
| `def.app.mk` | fonctions `app-*` (bootstrap, build, up, start, exec…) pour une app hors compose ou un dépôt cloné à côté |
| `common.mk` | `app-%` (dispatch `app-<nom>-<verbe>`), `apps-*`, `update-*`, `install-bin-%`, `debug-%` |
| `help.mk`, `utils.mk` | aide, macros utilitaires (`UPPERCASE`, `LOWERCASE`, `reverse`…) ; `context`, `print-%`, `debug-%` |
| `myos.mk` | `myos` → `myos-host`, `myos-%` = la cible `%` dans `$(MYOS)` |
| `apps/def.mk` | `APP_HOST/APP_URI/APP_URL`, macros de routage fabio `tagprefix`, `urlprefix`, `uri`, `servicenvs` |
| `apps/def.docker.mk` | `COMPOSE_FILE_*` (suffixes d'overlays), **`COMPOSE_PROJECT_NAME`**, `DOCKER_COMPOSE` (plugin ≥ 2.24.4 sinon `docker-compose`), `DOCKER_COMPOSE_UP_OPTIONS ?= -d`, `DOCKER_IMAGE_TAG ?= $(ENV)`, `DOCKER_REPOSITORY`, `DOCKER_SERVICES` (= `compose config --services`), fonctions `compose-file`, `docker-stack`, `docker-stack-update`, `docker-build`, `docker-compose` |
| `apps/docker.mk` | cibles `docker-compose-<verbe>`, `docker-stack-%`, `docker-build*`, `docker-network-create*`, `docker-image-myos`, `docker-rm-%`, `docker-volume-rm-%`… |
| `apps/common.mk` | **les verbes utilisateur** : `up down start stop restart recreate config logs ps exec run build rebuild clean scale bootstrap bootstrap-stack stack stack-% force-% shutdown update…` |
| `apps/ufw.mk`, `apps/def.ufw.mk` | ufw / ufw-docker (actifs si `SETUP_UFW=true`) |
| `apps/myos/*.mk` | `COMPOSE_IGNORE_ORPHANS := true`, `setup-*` (docker group via ansible, binfmt, nfsd, sysctl, ufw), ssh |
| `apps/{ansible,aws,openstack,packer,terraform,subrepo}`, `monorepo/` | outillage historique, non utilisé ici |

Côté stacks [C] : `stack/<nom>/<nom>.mk` définit les **groupes** (`duniter ?=
duniter/v2s duniter/squid`, `woodpecker ?= woodpeckerci/woodpecker-server
woodpeckerci/woodpecker-agent`, `host ?= host/consul host/fabio host/registrator`,
`default`, `logs`, `monitoring`, `testing`, `develop`), les variables de routage
(`*_SERVICE_<port>_TAGS`), ufw (`HOST_<SVC>_UFW_UPDATE`, `_UFW_DOCKER`) et des
cibles `bootstrap-stack-<nom>`. `stack/myos/` porte les overlays communs
(`networks.yml`, `volumes.{www,dns,home,log,backup}.local.yml`).

### 1.4 Variables clés et dérivations

| Variable | Défaut (code) | Valeur effective sonic, `Sources/myos` |
|---|---|---|
| `ENV` | `master` (`def.mk`) | **`local`** (`.env`), sauf `ENV=` en ligne de commande |
| `USER` | `id -nu` | `aya` |
| `HOSTNAME` | `hostname` court | `sonic` |
| `DOMAIN` | `dnsdomainname` | `asycn.io` (`.env` aussi) |
| `APP` | nom du dossier s'il a `.git` | `myos` |
| `STACK` | `$(APP)` | `.env` : `testing duniter woodpecker coroot lukegus/termix` |
| groupe `host` | `host/consul host/fabio host/registrator` (`host.mk`) | `.env` : `acme apache/php5 autoheal certbot consul fabio ftps ipfs nginx php registrator` |
| groupe `coroot` | — | `.env` : `coroot/mcp coroot/coroot` |
| `SERVICE` | vide | restreint la commande compose à ce(s) service(s) |
| `COMPOSE_FILE_{DNS,HOME,WWW}` | `false` | `true` (`.env`) → overlays `*.dns.yml`, `*.home.yml`, `*.www.yml` et `stack/myos/volumes.{dns,home,www}.$(ENV).yml` |

**Nom de projet** [C] (`apps/def.docker.mk`) :

```
COMPOSE_PROJECT_NAME ?= DOCKER_COMPOSE_PROJECT_NAME s'il existe,
                        sinon lowercase(USER-APP_NAME-ENV[-APP_PATH]) sans les points
DOCKER_COMPOSE_PROJECT_NAME ?= HOST_COMPOSE_PROJECT_NAME (= HOSTNAME) si HOST_STACK,
                               USER_COMPOSE_PROJECT_NAME si USER_STACK
HOST_STACK = "host" si le 1er segment de STACK est host ; USER_STACK idem pour "User"
```

`docker-stack-%` relance make **une fois par élément de `STACK`** avec
`APP_NAME` = 1er segment de l'élément, sans `_ - .` (`woodpeckerci/woodpecker-agent`
→ `woodpeckerci`, `lukegus/termix` → `lukegus`). Les sous-stacks d'un même
segment partagent donc le projet.

| Projet visible | Dérivation |
|---|---|
| `sonic` | `STACK=host…` → `HOST_STACK` → `HOST_COMPOSE_PROJECT_NAME` = `HOSTNAME` |
| `aya-duniter-master` | `aya` + `duniter` + `ENV=master` (ligne de commande) |
| `aya-duniter-tests` | `aya` + `duniter` + `ENV=tests` (`.env` de `myos.gtest`) |
| `aya-coroot-local`, `aya-lukegus-local`, `aya-mediawiki-local`, `aya-ipfs-local`, `aya-gitlab-local`, `aya-ceramic-local`, `aya-woodpecker-local` | `aya` + 1er segment + `ENV=local` |
| `aya-woodpeckerci-local` | idem, depuis `/home/aya/Applications/myos` (`STACK=woodpeckerci/woodpecker-agent`) |

**Réseaux** [C] (`make/def.docker.mk` + `stack/myos/networks.yml`) :

| Réseau compose | Variable | Formule | Noms sur sonic |
|---|---|---|---|
| `default` (créé par compose si un service n'a pas de `networks:`) | `DOCKER_NETWORK_DEFAULT` | `_$(COMPOSE_PROJECT_NAME)` | `_sonic` (autoheal), `_aya-mediawiki-local` |
| `private` (externe) | `DOCKER_NETWORK_PRIVATE` | `$(USER)-$(ENV)` | `aya-local`, `aya-master`, `aya-tests` |
| `public` (externe) | `DOCKER_NETWORK_PUBLIC` | `$(HOSTNAME)` | `sonic` |

Le tiret bas initial de `default` est voulu (commentaire du code : docker
attache les interfaces par ordre alphabétique, `default` doit passer en premier).
**[C]** Conséquence notable : `sonic-ftps` est sur `aya-local` — le réseau privé
du stack hôte dépend de `ENV` (lancé en `local`).

**Autres dérivations** [C] : `DOCKER_REPOSITORY` = projet avec `-`/`_` → `/`
(`sonic` → `sonic`, `aya-ipfs-local` → `aya/ipfs/local`) ; images
`${HOST_DOCKER_REPOSITORY}/fabio:${DOCKER_IMAGE_TAG}` = `sonic/fabio:local`,
`${DOCKER_REPOSITORY}/nginx:${DOCKER_IMAGE_TAG}` = `sonic/nginx:local`,
`aya/ipfs/local/ipfs:local`. `HOST_DOCKER_VOLUME` = `sonic` (volume externe
`host` monté par fabio, acme, ftps, certbot…).

**Fichiers compose d'un stack** [C] (`compose-file`) : pour chaque nom
(`docker-compose` et `<nom>`), dans le dossier du stack : `<n>.yml`,
`<n>.$(ENV).yml`, `$(ENV)/<n>.yml`, `$(ENV)/<n>.$(ENV).yml`, puis pour chaque
suffixe (`dns home www …` activés + la version, `latest` par défaut)
`<n>.<s>.yml`, `<n>.<s>.$(ENV).yml`. Puis `stack/myos/{networks,volumes}*`.
D'où `woodpecker-server.latest.yml` dans les labels, et `docker-compose.yml`
deux fois pour coroot (une fois par membre du groupe).

**Variables passées à compose** [C] : par l'environnement (`env-exec` =
`env $(env_args) docker compose …`) : `ENV_VARS` (liste cumulée par tous les
`.mk`), variables de `.env.dist`, contenu de `ENV_FILE` (`.env`). Compose est
appelé `docker --log-level=error compose --ansi=auto -f … -p <projet> <verbe>`.

### 1.5 Les cibles demandées [C sauf mention]

Toutes passent par `docker-stack-<verbe>` → pour chaque élément de `STACK` :
`make docker-compose-<verbe> STACK=<élément> APP_NAME=<1er segment>` →
prérequis `stack` (calcule `COMPOSE_FILE`) → `docker compose … <verbe>`.

| Cible | Ce qui s'exécute |
|---|---|
| `config` | `docker-stack-config` → `compose config`. Pas d'écriture tant qu'aucun dossier de stack n'a de `.env.dist` (seul `supabase` en a). **Affiche les secrets interpolés.** |
| `up` | `docker-stack-up` + `ufw-update` + `app-start`. `docker-compose-up` a pour prérequis `docker-image-myos`, `bootstrap-stack`, `stack`, puis `compose up $(DOCKER_COMPOSE_UP_OPTIONS) [SERVICE]` avec `-d` par défaut (`-d --build` seulement si `DRONE=true`). |
| `start` | `compose start [SERVICE]` |
| `restart` | `compose restart [SERVICE]` + `app-start` — **n'applique aucun changement de configuration** |
| `recreate` | `docker-compose-rm` puis `docker-compose-up` : `compose rm -fs [SERVICE]` puis `up` (avec bootstrap-stack). **Sans `SERVICE`, arrête et supprime tous les conteneurs des fichiers chargés.** |
| `stop`, `down` | `compose stop` ; `down` = `compose rm -fs SERVICE` ou `compose down`, plus `ufw-delete` |
| `host`, `host-<verbe>` | `host` → `stack-host-up` ; `host-%` → `stack-host-%` |
| `stack-<stack>-<verbe>` | si `<verbe>` est un `docker-compose-<verbe>` existant : `make <verbe> STACK="<stack>"` en transmettant `ARGS COMPOSE_IGNORE_ORPHANS DOCKER_COMPOSE_PROJECT_NAME SERVICE User host`. Ex. `make host-up SERVICE=fabio` = `make up STACK=host SERVICE=fabio`. |
| `force-<verbe>` | `<verbe>` + `stack-user-<verbe>` + `stack-host-<verbe>` (`shutdown` = `force-down` : tout tomber) |

Effets de bord de `up` :

- **`docker-image-myos`** : boucle sur `MYOS_DOCKER_IMAGES`, **qui n'est défini
  nulle part** dans ce checkout ni dans `.env` → no-op [C : grep].
- **`bootstrap-stack`** : `docker-network` (crée `$(USER)-$(ENV)` et
  `$(HOSTNAME)` s'ils manquent, `docker network create`), puis
  `bootstrap-stack-<stack>` :
  - `host` → `host-ssl-certs` : `docker run --rm alpine` avec le volume `sonic`
    monté sur `/host` ; crée `/host/htpasswd/default.htpasswd` s'il manque,
    **`apk add openssl` (réseau)**, puis pour chaque `DOMAIN` (`asycn.io`) copie
    `/host/live/<domaine>/{fullchain,privkey}.pem` vers `/host/certs/` si le
    certificat n'est pas de staging, sinon génère un auto-signé si la clé
    manque. **Exécuté à chaque `up` du stack hôte.** (`host-certbot` seulement
    si `SETUP_CERTBOT`, commenté dans `.env`.)
  - `ipfs` → `mkdir -p ~/.ipfs` + `setup-sysctl` (no-op, `SETUP_SYSCTL=false`).
  - autres stacks : pas de `bootstrap-stack-<x>` → rien.
- **Pas de `--build`** : compose ne construit une image `build:` que si elle
  est **absente** ; il ne la reconstruit pas si elle existe.
- **Pull** : compose tire les images absentes (`pull_policy` par défaut
  `missing`). **Exception : `stack/coroot/docker-compose.yml` a `pull_policy:
  always`** (3 services) → chaque `up` de coroot tire les images.
- **`ufw-update`** (existe seulement si `SETUP_UFW=true`, c'est le cas) :
  prérequis `stack` + **pour un stack hôte `setup-ufw`** = `ufw-install`
  (`git clone https://github.com/chaifeng/ufw-docker` dans
  `/home/aya/Sources/ufw-docker` si absent — présent, commit 2023), `ufw-bootstrap`,
  `ufw-build` (construit `sonic/ufw-docker:$(DOCKER_IMAGE_TAG)` si absente — c'est
  ce qui a produit `sonic/ufw-docker:local` le 2026-10-07), `ufw-up` (`docker
  run -d --restart always --network host --cap-add NET_ADMIN -v /etc/ufw…`
  seulement si `sonic-ufw-docker` ne tourne pas — il tourne, image `:latest` de
  2022), puis **`ufw-docker install`** exécuté dans le conteneur (touche
  `/etc/ufw/after.rules` de l'hôte, idempotent [D]). Ensuite, pour chaque
  service de `UFW_UPDATE` (= `SERVICE`, sinon tous les services) :
  `ufw allow <port>` pour `HOST_<SVC>_UFW_UPDATE` (fabio 80/tcp 443/tcp, consul
  8500, ipfs 4001/tcp 4001/udp 8080, certbot 53/udp) et `ufw-docker allow
  sonic-<svc> <port>` pour `HOST_<SVC>_UFW_DOCKER` (ftps 21 + 18700-18710).
  Tout passe par `docker exec sonic-ufw-docker …`. **Modifie le pare-feu de
  l'hôte à chaque `up`** (règles déjà présentes : sans effet [D]).
- **`app-start`** : pas de recette définie → tombe dans la règle `%:` → no-op.
- **`COMPOSE_IGNORE_ORPHANS := true`** (forcé, exporté) : un `up` avec un
  sous-ensemble de fichiers ne signale ni ne supprime les autres conteneurs du
  projet. C'est ce qui permet `host=host/nginx` sans toucher au reste.
- **`.env`** : `.env` est une cible phony incluse ; elle n'écrit que si une
  clé de `.env.dist` manque à `.env` (rendu trié en fin de fichier — on voit
  `DOCKER_MACHINE/DOCKER_SOCKET_LOCATION/DOCKER_SYSTEM` ajoutés ainsi). Toutes
  présentes → rien.
- **Évaluations au parsing** : `DOCKER_MACHINE`/`DOCKER_SYSTEM` lanceraient
  `docker run --rm alpine uname` s'ils n'étaient pas dans `.env` (ils y sont) ;
  `DOCKER_SERVICES` lance `compose config --services` ; `DOCKER_HOST_*` lisent
  `/sbin/ip`. Lecture seule.

**`SERVICE=`** : `$(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE))`. **Piège** :
si `SERVICE` ne correspond à aucun service du stack (faute de frappe), le
filtre est vide et la commande s'applique à **tous les services**. Plusieurs
valeurs sont acceptées (`SERVICE='nginx acme'`).

**`--force-recreate`** : `DOCKER_COMPOSE_UP_OPTIONS` est en `?=` → surchargeable
en ligne de commande, et propagé aux sous-make par `MAKEFLAGS` :
`DOCKER_COMPOSE_UP_OPTIONS='-d --force-recreate --no-deps'`. **[D]** non exécuté.

**Aperçu sans effet** : `DRYRUN=true` remplace les commandes par `echo` (et
`RECURSIVE=true` par défaut relance les sous-make en dry-run). **[D]** Restes
non neutralisés : les `$(shell docker …)` de lecture au parsing, et `touch .env`
dans `.env_update` (n'arrive que si `.env.dist` a une clé nouvelle). Non
exécuté ici.

---

## 2. Recréer chaque projet à l'identique

Toutes les commandes : **`make`, pas `myos`**, depuis le checkout indiqué, sans
`ENV=` sauf mention (le `.env` du checkout donne `ENV`). Version compose à
l'origine : 2.26.1 (sonic) sauf mention. Rien de ce tableau n'a été exécuté.

| Projet | Checkout (`cd`) | Commande | Fichiers compose constatés (labels) | Un seul service |
|---|---|---|---|---|
| `sonic` | `/home/aya/Sources/myos` | `make host` (= `make up STACK=host`, groupe `host` du `.env`) | 21 : `acme apache/php5(+.www) autoheal certbot consul fabio ftps ipfs(+.home) nginx(+.www,.dns) php(+.www,.dns) registrator` + `networks` + `volumes.{www,dns,home}.local` | voir §3 |
| `aya-duniter-master` | `/home/aya/Sources/myos` | `make up STACK=duniter ENV=master` | v2s/oracle/ui : `v2s.yml squid.yml networks.yml` ; db/server/processor : `squid.yml networks.yml` | `make up STACK=duniter ENV=master SERVICE=v2s` ; les services squid ont été recréés en dernier par **`make up STACK=duniter/squid ENV=master`** [D] |
| `aya-duniter-tests` | `/home/aya/Sources/myos.gtest` | `make up STACK=duniter` (`.env` : `ENV=tests`, `DUNITER_V2S_DUNITER_CHAIN_NAME=gtest`) | idem, chemins `myos.gtest` | `… SERVICE=v2s` ; squid : `STACK=duniter/squid` |
| `aya-coroot-local` | `/home/aya/Sources/myos` | `make up STACK=coroot` (groupe `coroot=coroot/mcp coroot/coroot`) | `docker-compose.yml mcp.yml docker-compose.yml coroot.yml` + overlays myos | `… SERVICE=coroot` — **pull systématique** (`pull_policy: always`) |
| `aya-lukegus-local` | `/home/aya/Sources/myos` | `make up STACK=lukegus/termix` | `termix.yml` + overlays | `SERVICE=termix` / `guacd` |
| `aya-mediawiki-local` | `/home/aya/Sources/myos` | `make up STACK=mediawiki` | `mediawiki.yml` + overlays | `SERVICE=mediawiki` / `database` |
| `aya-ipfs-local` | `/home/aya/Sources/myos` | `make up STACK=ipfs` | `ipfs.yml` + overlays | `SERVICE=ipfs` (image `aya/ipfs/local/ipfs:local`, construite si absente) |
| `aya-woodpecker-local` | `/home/aya/Sources/myos` | `make up STACK=woodpecker` (historique l. 408) | `woodpecker-server(.latest).yml woodpecker-agent(.latest).yml` + overlays | `SERVICE=server` / `agent` |
| `aya-gitlab-local` | `/home/aya/Sources/myos` | `make up STACK=gitlab/runner` | `runner.yml` + overlays | `SERVICE=runner` |
| `aya-ceramic-local` | `/home/aya/Sources/myos` | `make up STACK=ceramic` | `ceramic.yml` + overlays | `SERVICE=postgres` |
| (hors liste) `aya-woodpeckerci-local` | `/home/aya/Applications/myos` | `make up` (`.env` : `STACK=woodpeckerci/woodpecker-agent`) | `woodpecker-agent(.latest).yml` + overlays | **[C] conteneur en `restarting`** |

Pour forcer la recréation d'un seul service :
`make up STACK=<…> SERVICE=<svc> DOCKER_COMPOSE_UP_OPTIONS='-d --force-recreate --no-deps'`.
`make recreate STACK=<…> SERVICE=<svc>` fait `rm -fs <svc>` puis `up` (coupure
plus longue, mais même effet). **Ne jamais lancer `recreate` sans `SERVICE`.**

Observations transverses :

- **[C] Un `make up` sans `STACK`** depuis `Sources/myos` prendrait `STACK` du
  `.env` : `testing duniter woodpecker coroot lukegus/termix`, en `ENV=local` →
  lancerait le stack drone (`testing`) et **un nouveau projet
  `aya-duniter-local`** (second nœud duniter). **[D]** À ne pas faire.
- **[C] Versions compose dans les labels** : `aya-mediawiki-local` 5.0.0,
  `aya-duniter-*-ui-1`, `sonic-apache-php5-1`, `sonic-ftps`, `aya-coroot-local-prometheus-1`
  5.0.2, `sonic-certbot` 2.40.3, `aya-ceramic-local` 2.39.1 — alors que sonic a
  2.26.1 (`/usr/libexec/docker/cli-plugins/docker-compose`) et aucun plugin
  utilisateur lisible. **Non expliqué** (client distant ? plugin de root,
  illisible pour aya ?). Leurs `working_dir` pointent pourtant vers sonic.
- **[D]** Un `up` avec compose 2.26.1 sur un conteneur créé par 5.x ne le
  recrée que si le hash de configuration diffère ; non vérifié.

---

## 3. La stack hôte : nginx, fabio, consul, registrator

### 3.1 Ce qui est en place [C]

| Conteneur | Créé (UTC) | Image (id) | Réseau | Ports |
|---|---|---|---|---|
| `sonic-fabio` | 2026-10-07 22:28 | `sonic/fabio:local` (736a98bf, 2025-08-10) | **host** | écoute :80 et :443 de la machine (`-proxy.addr :80,:443;cs=certs`) |
| `sonic-consul` | 2026-10-07 22:28 | `sonic/consul:local` (a1839b73) | host | 8500 |
| `sonic-registrator` | 2026-10-07 22:28 | `sonic/registrator:local` (dfab71a2) | host | — |
| `sonic-nginx-1` | 2026-10-07 22:23 | `sonic/nginx:local` (642b0925, 2025-08-10) | `sonic` | 80 et 443 publiés **sur des ports éphémères** |
| `sonic-acme-1` | 2026-10-07 22:28 | `pinidh/acme-companion:latest` | `sonic` | — (`volumes_from: nginx`, `depends_on: nginx`) |

Images présentes aussi, **non utilisées** : `sonic/{fabio,consul,registrator}:latest`
(2026-09-26).

**[D] Rôles dans le chemin HTTP** : fabio est **l'entrée HTTP/HTTPS de toute la
machine** (réseau host, 80/443). Il route d'après les tags `urlprefix-…` que
registrator publie dans consul. nginx n'est qu'un backend derrière fabio : il
sert les vhosts de `HOST_NGINX_LETSENCRYPT_HOST` (axiom-team.fr, monnaie-libre.fr,
cesium.app, librodrome.org, …) et le joker `*:443` (`HOST_NGINX_SERVICE_443_HOST`
modifié localement, non commité).

### 3.2 Commandes

Depuis `/home/aya/Sources/myos`, avec `make` (moteur du checkout, tag `local`) :

| But | Commande | Remarque |
|---|---|---|
| Voir ce qui serait lancé | `make config STACK=host` ou `make host-config SERVICE=fabio` | lecture seule [D], affiche les secrets |
| Recréer **nginx seul**, comme le 07/10 | `make host host=host/nginx` | charge nginx(+www,dns) + overlays ; les orphelins sont ignorés |
| Même chose avec le jeu de fichiers complet | `make host SERVICE=nginx` | labels identiques aux autres services |
| Forcer même si rien n'a changé | `make host SERVICE=nginx DOCKER_COMPOSE_UP_OPTIONS='-d --force-recreate --no-deps'` | — |
| nginx + acme ensemble | `make host SERVICE='nginx acme' DOCKER_COMPOSE_UP_OPTIONS='-d --force-recreate'` | acme fait `volumes_from: nginx` |
| fabio seul | `make host SERVICE=fabio DOCKER_COMPOSE_UP_OPTIONS='-d --force-recreate --no-deps'` | sans `--no-deps`, compose v2 vérifie aussi consul (`depends_on`) et le recrée si sa config a dérivé [D] |
| consul / registrator | `SERVICE=consul` / `SERVICE=registrator` (même forme) | registrator dépend de consul |
| Le trio comme dans l'historique | `make host host='host/fabio host/consul host/registrator'` | — |

À éviter : `myos …` (moteur `lightning` : tag `latest`, change les images) ;
`ENV=…` en ligne de commande (`DOCKER_IMAGE_TAG` suit `ENV` → image absente →
**build**, et réseau privé `aya-<env>` différent) ; `make host` depuis
`myos.gtest` (son `.env` porte aussi `host=…` mais `ENV=tests` : tag `tests`,
builds, réseau `aya-tests`) ; `recreate` sans `SERVICE` ; `SERVICE` mal
orthographié (bascule sur tous les services) ; `make shutdown` / `force-*`.

### 3.3 Ce qui est rebuild [C code, D effet]

- `nginx`, `fabio`, `consul`, `registrator` ont une section `build:` (contexte
  `../..` = racine du checkout, `docker/<svc>/Dockerfile`). Sans `--build` et
  avec `sonic/<svc>:local` présentes, **compose ne reconstruit pas** [D]. Le
  07/10 n'a rien reconstruit (images d'août 2025 toujours en place).
- Un rebuild n'arrive que si l'image `:local` manque, si on passe `--build`
  (`docker-compose-build`, `rebuild`, `DOCKER_COMPOSE_UP_OPTIONS='-d --build'`)
  ou si `ENV` change. Il dépendrait alors du réseau : fabio `FROM alpine:latest`
  + `wget` du binaire 1.6.3 sur GitHub ; nginx `FROM pinidh/nginx-proxy:alpine`
  (tag flottant) + `sed` sur ses templates ; consul `FROM consul:1.11.1` (**[D]
  l'image officielle `consul` du Docker Hub est dépréciée au profit de
  `hashicorp/consul` ; un rebuild pourrait échouer — non vérifié**) ;
  registrator compilé en Go depuis les sources.
- `acme` (`pinidh/acme-companion:latest`), `autoheal`, `php`, `ftps` : images
  amont, tirées seulement si absentes.

### 3.4 Risques [D sauf mention]

- **fabio recréé = coupure de toute l'entrée HTTP/HTTPS de la machine**, le
  temps de l'arrêt/démarrage (quelques secondes si l'image est là) : tous les
  sites, CI, duniter (wss), etc.
- **nginx recréé** : les vhosts servis par nginx (dont le joker `*:443`) tombent
  jusqu'à ce que registrator réenregistre le nouveau conteneur (nouvelle IP sur
  `sonic`, nouveaux ports éphémères, `-resync=30`). fabio reste en place.
- **consul recréé** : registre indisponible ; données dans le volume
  `sonic_consul`. Si fabio garde sa dernière table de routage pendant la
  coupure, ce n'est **pas vérifié**.
- **acme** : son `volumes_from: nginx` pointe sur l'ancien conteneur après une
  recréation de nginx seul. L'historique montre `docker restart sonic-acme-1`
  après chaque opération nginx ; le comportement exact n'est **pas vérifié**.
  Le plus sûr : recréer nginx et acme ensemble.
- **Effets de bord de tout `up` hôte** (§1.5) : `host-ssl-certs` (conteneur
  alpine, `apk add` réseau, écrit dans le volume `sonic` : `htpasswd/`, `certs/`),
  `ufw-docker install` et `ufw allow …` sur le pare-feu de l'hôte, `git clone`
  d'ufw-docker si absent, build de `sonic/ufw-docker:local` si absente.
  `SERVICE=` réduit les règles ufw au service visé, pas `setup-ufw`.
- **Pull** : seulement les images absentes ; aucune ne manque aujourd'hui pour
  ces services [C : images présentes].
- **Fichiers locaux non commités** pris en compte : `stack/host/{fabio.yml,
  nginx.mk, acme.mk, ftps.yml, apache/php5.yml, ipfs.yml}`, `docker/nginx/
  nginx_default_location_php` (règle de réécriture cesium.app). Un `git
  checkout`/`pull` du dépôt les perdrait.
- **[C] Fichier d'échange vim `stack/host/.fabio.mk.swp`** dans `Sources/myos` :
  une édition de `fabio.mk` est ouverte ou a planté.

### 3.5 Les autres services du projet `sonic` [C]

| Conteneur | Origine constatée | Reproductible par myos ? |
|---|---|---|
| `sonic-php-1`, `sonic-autoheal`, `sonic-apache-php5-1`, `sonic-ftps` | 21 fichiers, `Sources/myos` | oui, `make host SERVICE=<svc>` |
| `sonic-certbot` (2025-12-20) | 22 fichiers : le groupe incluait alors `mail/mailserver` (commenté depuis) | oui, `SERVICE=certbot` (sans mailserver) |
| `sonic-ipfs` (2026-03-23) | `ipfs.yml ipfs.home.yml` + overlays | `make host host=host/ipfs` |
| `sonic-memcached-1` (2023-03-09) | `/home/zen/.zen/myos/stack/host/memcached.yml` | **non** : ce fichier n'existe plus et n'a jamais été suivi par git (ni chez zen ni dans `Sources/myos`) |
| `sonic-ufw-docker` | `docker run` par `ufw-up`, image `sonic/ufw-docker:latest` (2022), sans label compose | relancé par `setup-ufw` seulement s'il ne tourne pas |
| `sonic-beszel-agent` | `/home/aya/Sources/sonic/bestzer.yml` (hors myos, dossier sans git) | [D] `docker compose -p sonic -f /home/aya/Sources/sonic/bestzer.yml up -d` |

---

## 4. Les autres checkouts [C]

| Checkout | Branche / commit | Remote | État | `.env` (clés structurantes) | Ce qui en tourne |
|---|---|---|---|---|---|
| `/home/aya/Sources/myos` | `tmp` @ `429270f` (2026-02-20) | `git.open.us.org/ACL/myos`, `git.p2p.legal/qo-op/myos` | 17 fichiers modifiés, 15 non suivis (stacks `aurora ceramic coroot gitlab lukegus mediawiki`, `docker/{aurora,dehydrated}`, `.env.gtest`, `.env.naturalis`, `feeds.ini`) | `ENV=local`, `STACK=testing duniter woodpecker coroot lukegus/termix`, `host=…`, `coroot=…`, `SETUP_UFW=true`, `HOST_LB=true` | `sonic` (sauf memcached, beszel), tous les `aya-*-local`, `aya-duniter-master` |
| `/home/aya/Sources/myos.gtest` | `tmp` @ `429270f` (même commit) | idem | 12 modifiés ; n'a pas `stack/{gitlab,lukegus}`, ni `coroot/mcp.yml` ; a `stack/duniter/v2s.yml.gtest`, `woodpecker-dind.yml` | `ENV=tests`, `STACK=duniter`, `DUNITER_V2S_DUNITER_CHAIN_NAME=gtest`, `APP_HOST_MULTI_ENV=false`, **`host=…` aussi** | `aya-duniter-tests` |
| `/home/aya/Applications/myos` | `tmp` @ `429270f` | idem | 11 modifiés ; non suivis dont un dump d'image OCI (`blobs/`, `index.json`, `oci-layout`, `test.tar`, `-` ≈ 53 Mo chacun), fichiers `.swp` dans `stack/duniter`, `stack/mediawiki` | `ENV=local`, `STACK=woodpeckerci/woodpecker-agent` | `aya-woodpeckerci-local` (agent en `restarting`) |
| `/home/zen/.zen/myos` | `develop` @ `65d739e` (2024-12-15, « wip: stalled changes ») | `ssh://…open.us.org/ACL/myos` | propre | `ENV=local`, `STACK=host`, `DOMAIN=asycn.io olympe.network copylaradio.com`, `SETUP_CERTBOT=true`, `host=host/acme … host/mail/mailserver … host/volumes.*` | `sonic-memcached-1` (fichier disparu) |
| `/usr/local/lib/myos` | `lightning` @ `0e09506` (2026-07-28) | `github.com/aya/myos`, `git.open.us.org/aya/myos` | propre | aucun | images `sonic/*:latest` du 26/09 (aucun conteneur) |

Différences de moteur notables (`make/`) [C] :
- `myos.gtest`, `Applications/myos` : `make/` identique à `Sources/myos`.
- `zen` : `make/` antérieur (10 fichiers diffèrent) ; `stack/host` diffère sur
  presque tous les fichiers (acme, consul, fabio, nginx, registrator…).
- `lightning` (`/usr/local/lib/myos`) : `APP_DIR = WORKDIR`, `STACK_DIR`
  cherché dans `WORKDIR/stack`, `.`, `..`, `~/.local/share`, `/usr/local/share`,
  `/usr/share` (`+/myos`), `ENV_PATH=WORKDIR`, **`ENV ?= local`**,
  **`DOCKER_IMAGE_TAG ?= latest`**, `ENV_VARS` déduit des `${VAR}` des fichiers
  compose (fonction `env-vars`), alias `status` = `ps`, `reload` = `recreate`,
  `docker-stack-%` délègue à `app-$(APP)-%` quand `APP` est dans `STACK`.
- Duniter, `Sources/myos` vs `myos.gtest` : chaîne `g1` vs `gtest`, images
  `duniter-g1-1100` vs `duniter-gtest-1000`, squid `-g1` (sans tag → `latest`)
  vs `-gtest:0.5.11`, port p2p 30333 publié fixe en g1 / éphémère en gtest,
  `DUNITER_PUBLIC_SQUID` seulement en g1.

**Secrets en clair constatés (valeurs non reproduites ici)** : jeton
d'accès dans l'URL du remote `open` de `/usr/local/lib/myos/.git/config` ;
mots de passe et jetons dans les `.env` des checkouts (dont une URL Apprise
avec identifiants et un mot de passe en commentaire) ; jeton beszel dans
`/home/aya/Sources/sonic/bestzer.yml`. Relève de la règle 7 de l'infra et
peut-être d'une fiche d'incident.

---

## 5. Ce que la réécriture shell (ce dépôt, branche `tdd`) doit reproduire pour sonic

Lu : `README.md`, `AGENTS.md`, `adr.md`, `RESTART.md`, `spec/golden/DELTAS.md`,
`share/settings/engine.settings`, extraits de `lib/`. La réécriture couvre
déjà la plupart des verbes ; la liste vise **la bascule de sonic sans
recréation involontaire**.

### 5.1 Parité indispensable (sinon recréation ou renommage)

1. **Format de projet `user-app-env`** (`aya-duniter-master`) — déjà prévu
   (`MYOS_PROJECT_FORMAT=user-app-env`, `migrate pin`) ; à épingler dans les
   `.env` de `Sources/myos`, `myos.gtest`, `Applications/myos`.
2. **`DOCKER_IMAGE_TAG` = `ENV` pour les images construites** : sonic tourne
   sur `sonic/*:local` et `aya/ipfs/local/ipfs:local`. La réécriture répond
   `latest` par défaut (`lib/values.sh`) — et `sonic/{fabio,consul,registrator}:latest`
   **existent** (images du 26/09, différentes) : un `up host` basculerait
   silencieusement dessus, comme `lightning` l'a fait. Épingler
   `DOCKER_IMAGE_TAG=local` (et `tests` pour gtest) ou reproduire la règle.
3. **Les groupes définis dans `$WORKDIR/.env`** (`host=…`, `coroot=…`) :
   `myos_groups` lit `*.env` et `*.mk` des dossiers de stacks ; **vérifier**
   qu'il lit aussi le `.env` du projet (non prouvé à la lecture).
4. **`APP_NAME` = 1er segment de la référence** : `duniter/squid` et
   `duniter/v2s` dans le même projet ; `lukegus/termix` → `aya-lukegus-local` ;
   `gitlab/runner` → `aya-gitlab-local` ; `woodpecker` (groupe) →
   `aya-woodpecker-local` alors que le dossier est `woodpeckerci`.
5. **Un `up` partiel n'enlève ni ne signale le reste du projet** :
   `COMPOSE_IGNORE_ORPHANS=true` exporté. Introuvable dans `lib/` et `share/`
   (grep) : à reproduire, sinon `up host/nginx` avertit (sans supprimer) et un
   `--remove-orphans` éventuel détruirait fabio.
6. **Résolution des fichiers** : `<n>.yml`, `<n>.$ENV.yml`, `$ENV/<n>.yml`,
   suffixes activés par `COMPOSE_FILE_<SUFFIX>=true` (dns, home, www),
   `<n>.<version>.yml` (`latest` par défaut : `woodpecker-server.latest.yml`),
   `docker-compose.yml` du dossier pour chaque membre, puis `stack/myos/
   networks.yml` + `volumes.<suffix>.$ENV.yml`. Les deltas golden notent déjà le
   tri des suffixes et la dédup ; **compose fusionne dans l'ordre des `-f`**, un
   ordre différent change le hash et peut recréer : à comparer avec
   `docker compose config --hash '*'` avant bascule.
7. **Réseaux** : `_<projet>`, `<user>-<env>` (externe), `<hostname>`
   (externe) — repris dans `lib/stack.sh`. Pour le stack hôte, le réseau privé
   **dépend d'`ENV`** (`sonic-ftps` est sur `aya-local`).
8. **Projet hôte = hostname de la cible** (`sonic`), `HOST_DOCKER_REPOSITORY`,
   `HOST_DOCKER_VOLUME=sonic`, `container_name: ${HOST_COMPOSE_PROJECT_NAME}-<svc>` —
   repris (ADR 0001, `--target` nomme d'après la cible).
9. **Valeurs passées à compose** : toutes les variables référencées, plus les
   valeurs calculées (`HOST_NGINX_*`, `HOST_FABIO_PROXY_ADDR`, tags
   `urlprefix-` via `tagprefix/urlprefix/servicenvs/uri`), `DOCKER_HOST_INET4`,
   `DOCKER_HOST_IFACE`, `DOCKER_INTERNAL_DOCKER_HOST` (interfaces de la
   **cible**, pas du poste — à vérifier avec `--target`), `HOST_UID/GID=123`.
   Les tags fabio doivent sortir **à l'octet près**, sinon env différent →
   recréation.
10. **`.env` existant respecté** : ne rien réécrire d'un `.env` qui contient
    des clés de `.env.dist` (rendu en fin de fichier, trié).

### 5.2 Comportements à garder (ou à remplacer explicitement)

- `SERVICE=` (un ou plusieurs) sur `up/start/stop/restart/logs/rm` —
  la réécriture le passe tel quel : **mieux** que make, qui retombe sur tous
  les services si le nom est inconnu ; à garder ainsi.
- `recreate` : make = `rm -fs` + `up` ; la réécriture = `up -d
  --force-recreate` (delta noté). Ajouter **`--no-deps`** possible (fabio →
  consul), absent des deux.
- `DOCKER_COMPOSE_UP_OPTIONS` surchargeable (`--build`, `--force-recreate`).
- Pas de `--build` implicite : construire seulement si l'image manque.
- `pull_policy` des fichiers respecté (coroot `always`).
- `bootstrap-stack-host` (htpasswd par défaut, copie `live/` → `certs/`,
  auto-signé) : la réécriture le confie à `cert` (`--self-signed` au
  bootstrap) — vérifier que `cert` ne réécrit pas `/host/certs` des domaines
  servis par acme, et que fabio trouve `cs=certs;type=path;cert=/host/certs`.
- `bootstrap-stack-ipfs` (`~/.ipfs`), création des réseaux externes.
- ufw : `HOST_<SVC>_UFW_UPDATE` / `_UFW_DOCKER` → la réécriture en dérive
  `firewall apply` (delta noté) ; garder l'exemption `ufw-docker allow
  sonic-ftps 21/tcp…` (ports ftps passifs) et `53/udp` certbot.
- Verbes : `config ps logs exec run connect attach scale start stop restart
  down clean shutdown` ; `host`/`host-<verbe>` comme raccourci du groupe hôte.
- `DRYRUN=true` ↔ `myos -n` (plus sûr : pas d'écriture `.env`).
- Les cibles `%:env` / `%@env` (verbe pour un autre `ENV`) — non utilisées sur
  sonic d'après l'historique [C].

### 5.3 À ne pas reproduire (constaté nuisible)

- `make up` sans `STACK` qui lance tout le `STACK` du `.env` (dont `testing`).
- Repli sur tous les services quand `SERVICE` est inconnu.
- `recreate` sans service = `rm -fs` de tout le stack hôte.
- `apk add` réseau et écriture du volume `sonic` à chaque `up` hôte.
- Deux moteurs sous deux noms (`make` vs `myos`) avec des défauts différents.

### 5.4 Avant la bascule de sonic (suggestion) [D]

Pour chaque projet de §2 : sortir `docker compose … config --hash '*'` par
l'ancien moteur (`make config` sans exécution) et par le nouveau (`myos -n`,
`print-COMPOSE_PROJECT_NAME`), comparer projet, liste et ordre des fichiers,
hash par service, images (tag) et réseaux. Toute différence de hash =
recréation au premier `up`.

---

## 6. Exécuté le 2026-10-18, pendant la réparation de sonic [C]

Les commandes du §2 ont servi à recréer les conteneurs qui avaient perdu
leurs réseaux (incident `infra/incidents/2026-10-18-sonic-reseaux-perdus-au-reboot.md`
du workspace aya), toutes sous la forme :

```sh
cd <checkout> && make up STACK=<…> [ENV=master] SERVICE='<…>' \
  DOCKER_COMPOSE_UP_OPTIONS='-d --force-recreate --no-deps --pull never'
```

précédées d'un `DRYRUN=true` dont on a vérifié que la commande compose finale
visait le bon projet, les mêmes fichiers que les labels, et **les seuls
services nommés** (le piège du `SERVICE` inconnu). Résultats :

- les dix projets ont donné les noms de projet et les jeux de fichiers
  attendus ; `--pull never` a gardé les images en place (coroot compris) ;
- `make up STACK=duniter/squid ENV=master SERVICE='db server processor'` a
  échoué sur `dependency failed to start: container …-processor-1 is
  unhealthy` : le processor rattrapait son retard ; `server` est resté
  `created`, relancé ensuite par la même commande avec `SERVICE=server` ;
- `make up STACK=host SERVICE='ipfs apache-php5 ftps'` a recréé les trois
  conteneurs, puis échoué dans `setup-ufw` : `ERROR: UFW is disabled […]`.
  ufw était effectivement inactif sur l'hôte (nftables vide le ruleset au
  boot, voir l'incident) ;
- recréé sur `aya-local`, `sonic-ftps` y a pris l'adresse `172.20.0.14`,
  l'IP fixe de `aya-woodpeckerci-local-agent-1` (Applications/myos), qui ne
  démarre plus (`Address already in use`). Leçon pour la réécriture : une IP
  fixe dans un réseau partagé n'est réservée que tant que son conteneur tourne.
