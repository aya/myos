# 2026-10-18 : les défauts du moteur trouvés en préparant la reprise de sonic

**Impact** : aucun en production, puisqu'aucun `up` n'a été lancé. En
préparant un dépôt par user pour reprendre les ~100 conteneurs de sonic sans
les recréer (`chantiers/reprise-sonic/plan.md`), cinq sessions ont comparé le
rendu de myos (`config -- --hash '*'`) aux empreintes des conteneurs. Chaque
écart du moteur aurait, à la bascule, renommé ou recréé des conteneurs de
production. Tous sont contournés dans les dépôts, et chaque contournement est
à retirer quand le moteur sera corrigé.

**Déclencheur** : les premiers vrais projets qui n'ont pas été écrits pour
myos (compose d'applis, CI, `/opt/*`), et ceux de l'ancien moteur.

## Les défauts

Constatés par les sessions de préparation. Les causes données sont celles
qu'elles ont lues dans le code ; aucune n'est encore couverte par un test.

1. **Les tirets du nom d'une stack disparaissent du nom de projet.**
   `carte-g1` donne `websites-carteg1-master`, `communo-api` donne
   `cdb-communoapi-main`. Le dossier du coffre perd aussi ses tirets
   (`<env>/apiaxiomteamfr/`). Contourné par `DOCKER_COMPOSE_PROJECT_NAME`
   dans chaque `.settings` (cdb, websites, lpk, ajr, syoul).
2. **Le réseau par défaut s'appelle `_<projet>`**, et non `<projet>_default`
   comme le fait compose. Tout projet compose classique qui s'en sert serait
   recréé. Contourné par `DOCKER_NETWORK_DEFAULT` (lpk, websites, poka).
3. **`DOCKER_NETWORK_PRIVATE` n'est lu que dans l'environnement ou sur la
   ligne de commande**, comme `COMPOSE_FILE_<X>` (incident du 2026-09-26).
   Sans lui sur la commande, myos créerait un réseau vide `cdb-main` sur
   sonic.
4. **Les valeurs d'une stack fuient vers les références suivantes d'un même
   appel.** Sans un `@if` sur la stack, prestashop-test et g1flux étaient
   fondus en un seul projet (syoul).
5. **`MYOS_COMPOSE_BIN` est ignoré**, alors que `DOCKER_COMPOSE` est suivi
   (lpk). C'est pourtant ce que la bascule doit fixer (voir 9).
6. **`include:` n'est pas suivi** pour les variables : myos ne passe pas à
   compose celles des fichiers inclus, ni la forme nue `NOM:` (websites).
   Une valeur du coffre n'arrive alors pas au conteneur (prouvé).
7. **Les `export` d'un `.settings` se perdent ; `@tagprefix` ne rend pas les
   routes de fabio à l'octet près comme l'ancien moteur** (stack host). Les
   routes sont épinglées en littéral.
8. **Le bootstrap construit tout `docker/*/Dockerfile`, et `up` n'accepte
   pas `--no-deps`** (stack host). Les contextes de build de la stack host
   sont rangés dans `build/` pour éviter le premier.
9. **Hors du moteur, mais à sa charge** : compose 5.x ne calcule pas
   l'empreinte comme compose 2.x (`depends_on`, binds courts). Le même
   rendu recrée donc ce que 2.26.1 laisserait. Et `config --hash` ignore les
   `env_file`. myos devrait savoir avec quelle version de compose reprendre
   un projet (le label `com.docker.compose.version` la donne), et le dire
   dans `-n up`.

Les récidives de deux incidents ouverts sont dans leurs fichiers : `-n up`
écrit le `.env` (2026-09-26), et `COMPOSE_FILE_<X>` n'est lu que dans
l'environnement (2026-09-26).

## Pourquoi le filet a manqué

- **Ce que la suite dorée vérifie**, ce sont les noms que l'ancien moteur
  donnait à ses propres fixtures : des noms sans tiret, et un réseau qu'il
  nommait lui-même. Aucune fixture n'est un projet compose écrit pour un
  autre outil : ni nom à tiret, ni `<projet>_default`, ni `include:`, ni
  `env_file`.
- **Les specs des verbes passent par un mock de docker** : elles ne voient ni
  les empreintes de compose, ni ce que change une version de compose.
- **Aucun test ne compare le rendu à un déploiement existant.** Le seul
  critère qui compte pour reprendre une machine, « le premier `up` ne
  recrée rien », n'existait pas : `config -- --hash` est arrivé le
  2026-10-18 (181748b).

## Correctif

Aucun dans le moteur pour l'instant. Chaque défaut : un exemple qui le
reproduit (une fixture réelle tirée d'un dépôt d'user), vu rouge, puis le
correctif, puis le retrait du contournement dans les dépôts concernés. Le 9
mérite un ADR : faut-il épingler la version de compose par projet ?

## Leçon

Un moteur qui reprend des déploiements existants se teste contre eux : le
critère est l'empreinte que compose a laissée sur chaque conteneur, pas la
sortie qu'on attendait de soi-même.
