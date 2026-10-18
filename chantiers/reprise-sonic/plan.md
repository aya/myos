# Le plan de la reprise de sonic par la réécriture

Préparé le 2026-10-18 au soir. **Aucun `up` n'a été lancé** : tout ce qui suit
est mesuré sur le rendu de myos, comparé aux conteneurs qui tournent.

## La décision (aya)

- **Un dépôt par user**, local sur le poste : `~/dev/<user>/infra`, sur le
  modèle de `~/dev/hco/infra`. Chaque dépôt contient `stack/<app>/` (compose
  vendoré, surcharge, `.settings`), un `.env.dist` (`MYOS_USER`) et un
  `migration.md`.
- **La stack host** de sonic va dans `~/dev/aya/infra`, avec le reste d'aya.
- **Les projets déployés par une CI** migrent aussi : la CI construit l'image
  comme aujourd'hui, puis lance `myos --target sonic up <app>`.

## Ce qui est prêt

| Dépôt | Projets | Services | Empreinte égale (avec les secrets des conteneurs) | Détail |
|---|---|---|---|---|
| `~/dev/aya/infra` (c61374a) | sonic (host), aya-duniter-master/tests, coroot, lukegus, mediawiki, ipfs, woodpecker, woodpeckerci, gitlab, ceramic, myos-master | 40 | 39/40 avec compose 2.26.1 (écart : acme) ; avec la 5.1.2 du poste, 18 seraient recréés | `machines/sonic-migration.md` |
| `~/dev/cdb/infra` (0bb1d24) | cdb-communo-api-main, cdb-communo-front-main | 16 | 16/16 (secrets injectés sur sonic) | `migration.md` |
| `~/dev/websites/infra` (634767b) | api-axiom-team-fr main/develop, axiom-team-fr main/develop, carte-g1, gratewizard | 12 | 12/12 | `migration.md` |
| `~/dev/lpk/infra` (bb25d10) | lpk-decision-main, lpk-librodrome-main | — | voir ci-dessous | `migration.md` |
| `~/dev/ehv/infra` (1368244) | ehv-sejeteralo-main | — | | |
| `~/dev/ajr/infra` (c54758e) | ajr-dependency-track-main, ajr-mafabriqueadeco-main | — | | |
| `~/dev/syoul/infra` (5891d60) | syoul-g1flux-dev/main, syoul-prestashop-test-main | — | | |
| `~/dev/poka/infra` | poka-padp2p-master, cesium2s | 3 | 3/3 | `migration.md` |
| `~/dev/axiom-team/infra` | axiom-team-hasura-master | 1 | 1/1 | `migration.md` |
| `~/dev/hco/infra`, `bankSync`, `budgetPilot` (existants) | hco-main-* | | non mesuré : le poste ne peut pas déchiffrer le coffre de hco | |

Pour lpk, ehv, ajr et syoul (15 services) : 6 sont égaux sans secret ; 7 ne
diffèrent que par leurs secrets (égaux avec une même valeur factice des deux
côtés, pas mesuré avec les vraies valeurs, refusé par le classifieur) ; 2
n'ont jamais eu de conteneur (dtrack apiserver, PrestaShop de
mafabriqueadeco). Tous les dépôts redonnent le nom exact de chaque projet
(`print-COMPOSE_PROJECT_NAME`). Ce sont des commits locaux, sans remote.

## Ce que la mesure a appris (vaut pour toute la reprise)

1. **La version de compose fait l'empreinte.** compose 5.x ne compte plus
   `depends_on` dans l'empreinte, et ne sérialise plus de la même façon les
   binds courts (`create_host_path`). Tout service créé par compose 2.x avec
   l'un ou l'autre serait recréé par un `up` en 5.x, quel que soit le dépôt.
   C'est le cas de fabio, consul, registrator et nginx. **La bascule se fait
   avec la version de compose qui a créé le conteneur**
   (`DOCKER_COMPOSE=<binaire 2.26.1>` pour l'ancien moteur, 5.x pour ce que
   la CI a créé en 5.5.1).
