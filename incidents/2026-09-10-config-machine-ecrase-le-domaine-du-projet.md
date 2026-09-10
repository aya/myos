# 2026-09-10 : la config machine écrasait le domaine du projet, silencieusement

**Impact** : évité. `myos --target sonic up crm` aurait déployé sur
**`crm.holcommon.net`** au lieu de `crm.hco.st` : route consul fausse,
`SERVER_URL` faux (donc les liens de twenty), nom de certificat faux. Le
déploiement aurait « réussi » sans un mot.

**Déclencheur** : dernière vérification avant de donner la commande de
déploiement. Toutes mes vérifications précédentes passaient par
`sh lib/main.sh` en direct, ce qui **contourne le wrapper**. Avec le vrai
binaire :

```
$ /Users/aya/dev/myos/myos --target sonic print-APP_HOST crm ENV=master
APP_HOST crm.holcommon.net      # attendu : crm.hco.st
```

`/etc/default/myos` sur le poste contient `DOMAIN=holcommon.net` — laissé par
l'installation myos v1 encore présente (`/usr/local/bin/myos` est toujours
l'ancien moteur make ; les deux versions coexistent, comme prévu).

## Cause racine

Le wrapper `myos` lit la configuration système et l'**exporte dans
l'environnement**. Or la couche environnement est au-dessus de
`$WORKDIR/.env` dans `myos_var`. Le défaut de la machine battait donc la
valeur du projet.

C'est une inversion de couches, pas un bug d'implémentation : la config
machine est un **repli** (« sur cet hôte, à défaut, le domaine est X »), alors
qu'un projet qui déclare son domaine est plus spécifique que l'hôte depuis
lequel on le pilote. En déploiement distant l'absurdité est nette : le
`DOMAIN` du **poste de travail** décidait du domaine servi sur le serveur.

Le wrapper doit malgré tout exporter ces valeurs : leur raison d'être est de
pointer le CLI docker (`DOCKER_HOST`, `DOCKER_SOCKET_LOCATION`), et un
processus fils ne lit que l'environnement.

## Pourquoi le filet a manqué

- **Le harnais de test met `MYOS_CONF=/dev/null`.** Aucun test n'exerçait la
  configuration système. C'est la même famille de cécité que
  [`migrate pin`](2026-09-10-migrate-pin-sans-effet.md) : une valeur que le
  harnais fixe est un chemin de lecture que rien ne teste.
- **Mes propres vérifications contournaient le wrapper.** J'ai validé une
  dizaine de valeurs dérivées avec `sh lib/main.sh`, qui ne lit pas
  `/etc/default/myos`. Vérifier avec autre chose que le binaire que l'opérateur
  tape ne vérifie pas ce qu'il obtiendra.

## Correctif

Le wrapper marque chaque valeur venue de la configuration système dans
`MYOS_CONF_<nom>` en plus de l'exporter. `myos_var` s'en sert pour la
distinguer d'une variable posée par l'opérateur et la classe **sous** le
`.env` du projet, avec l'origine `conf`. Précédence désormais :

```
ligne de commande > environnement > .env.<ENV> > .env > secrets > config machine > stack > moteur
```

Tests (`spec/verbs/sysconf_spec.sh`) : la config répond pour un nom que
personne d'autre ne fournit, perd contre `.env`, perd contre la ligne de
commande, et **atteint toujours l'appel docker** auquel elle est destinée.

Rouge vérifié avant (`expected "DOMAIN from-the-system" to include
"from-the-project"`), vert après. Suite : 291 exemples, 0 échec, portabilité ok.

Détail de méthode, à retenir : le premier jet du test posait `DOMAIN=` (vide)
pour neutraliser le harnais. Le wrapper lit « posé mais vide » comme fourni, et
le test échouait pour la mauvaise raison. Il faut **retirer** le nom de
l'environnement hermétique, pas le contredire — c'est la troisième fois dans la
journée que les valeurs figées du harnais font échouer ou passer un test pour
un motif étranger à ce qu'il vérifie.

## Playbook

- Vérifier une valeur dérivée **avec le binaire que l'opérateur tape**, jamais
  avec `sh lib/main.sh`.
- `myos env <stack> | grep <NOM>` et, en cas de doute sur la provenance,
  se rappeler l'ordre ci-dessus. `/etc/default/myos` et `/etc/conf.d/myos` sont
  les deux fichiers à lire avant d'accuser le projet.
- Sur ce poste, `myos` sur le PATH est **l'ancien moteur v1** : le nouveau est
  `/Users/aya/dev/myos/myos`.
