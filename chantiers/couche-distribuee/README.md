# Chantier myos v2 — la couche distribuée

**But du chantier** : faire de myos la fondation d'un service d'hébergement
distribué, sans lui faire perdre ce qui le rend utilisable seul.

Ce document est le contrat du chantier. Un agent qui le lit doit pouvoir
reprendre le travail sans relire l'historique de conversation qui l'a produit.

## Pourquoi ce chantier existe

Le refacto v2 de myos (branche `tdd`, dépôt `../myos`, hors de ce dépôt) a
remplacé le moteur make par du sh POSIX et a supprimé au passage `deploy*`,
`ssh*`, `release*`, `setup-*`. C'était juste : l'ancien `deploy.mk` faisait un
`docker-login/tag/push`, un `ansible-pull` vers une cible **inexistante**, un
webhook Slack et portait des restes d'AWS CodeDeploy.

Mais en le supprimant, le refacto a laissé myos sans le « pourquoi » que son
propre plan énonce : *« la fondation d'un service d'hébergement distribué où
des agents déploient et maintiennent des stacks uniformes »*. Le résultat était
un excellent lanceur de stacks mono-hôte qui ne disait plus à quoi il servait.

**Le diagnostic : le refacto s'est arrêté une couche trop tôt.** Rien n'était à
défaire. myos sépare déjà `résoudre` (`path.sh`, `ref.sh`, `files.sh`,
`values.sh`, `settings.awk`) de `appliquer` (`lib/verb/compose.sh`, qui n'est
qu'un constructeur de ligne de commande). Toute la valeur est dans la
résolution, et elle est agnostique du backend.

## Ce qui est livré

Branche `tdd` de ce dépôt, huit commits, **295 exemples / 0 failure**, lint
propre, portabilité vérifiée sous busybox ash (alpine) et dash (debian).

Éprouvé pour de vrai : `infra/stack/twenty` tourne sur `sonic` et répond sur
**https://crm.hco.st** avec son certificat, sans configuration manuelle. C'est
ce passage à l'usage réel qui a révélé cinq défauts que la suite verte ne
voyait pas — lire `../../incidents.md` avant de toucher aux couches de valeurs.

| Commit | Ce qu'il ajoute |
|---|---|
| `70b4b84` | `--target` (`lib/target.sh`) et le backend swarm (`lib/verb/swarm.sh`) |
| `26b1ec8` | le gate de politique (`lib/verb/policy.sh`) |
| `9421d7b` | les secrets sops (`lib/secrets.sh`), le verbe `apply` (`lib/verb/apply.sh`), le second rendu de route (`@traefikrule`) |
| `83b9c64` | le compose amont vendoré : l'audit voit la surcharge, `.env.dist` bat le défaut du moteur |
| `fca7e98` | une cible nomme la machine : les valeurs d'hôte suivent la cible |
| `22c495a` | `migrate pin` fonctionne : le format écrit dans `.env` nomme le projet |
| `571a43f` | la config machine est le repli de la machine, sous le `.env` du projet |
| `ecf9c5f` | une cible est un host ssh par son nom ; compose est détecté en le demandant |

Décisions correspondantes : [0001 cible](../../adr/0001-une-cible-nomme-la-machine.md),
[0002 gate](../../adr/0002-le-gate-de-politique.md),
[0003 secrets](../../adr/0003-secrets-sops-age.md),
[0004 route](../../adr/0004-la-route-comme-format-pivot.md),
[0005 compose amont](../../adr/0005-compose-amont-vendore.md), et dans l'atelier
[un seul chemin d'exécution](../../../adr/0001-un-seul-chemin-d-execution.md).

## Ce qui reste

Par ordre de dépendance. Chaque entrée est prenable indépendamment sauf mention.

### 1. Le catalogue converti au backend swarm — *le plus gros, non commencé*

`../../../myos-stacks` branche `v2`, ~30 stacks. Ce que `docker stack deploy` impose :

- les **labels passent sous `deploy:`** — cela touche chaque stack routée
  (`SERVICE_<port>_TAGS`, et les labels traefik si le routeur change) ;
- `build:` est ignoré : toute stack qui construit son image doit la pousser et
  l'épingler **par digest** avant le déploiement ;
- `depends_on` n'existe pas, `restart:` devient `deploy.restart_policy` ;
- un volume nommé est **local au nœud** : toute stack avec état a besoin d'une
  contrainte de placement, sinon elle redémarre ailleurs sur un volume vide ;
- `deploy.resources.limits` et `healthcheck` deviennent obligatoires (le gate
  les demande dès que `MYOS_POLICY_REQUIRE` les promeut).

Trois stacks sont des cas difficiles et **ne doivent pas servir d'échauffement** :
`host/nginx` et `drone/drone-runner-docker` montent le socket docker,
`host/registrator` observe les conteneurs — ce qui ne fonctionne pas en swarm
par conception (Swarm raisonne en *services*).

### 2. Un swarm mono-nœud d'essai — *bloqué sur rien*

Pas de nouveau serveur pour l'instant. Un `docker swarm init` **sur le poste**
valide le backend de bout en bout. Ne pas le faire sur `sonic` : `swarm init`
sur un hôte qui porte des stacks vivantes crée `ingress` et `docker_gwbridge`
(collisions de sous-réseaux possibles) et ouvre 2377/tcp, 7946/tcp+udp,
4789/udp — que `myos firewall` ne connaît pas encore, donc l'audit dirait que
tout va bien.

### 3. Un `start_period` manquant, vu par le gate — *petit*

`policy` avertit d'un service sans `healthcheck`. Le cas symétrique lui échappe :
un healthcheck **sans `start_period`** sur un service qui migre au démarrage.
Sur une machine qui porte un autoheal, ça donne une boucle infinie — c'est
arrivé (`../../../infra/incidents/2026-09-10-twenty-boucle-autoheal-premier-demarrage.md`).

### 4. Les ports swarm dans `firewall` — *petit, isolé*

`myos firewall` ignore 2377, 7946 et 4789. Sur un nœud swarm, l'audit est donc
faux par omission. À traiter avec le point 2.

### 5. Le gate et la fusion compose — *connu, non corrigé*

`policy` a la même cécité que `firewall` avait : il lit les fichiers bruts, donc
une surcharge qui retirerait un montage par `volumes: !override` ne serait pas
vue. Le correctif de `firewall` (honorer `!override`/`!reset` dans l'awk) est le
modèle à suivre. Voir
[l'incident](../../incidents/2026-09-10-audit-firewall-aveugle-a-la-surcharge.md).

### 6. `status --strict` pour le backend swarm — *petit*

Aujourd'hui exit 2 avec un message explicite. Les compteurs de réplicas de
`docker stack services` ne sont pas les paires state/health que lit l'audit ;
il faut lire `docker service ps` et décider ce que « sain » veut dire.

### 7. Le réconciliateur T1 — *dépend de 1 et 2*

`myos apply` existe et fait le travail. Le réconciliateur n'est qu'une boucle
autour, plus : la clé age du cluster, la vérification de signature activée, et
le renvoi des events NDJSON quelque part de consultable.

### 8. Sauvegarde hors site et **répétition de restauration** — *urgent, indépendant*

`MYOS_BACKUP_ENCRYPT` (age) n'est pas fait, l'expédition hors site non plus.
`sonic` porte 460 Go de volumes locaux
([incident](../../../infra/incidents/2026-09-10-sonic-disque-a-98-pourcent.md)). Sans
restauration répétée, le PRA est une fiction — c'est écrit dans le plan et ça
reste vrai.

## Comment travailler ici

### TDD red/green, sans exception

Le test d'abord, on le regarde **échouer**, puis on écrit le code. Un test qui
n'a jamais été rouge ne prouve rien — il peut passer pour une raison sans
rapport. Quand un correctif est écrit, on le neutralise pour vérifier que le
test redevient rouge, puis on le remet. C'est ce qui a été fait pour les deux
défauts de `83b9c64`, et c'est ce qui a montré que les tests avaient des dents.

Exemple, `tools/check-index.sh` de ce dépôt : `tools/tests/test-check-index.sh`
a été écrit d'abord et a rendu 0/7, puis 7/7.

### Les trois mécanismes de test de myos

- **golden** (`spec/golden/`) — le contrat. `cases.txt` liste les commandes,
  `expected/` leurs sorties. **Ne jamais éditer une attente à la main** :
  changer le code, `make golden-record CASES="nom ..."`, **lire le diff**, et
  écrire dans `spec/golden/DELTAS.md` pourquoi le comportement a bougé. Un delta
  sans ligne dans DELTAS est une régression.
- **verbes** (`spec/verbs/`) — pour ce qui n'a pas d'historique enregistré, ou
  ce qui demande deux temps dans un même bac à sable (rendre puis lire). Docker
  et sops y sont simulés par `spec/support/bin/`.
- **unit** (`spec/unit/`) — le compilateur `.settings`.

`make test` fait les trois, `make lint` passe shellcheck, `make test-portability`
rejoue la suite golden sous le `/bin/sh` d'alpine et de debian, en docker.

**À savoir** : trois warnings shellspec préexistent (`settings_spec` ×2,
`backup_spec` ×1) et font sortir la suite en 101. Ce ne sont pas vos
changements ; vérifiez-le par `git stash` avant de vous en inquiéter.

### Les contraintes du shell

sh POSIX seulement (dash, busybox ash, bash 3.2) : pas de `local`, pas de
tableaux, pas de `[[`. Une fonction retourne par la globale `R`, jamais par
`$( )`. **Chaque temporaire porte un préfixe propre à sa fonction** (`_p_` dans
`myos_path`, `_tg_` dans `myos_target_env`…) parce que les appels imbriqués
partagent le même espace de noms. Les listes de mots s'itèrent avec `set -f` :
un mot peut être `*.example.org`. Le reste est dans `../../AGENTS.md`, y
compris les pièges déjà payés.

### Les collisions de noms, vécues

Ajouter le verbe `apply` a cassé `firewall apply` : les verbes étaient testés
avant les sous-verbes. Avant d'ajouter un verbe, vérifier `MYOS_SUBS`. Et avant
de nommer une variable de moteur, vérifier qu'elle n'est pas déjà prise par le
harnais de test — `MYOS_ENGINE` l'était (il nomme `just`), d'où `MYOS_BACKEND`.

### Ce qu'on écrit ailleurs

- une décision sur le moteur → `../../adr.md` ; sur la plateforme →
  `../../../infra/adr.md` ; ce qui lie tout → `../../../adr.md`
- un défaut trouvé, même avant la production → `../../incidents.md`
- un comportement qui bouge → `../../spec/golden/DELTAS.md`
