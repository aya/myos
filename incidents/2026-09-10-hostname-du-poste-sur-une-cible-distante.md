# 2026-09-10 : un déploiement distant allait créer un réseau nommé d'après le portable

**Impact** : évité de justesse. Détecté à la dernière vérification avant le
premier `up` réel sur `sonic`, une machine qui porte 91 conteneurs de
production client. Le déploiement aurait « réussi » : conteneurs démarrés,
aucune erreur — et le service aurait été **injoignable**, parce qu'attaché à un
réseau que fabio ne connaît pas.

**Déclencheur** : `myos --target sonic print-DOCKER_NETWORK_PUBLIC crm`
répondait `axiomstudio`, le nom du poste de travail, au lieu de `sonic`.

## Cause racine

`--target` (ADR 0003) ne changeait que l'endpoint docker. Tout ce que le modèle
dérive de l'hôte restait calculé sur la machine qui exécute la commande :

```
MYOS_HOSTNAME=${HOSTNAME:-$(hostname ...)}
DOCKER_NETWORK_PUBLIC = $MYOS_HOSTNAME
HOST_COMPOSE_PROJECT_NAME = $MYOS_HOSTNAME
```

Sur `sonic` le réseau public existant s'appelle `sonic`. myos allait donc créer
`axiomstudio` à côté, y attacher le conteneur, et registrator — qui lit l'IP
depuis `${DOCKER_NETWORK_PUBLIC}` — n'aurait rien enregistré d'utile.

**Pourquoi le filet a manqué** : rien ne compare l'idée que myos se fait de la
machine avec la machine. Le dry-run affichait `docker network create
axiomstudio` et cette ligne est passée inaperçue deux fois avant qu'un
`print-DOCKER_NETWORK_PUBLIC` explicite ne la rende évidente.

## Correctif

`lib/target.sh` et `lib/main.sh` : quand `--target` est donné, `MYOS_HOSTNAME`
vaut le nom de la cible, et `HOSTNAME` est **exporté** avec lui — sinon la
couche environnement (au-dessus du moteur) laisserait `${HOSTNAME}` dans une
stack en désaccord avec le réseau que le même run vient de nommer.
`MYOS_TARGET_<NAME>_HOSTNAME` surcharge la convention, `HOSTNAME=` sur la ligne
de commande surcharge les deux.

Trois goldens ré-enregistrés (`target-up-consul`, `target-context-up`,
`target-swarm-up`) : le projet et le réseau d'une stack `host/` s'appellent
désormais `sonic` et non `testhost`. Delta consigné dans `spec/golden/DELTAS.md`.

## Playbook avant tout premier déploiement sur une machine

Ne pas lire seulement le `-n`, vérifier les noms dérivés :

```sh
myos --target <cible> print-DOCKER_NETWORK_PUBLIC <stack>
myos --target <cible> print-COMPOSE_PROJECT_NAME <stack>
ssh <cible> docker network ls
```

Les deux premiers doivent exister dans le troisième, ou être délibérément neufs.
