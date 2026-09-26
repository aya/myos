# 2026-09-26 : un `COMPOSE_FILE_<X>` posé dans un `.settings` est accepté, puis ignoré

**Impact** : aucun déploiement touché. Trouvé en construisant
`infra/stack/erpnext`, qui vendore deux surcharges amont de frappe_docker
(`docker-compose.mariadb.yml`, `docker-compose.redis.yml`).

**Déclencheur** : `erpnext.settings` déclarait `COMPOSE_FILE_MARIADB ?= true`
et `COMPOSE_FILE_REDIS ?= true`. `myos -n up erpnext` ne chargeait **que**
`docker-compose.yml` et `erpnext.yml`, sans erreur ni avertissement. Sans ces
deux surcharges, la stack monte sans base de données, et `myos` la déclare
saine : ses services n'ont pas de healthcheck, et « running sans
healthcheck » vaut sain.

## Cause racine

`myos_suffixes` (`lib/files.sh:9-23`) cherche les interrupteurs uniquement
dans `env` (l'environnement du processus). Les valeurs d'une stack
(`.settings`, `.env`, coffre) ne sont pas consultées. La ligne du
`.settings` est lue, elle a une valeur (`myos print-COMPOSE_FILE_MARIADB`
répond `true`), mais elle ne sert à rien.

## Pourquoi le filet a manqué

`skills/myos/references/conventions.md` écrit « `COMPOSE_FILE_<X>=true` »
sans dire d'où cette valeur doit venir. Aucune spec ne pose un interrupteur
ailleurs que dans l'environnement du harnais.

## Contournement (dans infra, pas dans le moteur)

- `infra/stack/erpnext/actions/pre-up` refuse un `up` qui n'a pas les deux
  interrupteurs dans l'environnement, et donne la commande exacte :
  `COMPOSE_FILE_MARIADB=true COMPOSE_FILE_REDIS=true myos up erpnext`.
- Ce garde est testé (`tests/test-pre-up.sh`, vu rouge en le neutralisant).

## État

**Ouvert.** Deux corrections sont possibles, à trancher côté moteur :
- `myos_suffixes` lit aussi les valeurs de la stack ;
- ou un interrupteur trouvé dans un `.settings` fait échouer `myos`.
Il faut veiller à la circularité : les `.settings` ne sont pas des fichiers
compose, donc l'ordre de lecture ne devrait pas en créer, mais c'est à
vérifier dans `lib/stack.sh`. Le contournement d'infra disparaîtra avec la
correction.