2. **`config --hash` ignore les clés des `env_file`**, alors que `up` en tient
   compte. Pour les services qui en utilisent (communo php, worker, node), le
   critère n'a été valable qu'après avoir remplacé les `env_file` par des clés
   nommées dans la surcharge.
3. **Les politiques de redémarrage passées à `always` le 2026-10-18**, par
   `docker update` et dans les stacks (infra adr/0013), ne figurent pas dans
   l'empreinte des conteneurs, calculée à leur création. Une surcharge
   « bascule » remet l'ancienne valeur pour le premier `up`. La recréation
   qui passera à `always` se fait ensuite, dans une fenêtre choisie.
4. **Les secrets** : aucun coffre n'existe pour ces users. Leurs valeurs sont
   aujourd'hui dans les conteneurs et dans les `.env` des dossiers de
   lancement sur sonic. Il faut les reprendre tels quels, jamais les
   régénérer, dans `~/dev/<user>/config` chiffré par sops pour la clé age du
   poste et celle de sonic. Ensuite, refaire la mesure avec le coffre.

## Les défauts du moteur trouvés en préparant

Écrits dans `incidents/2026-10-18-defauts-trouves-en-preparant-la-reprise-de-sonic.md`,
avec les récidives des incidents du 2026-09-26. Les dépôts les contournent
(`DOCKER_COMPOSE_PROJECT_NAME`, `_stack.settings`, surcharges) ; une fois
le moteur corrigé, ces contournements devront être retirés.

## Ce qui reste à trancher avant la première bascule

- **Images** :
  - `g1flux:latest` désigne l'image de dev : un `up g1flux ENV=main`
    recréerait la production sur cette image ;
  - `sejeteralo-backend:latest` n'existe plus sur sonic ;
  - un `docker pull` de `latest` avant la bascule (nocodb, postgres) ferait
    recréer.
- **Services jamais lancés**, créés au premier `up` : dtrack apiserver,
  PrestaShop de mafabriqueadeco, `graphql-engine` de hasura. Lancer avec
  `SERVICE=`, ou les retirer.
- **CI** : `--target sonic` passe par ssh, donc la CI a besoin d'une clé ssh
  pour un compte du groupe docker de sonic. L'alternative est d'utiliser le
  socket que l'agent woodpecker monte déjà.
- **Sécurité, indépendante de la reprise** :
  - le postgres de hasura est en `trust` et publie `0.0.0.0:16405`
    (joignable par mycelium) ;
  - le fork privé `gitlab.com/aya/communo-api` suit des `.env` de production :
    rotation, puis retrait du dépôt ;
  - deux URL de remote sur sonic portent un jeton en clair :
    `~aya/Applications/librodrome`, et `upstream` des checkouts myos.

## L'ordre proposé

1. Le coffre de chaque user, puis la mesure refaite avec lui : `config --hash`
   égal partout, avec la version de compose qui a créé chaque conteneur.
2. Corriger les défauts du moteur qui imposent des contournements (noms à
   tirets, réseau par défaut, `COMPOSE_FILE_*`, `-n` qui écrit), en TDD, et
   retirer les contournements des dépôts.
3. Basculer, du sans-état vers ce qui porte des données, et develop avant
   main :
   - sauvegarde (`myos backup`) ;
   - `myos -n up`, et lecture de ce qu'il ferait ;
   - `myos up` avec `DOCKER_COMPOSE` à la bonne version ;
   - `docker inspect` : même `Id` qu'avant, aucun conteneur recréé.
4. La stack host en dernier, dans une fenêtre annoncée : elle porte l'entrée
   HTTP de toute la machine.
5. Retirer les anciens checkouts du moteur Makefile de sonic, une fois que
   plus aucun conteneur n'en dépend (inventaire `infra/machines/sonic.md`
   régénéré).
