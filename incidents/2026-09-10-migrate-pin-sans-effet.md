# 2026-09-10 : `migrate pin` n'avait aucun effet, et rapportait un succès

**Impact** : aucun encore — aucune machine n'a été migrée. Le potentiel est le
plus grave trouvé à ce jour : `migrate pin` est **l'outil qui empêche le
renommage de tous les projets d'une flotte** lors du passage à myos v2. Il
écrivait son fichier, disait `pin ok`, et ne changeait rien. Sur `sonic` (91
conteneurs, ~20 projets clients au format historique) la bascule aurait
renommé chaque projet, donc recréé chaque conteneur et **détaché chaque volume
nommé** de son service.

**Déclencheur** : en préparant le déploiement de `crm` sur `sonic`, les
projets existants s'y lisent `cdb-communo-api-main`, `aya-duniter-master` —
format historique `user-app-env`. Vérification du levier censé le préserver :

```sh
echo 'MYOS_PROJECT_FORMAT=user-app-env' > .env
myos print-COMPOSE_PROJECT_NAME app ENV=master
# → aya-master-app     (nouveau format : le pin est ignoré)
```

## Cause racine

`myos_project_name` (`lib/stack.sh`) lisait `${MYOS_PROJECT_FORMAT:-user-env-app}`,
c'est-à-dire **la variable du shell**. Or `migrate pin` écrit la clé dans
`$WORKDIR/.env`, et une valeur de `.env` est chargée par `myos_values_load` dans
`MYOS_ENVFILE_<nom>` — jamais dans l'environnement. Les deux moitiés du
mécanisme ne se parlaient pas.

Les trois autres noms de la même fonction avaient le même défaut :
`DOCKER_COMPOSE_PROJECT_NAME`, `HOST_COMPOSE_PROJECT_NAME`,
`USER_COMPOSE_PROJECT_NAME` ne pouvaient pas être posés depuis `.env`.

## Pourquoi le filet a manqué — deux raisons, la seconde est la leçon

1. `spec/verbs/migrate_spec.sh` vérifiait que **le fichier était écrit**
   (`The contents of file "$sb/wd/.env" should equal ...`), jamais que le format
   épinglé **nommait le projet**. Tester l'artefact au lieu du comportement :
   le test était vert, la fonction morte.

2. **Les deux harnais de test forcent `MYOS_PROJECT_FORMAT=user-app-env` dans
   l'environnement** — `myos_run_engine` (`spec/support/run.sh:88`, donc toute
   la suite golden et `try.sh`) et `myos_run_live` (ligne 105, donc tous les
   specs de verbes). Le format était donc épinglé par le seul chemin qui
   fonctionnait pour *chaque test de la suite*. Le chemin `.env` — celui que
   `migrate pin` écrit, le seul qui compte en production — n'était exercé par
   rien.

   Constaté en direct : un premier test ajouté dans `migrate_spec.sh` est passé
   **du premier coup**, ce qui a fait croire un instant que le bug n'existait
   pas. C'est le harnais qui le masquait.

## Correctif

`lib/stack.sh` : les quatre noms passent par `myos_var`, donc par les couches
(ligne de commande, environnement, `.env`, défauts). La précédence est
inchangée.

Tests, dans un `Describe` séparé de `spec/verbs/migrate_spec.sh` qui invoque le
wrapper **sans le pin d'environnement** :

- `.env` épinglé → `tester-wd-local` (format historique)
- rien d'épinglé → `tester-local-wd` (nouveau défaut)
- ligne de commande contre `.env` → la ligne de commande gagne

Rouge vérifié avant le correctif (`expected "tester-local-wd" to include
"tester-wd-local"`), vert après. Suite complète : 287 exemples, 0 échec.

## Ce que ça dit de plus général

Un harnais qui pose une valeur « pour que les goldens comparent la résolution
et non le nommage » a rendu un mécanisme entier intestable. **Toute valeur que
le harnais fixe est une valeur dont le chemin de lecture n'est pas testé.** Il
y en a d'autres dans `myos_hermetic_env` : `DOMAIN`, `USER`, `HOSTNAME`,
`DOCKER_MACHINE`, `DOCKER_SYSTEM`. Le défaut
[`.env.dist` écrasé](2026-09-10-env-dist-ecrase-par-le-defaut-du-moteur.md)
était de la même famille, et son test a dû contourner `DOMAIN=example.test`
pour la même raison.

À faire : passer en revue `myos_hermetic_env` et, pour chaque valeur qu'il
fixe, se demander quel chemin de lecture cela dispense de tester.

## Playbook

- Avant de migrer une machine : `myos print-COMPOSE_PROJECT_NAME <stack>` sur
  la machine, et **comparer au nom réel** dans `docker ps`. Ne pas se fier au
  `pin ok`.
- Symptôme d'une bascule ratée : `docker ps` montre des conteneurs neufs aux
  noms réordonnés, et les anciens volumes existent toujours mais ne sont plus
  montés (`docker volume ls` en montre deux jeux).
