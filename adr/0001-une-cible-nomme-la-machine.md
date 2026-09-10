# 0001. Une cible nomme la machine, et les valeurs d'hôte la suivent

**Statut** : accepté — 2026-09-10

## Contexte

`--target NAME` envoie un déploiement vers un autre endpoint docker. Mais tout
ce que le modèle myos dérive de l'hôte — `HOSTNAME`, le réseau `public`, le
projet d'une stack `host/`, `HOST` — était calculé sur la machine qui exécute
la commande. Un déploiement lancé du portable vers sonic créait un réseau nommé
d'après le portable, où fabio ne peut rien trouver. Voir
[l'incident](../incidents/2026-09-10-hostname-du-poste-sur-une-cible-distante.md).

## Décision

Quand `--target` est donné, `MYOS_HOSTNAME` vaut le nom de la cible, et
`HOSTNAME` est **exporté** avec lui pour que la couche environnement soit
d'accord avec le moteur. Par convention le nom de la cible est le nom de la
machine ; `MYOS_TARGET_<NAME>_HOSTNAME` dit autrement, `HOSTNAME=` sur la ligne
de commande gagne sur les deux.

## Conséquences

- L'inventaire vit dans le dépôt qui porte les stacks (`.ssh/config` du projet,
  `MYOS_TARGET_*` dans `.env.dist`), pas dans un fichier privé.
- Corollaire non anticipé : en déploiement distant, `/etc/conf.d/myos` de la
  machine cible **ne s'applique plus**, puisque myos tourne en local et que seul
  le socket est distant. Les valeurs de niveau machine (`DOMAIN`) doivent donc
  vivre au niveau projet.

## Alternatives écartées

- **Demander à la cible** (`docker info --format '{{.Name}}'`) : autoritatif,
  mais un appel réseau au démarrage de chaque run, et cela casse le dry-run
  hors ligne. Reste l'autorité si la convention et la réalité divergent.
