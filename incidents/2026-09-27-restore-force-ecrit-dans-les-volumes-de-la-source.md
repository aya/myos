# 2026-09-27 : `restore --force` écrit dans les volumes du projet d'origine

**Impact** : aucun. Le défaut a été trouvé à la lecture, puis prouvé par un
test contre le docker simulé, avant toute restauration réelle. C'est un
quasi-accident.

**Déclencheur** : la mise en ligne de l'ERPNext de HCO
(`infra/actes/2026-09-26-deploiement-erpnext-hco-sur-sonic.md`) demande une
restauration **sur copie** : la sauvegarde d'un projet, rechargée dans un autre
projet, pour vérifier qu'elle est complète sans toucher à l'original. Dans
myos, c'est `myos restore <stack> ENV=<autre> --from <dir> --force`.

## Ce qui se passait

`restore` lit les noms de volumes dans le `manifest.json` de la sauvegarde.
Ce sont ceux du projet d'origine (`hco-local-erpnext_db-data`…). Il écrivait
dans ces volumes tels quels, puis relançait **son** projet :

```
docker … -p tester-app-local down
docker volume create other-app-local_data
docker run --rm -v other-app-local_data:/v … tar xzf /b/other-app-local_data.tar.gz -C /v
docker … -p tester-app-local up -d
```

Une restauration sur copie aurait donc :
- réécrit les volumes de l'**original**, pendant qu'il tourne (une base
  mariadb dont on remplace les fichiers sous elle) ;
- démarré la copie sur des volumes **vides**, qui aurait paru saine.

## Cause racine

`myos_restore_default` (`lib/verb/restore.sh`) ne connaissait pas le projet
d'origine : seul `myos_verb_restore` le lisait, pour refuser sans `--force`.
Une fois `--force` passé, plus rien ne faisait le lien entre les noms du
manifeste et le projet courant.

## Pourquoi le filet a manqué

La spec de `restore` vérifiait le refus sans `--force`, mais aucun exemple ne
passait `--force`. Le chemin qui l'utilise n'avait jamais été parcouru, et
l'aide de la commande (« --force to restore it anyway ») n'en disait pas
davantage.

## Correctif

`myos_verb_restore` exporte `MYOS_RESTORE_PROJECT`. Un volume
`<source>_<nom>` est restauré dans `<projet>_<nom>`. Un volume du manifeste
qui ne porte pas le préfixe de la source est refusé quand les deux projets
diffèrent. Nouvel exemple dans `spec/verbs/restore_spec.sh`, **vu rouge avant
le correctif** (le journal montrait `volume create other-app-local_data`), puis
vert. Il est rouge de nouveau quand on retire le correctif.

## État

- **Corrigé** dans la spec contre le docker simulé.
- **Pas encore prouvé sur un vrai docker** : la répétition de restauration de
  l'ERPNext de HCO sur une copie en sera la preuve (`infra`, chantier
  `erpnext-hco`).

## Constaté en passant, non corrigé

- **Le `myos` installé sur le poste d'Yvv** (`~/.local/lib/myos`, clone de ce
  dépôt) était en retard de 6 commits et n'a pas le correctif. Son plan à
  blanc, sur la vraie recette ERPNext, montrait `-v hco-local-erpnext_db-data:/v`
  pour une restauration sur `ENV=restau`. Le test d'infra
  (`stack/erpnext/tests/test-backup.sh`) refuse maintenant de restaurer
  quand le plan vise un volume de la source. Mettre à jour le binaire
  installé revient à Yvv : d'autres sessions déploient avec lui. **Mis à jour
  le 28/09** sur l'accord d'Yvv (`8912033`) : son plan à blanc vise
  maintenant `hco-restau-erpnext_db-data`.
- **Un `--from` relatif** part tel quel dans le montage
  (`-v backup/dry:/b:ro` dans le plan à blanc) : docker le lirait comme un
  nom de volume, pas comme un chemin. Vu à blanc seulement, pas reproduit
  sur un vrai docker. Ouvert.
