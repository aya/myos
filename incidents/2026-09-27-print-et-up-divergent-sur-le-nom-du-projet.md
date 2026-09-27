# 2026-09-27 : `print` et `up` ne sont pas d'accord sur le nom du projet

**Impact** : aucun déploiement touché. Quasi-accident, trouvé en préparant la
première stack du workspace `~/dev/aya/infra` (redroid sur aynic), avant tout
`up` réel.

**Déclencheur** : deux façons de nommer un projet sont entendues par
`print-*` et ignorées par `up`.

1. `ENV=main` posé en littéral dans `infra/.env.dist` (puis dans `.env`) :
   `myos --target aynic print-ENV redroid` répond `ENV main`, mais
   `print-COMPOSE_PROJECT_NAME` répond `aya-local-redroid`, et `-n up` lance
   `-p aya-local-redroid`. Seul `ENV=main` sur la ligne de commande donne
   `aya-main-redroid`.
2. `COMPOSE_PROJECT_NAME=aya-local-redroid2` sur la ligne de commande :
   `print-COMPOSE_PROJECT_NAME` répond `aya-local-redroid2`, `-n up` lance
   `-p aya-local-redroid`. Le levier qui marche est
   `DOCKER_COMPOSE_PROJECT_NAME=` (`print` et `up` sont alors d'accord).

## Cause racine

1. `lib/main.sh:86` : `MYOS_ENV=${ENV:-local}` lit l'environnement du
   processus, pas les couches de valeurs (`.env`, littéraux de `.env.dist`,
   coffre). `print-ENV`, lui, passe par `myos_var`. Même classe que
   [`migrate pin` sans effet](2026-09-10-migrate-pin-sans-effet.md).
2. `myos_project_name` (`lib/stack.sh:29`) ne consulte que
   `DOCKER_COMPOSE_PROJECT_NAME`. `COMPOSE_PROJECT_NAME` n'est qu'un repli du
   moteur (`lib/values.sh:88`) que toute couche plus haute masque pour
   `print`, sans effet sur `up`.

## Pourquoi c'est dangereux

Le nom du projet nomme les volumes. Avec `ENV=main` passé à la main, un seul
appel sans l'argument vise `aya-local-redroid` : un `up` crée un second
conteneur sur un volume vide, un `backup` n'archive aucun volume et répond ok.
Et la vérification que prescrit l'atelier avant un premier déploiement
(`print-COMPOSE_PROJECT_NAME`) est précisément l'instrument qui ment dans le
cas 2.

## Pourquoi le filet a manqué

Les specs posent `ENV` dans l'environnement du harnais : le chemin « ENV lu
d'un fichier » n'est jamais parcouru. Aucune spec ne compare la valeur que
`print-COMPOSE_PROJECT_NAME` affiche au `-p` que `up` passe à compose.

## Contournement (dans aya/infra, pas dans le moteur)

Pas d'`ENV` dans `.env.dist` : les projets gardent le défaut `local`, identique
à chaque appel. Une seconde instance se nomme par
`DOCKER_COMPOSE_PROJECT_NAME=`.

## État

**Ouvert.** Tests attendus : pour toute couche qui fixe `ENV`,
`print-COMPOSE_PROJECT_NAME` égale le `-p` de `-n up` ; et une valeur que `up`
ignore ne doit pas être affichée comme si elle comptait (ou `up` doit la lire).
