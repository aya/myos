# 2026-09-26 : un `up` à blanc écrit le `.env`, et y génère des secrets

**Impact** : aucun déploiement touché. Un quasi-accident est ouvert sur le
poste d'Yvv (voir plus bas). `-n` promet de ne rien faire. Pourtant, sur un
répertoire de travail sans `.env`, il **rend** le `.env` : les lignes
`$(openssl rand …)` des `.env.dist` sont exécutées, et le fichier est écrit en
600.

**Déclencheur** : en préparant la stack `erpnext`, `myos -n up twenty` a été
lancé dans `infra/` sur le poste d'Yvv, pour lire les noms dérivés (règle 5 de
l'atelier). Sortie : `env-update ok (5 keys added)`. Avant, `infra/.env`
n'existait pas. Après, il contenait `DOMAIN`, `MYOS_CONFIG_REPOSITORY`,
`TWENTY_APP_SECRET`, `TWENTY_ENCRYPTION_KEY` et `TWENTY_PG_PASSWORD`.

Reproduit sur une copie jetable (`git archive HEAD` d'infra, sans `.env`) :
même sortie, même fichier, mêmes cinq clés.

## Cause racine

Non établie dans le code, lu seulement en partie. Ce qui est constaté :
- `up` lance le bootstrap quand aucun `.env` n'existe
  (`myos_up_needs_bootstrap`, `lib/verb/lifecycle.sh`) ;
- le bootstrap appelle `myos_verb_env_update` sans condition ;
- le rendu écrit le fichier même quand `MYOS_DRYRUN=true`.

## Pourquoi c'est pire qu'un effet de bord

Dans `myos_var` (`lib/values.sh`), `.env` passe **avant** le coffre
(`MYOS_ENVFILE_` avant `MYOS_SECRET_`). Des secrets générés par erreur dans le
`.env` d'un poste masquent donc ceux du coffre, et ce pour tout déploiement
lancé ensuite depuis ce poste. Pour twenty :
- `TWENTY_PG_PASSWORD` ne correspond plus à la base ;
- `TWENTY_APP_SECRET` invalide les sessions ;
- `TWENTY_ENCRYPTION_KEY` rend illisibles les secrets du workspace.

Rien ne le signale : la valeur est bien formée, elle n'est simplement pas la
bonne.

## Pourquoi le filet a manqué

La règle 5 de l'atelier prescrit justement un `-n` avant tout premier
déploiement. Elle suppose que `-n` est sans effet, et aucun test ne vérifie
qu'un verbe à blanc laisse le répertoire de travail inchangé. Les specs posent
un `.env` dans leur harnais : le chemin « premier `up`, pas de `.env` » n'y est
jamais parcouru à blanc.

## État

- **Ouvert.** Pas de correctif : le moteur n'a pas été modifié.
- Test attendu : un `-n up` sur un répertoire sans `.env` laisse le répertoire
  identique, octet pour octet.
- Poste d'Yvv : `infra/.env` porte trois `TWENTY_*` qui ne viennent pas du
  coffre. À retirer (décision d'Yvv, c'est un fichier runtime) avant tout
  `myos --target sonic … twenty` lancé depuis ce poste.

## Récidive 2026-09-26, 20:16 — poste d'aya, déplacement de twenty

`myos -n --target sonic up twenty ENV=main`, lancé dans `infra/` pour lire le
plan avant de déplacer le CRM sur `crm.holcommon.com`. Sortie :
`env-update ok (2 keys added)`. `infra/.env` a été écrit (20:16:45) avec
`DOMAIN` et `MYOS_CONFIG_REPOSITORY` seulement : le coffre étant déchiffrable
ce jour-là (`sops` et la clé de sonic présents), `env-update` n'a écrit aucune
des clés qu'il fournit. Sans effet cette fois. Non vérifié : sous
`MYOS_SECRETS=none`, le même `-n` générerait vraisemblablement les trois
`TWENTY_*`, comme sur le poste d'Yvv. Toujours ouvert.

## Récidive 2026-09-27, 19:48 — poste d'aya, workspace aya/infra

Deux verbes à blanc, lancés dans `~/dev/aya/infra` pour préparer redroid sur
aynic :

- `myos --target aynic -n up redroid`, `.env.dist` ne portant que des
  littéraux (`MYOS_USER=aya`, `ENV=main`) : `env-update ok (1 keys added)`,
  `.env` écrit en 600 avec `ENV=main`. Donc même un `.env.dist` sans aucune
  valeur calculée fait écrire le fichier. Le même `-n up` avant l'ajout
  d'`ENV` (seul `MYOS_USER`) n'avait rien écrit.
- `myos --target aynic -n backup redroid` : crée
  `backup/aya-local-redroid/<date>/manifest.json`. `myos_backup_default`
  (`lib/verb/backup.sh:16-17`) fait son `mkdir -p` et écrit le manifeste
  sans regarder `MYOS_DRYRUN` ; seul `myos_volumes` (ligne 11) le respecte.

Sans effet : les deux résidus ont été supprimés. Le test attendu s'étend :
**tout** verbe à blanc laisse le répertoire de travail identique, pas seulement
`up`.

## Récidive 2026-09-30, vers 00:20 — poste d'Yvv, bankSync (chantier flux-de-gestion)

La session bs-h (lot SB1, préparation de la stack bankSync) a lancé
`myos -n up` pour lire les noms dérivés. Le `.env` a été **créé dans le clone
principal de bankSync** (`HCO/bankSync/.env`, et non dans le worktree de
travail), avec `DOMAIN` seul. La session l'a retiré aussitôt ; aucun secret
généré, aucun effet.

Ce que la récidive ajoute : appelé depuis un worktree, le verbe à blanc écrit
**hors du répertoire où la session travaille**, dans un dépôt que d'autres
sessions partagent. Le défaut reste **ouvert** ; le test attendu (tout verbe à
blanc laisse le répertoire de travail identique) doit aussi couvrir le clone
voisin d'un worktree.

Pourquoi le filet a manqué, cette fois : l'incident était connu, mais rien
n'empêche encore l'appel ; la parade reste la discipline, et la session ne
l'avait pas lu. Rappel posé dans `bankSync/chantiers/flux-de-gestion/SB1.md`
(section Pièges).

## Récidive 2026-10-18, au soir — poste d'aya, préparation de la reprise de sonic

Trois sessions qui préparaient chacune un dépôt d'user (`~/dev/websites/infra`,
`~/dev/cdb/infra`, `~/dev/lpk/infra`) ont constaté qu'un `myos -n up` écrivait
le `.env` du dépôt. C'étaient des dépôts neufs, sans coffre, avec
`MYOS_SECRETS=none` : le cas que la récidive du 26/09 jugeait vraisemblable.
Le `.env` est ignoré par git et n'a pas été commité ; les sessions ne l'ont
pas relu pour vérifier s'il contenait des secrets générés. Toujours ouvert.
(chantiers/reprise-sonic/plan.md)

## Playbook

- Symptôme : `env-update ok (N keys added)` dans la sortie d'un `-n`.
- Comparer `cut -d= -f1 .env` avant et après. Toute clé générée qui a un
  équivalent au coffre doit être retirée du `.env`, sinon elle masque le
  coffre.
