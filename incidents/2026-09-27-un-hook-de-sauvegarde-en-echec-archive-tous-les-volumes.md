# 2026-09-27 : un hook de sauvegarde en échec archive tous les volumes, sur la cible, sous un chemin du poste

**Impact** : openc, production personnelle. Un archivage non voulu de 128 Go a
tourné quelques minutes, puis aya a arrêté le conteneur. Des archives
partielles de `advertise` et de `config` ont été écrites en root sur openc,
sous `/Users/aya/dev/aya/infra/backup/…`. `config` contient l'autorité de
certification et le jeton admin du démon c411d. Le démon lui-même n'a rien
subi : les volumes étaient montés en lecture seule.

**Déclencheur** : `myos --target openc backup c411d`, depuis le poste, pour
éprouver la stack `c411d` de `~/dev/aya/infra`. Son hook `actions/backup` doit
remplacer la sauvegarde par défaut : il demande au démon une archive de son
état (9 Mo) au lieu de tarer ses 128 Go de téléchargements.

## Trois défauts enchaînés

1. **`$MYOS_COMPOSE` n'était pas exécutable avec une cible.** Il valait
   `DOCKER_HOST=ssh://openc docker … -p <projet>`. Une affectation qui sort
   d'une variable est un mot, pas une affectation : le hook est mort sur
   `DOCKER_HOST=ssh://openc: No such file or directory`. `myos_hook_env`
   exportait pourtant déjà `DOCKER_HOST` pour le hook.
2. **Un hook de remplacement en échec lançait le défaut.**
   `myos_verb_with_hooks` faisait `if ! myos_hook_replace …; then <défaut>`.
   Or `myos_hook_replace` renvoyait 1 quand il n'y a pas de hook, et le code du
   hook quand celui-ci échoue : les deux cas se confondaient. Le défaut a donc
   archivé chaque volume.
3. **Le défaut monte un chemin du poste sur la cible.**
   `docker run -v "$MYOS_BACKUP_DIR:/b" alpine tar …` : avec `--target`,
   `MYOS_BACKUP_DIR` est un chemin du poste, que le démon distant crée chez lui,
   en root. Les archives n'arrivent jamais sur le poste.

## Pourquoi le filet a manqué

- Les specs de hooks font `echo`, jamais `$MYOS_COMPOSE`. Et la spec « a hook
  and the target » vérifie `DOCKER_HOST`, pas la commande que les hooks
  lancent réellement. Les hooks réels (`twenty/actions/pre-backup` dans
  hco/infra, redroid ici) n'avaient jamais tourné avec une cible.
- Aucune spec ne faisait échouer un hook de remplacement. Seuls « pas de
  hook » et « hook qui réussit » étaient couverts, et ce sont précisément les
  deux cas où la confusion ne se voit pas.
- La spec de `backup` tourne sans cible : le chemin de `-v` est toujours local.
- Côté opérateur : j'ai lancé un verbe réel sur une machine de production pour
  éprouver un hook jamais exécuté, en me fiant à son remplacement du défaut. Un
  `-n` n'aurait rien montré (il affiche `hook backup`), mais un hook éprouvé
  d'abord sur une stack jetable, si.

## Correctifs

- 1 et 2 sont corrigés dans `lib/hooks.sh`. `MYOS_COMPOSE` perd le préfixe de
  cible. `myos_hook_replace` dit par `MYOS_HOOK_REPLACED` si le défaut doit
  encore tourner, c'est-à-dire seulement quand il n'y a pas de hook ou que le
  hook renvoie 75. Un hook en échec fait échouer le verbe et lance
  `on-fail-<verb>`. Specs : `up_hooks_spec.sh` (« can run $MYOS_COMPOSE as a
  command on a target ») et `backup_spec.sh` (« backup replaced by a hook »).
  Les deux ont été vues rouges avec le correctif neutralisé.
- **3 reste ouvert.** Tant qu'il l'est, `myos backup` avec `--target` et sans
  hook qui remplace le défaut n'écrit pas là où il le dit. Correction attendue :
  archiver sur la cible puis rapatrier (`docker cp` depuis le conteneur
  jetable), ou refuser le verbe avec une cible.

## Trouvé ensuite, en écrivant le hook de reprise de c411d

4. **Un nom exporté par un `.settings` n'atteignait pas les hooks.**
   `myos_env_vars` (`lib/values.sh`) ne retenait que les noms que les fichiers
   compose référencent. `MYOS_SET_EXPORT`, que le compilateur de settings
   produit, ne servait qu'à `cert`. Or `conventions.md` promet l'inverse :
   « the names the settings `export` » atteignent compose, et un hook reçoit
   « every exported value ». Le `pre-upgrade` de c411d aurait lu un projet
   hérité vide et serait sorti sans rien reprendre. Corrigé : les noms exportés
   rejoignent la liste. Spec : `up_hooks_spec.sh` (« gives the hook a name the
   settings export… »), vue rouge avec le correctif neutralisé. Aucune
   expectation golden n'a bougé.

## État

1, 2 et 4 corrigés, et prouvés. 3 ouvert. Nettoyage d'openc (`/Users` créé par
docker) : à faire par aya, en root.
