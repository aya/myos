# 0006. Le dépôt de configuration, et les couches de valeurs

**Statut** : accepté — 2026-09-10

## Contexte

Un déploiement doit pouvoir être fait depuis un second poste, ou depuis une CI,
**avec la même commande et le même résultat**, sans que personne ne se
transmette un `.env` à la main. C'est la condition pour que le mode PaaS
fonctionne : la CI n'exécute rien de particulier, elle exécute ce que
l'opérateur exécute.

Le moteur make avait cette pièce : `CONFIG_REPOSITORY` cloné en `config/`, dont
`config/<env>/<app>/.env` alimentait les valeurs. Le refacto v2 l'avait perdue.

## Décision

Un dépôt de configuration, disposé comme le moteur make le faisait :

```
<config>/.env                     partagé par tout
<config>/<env>/.env               partagé par un environnement
<config>/<env>/<app>/.env         une application dans un environnement
<config>/<env>/<app>/secrets.env  les mêmes, chiffrés (sops)
```

`MYOS_CONFIG` le désigne, `MYOS_CONFIG_REPOSITORY` est son URL, `myos secrets
pull` le clone ou le met à jour. Le plus spécifique gagne, et **tout perd
contre `$WORKDIR/.env`** : le fichier qu'on édite pour déboguer reste le
dernier mot.

Deux conséquences que le reste de la conception a dû suivre :

- **`env-update` n'écrit rien** pour une clé qu'une couche réelle fournit
  déjà. Recopier en clair, dans le `.env` de chaque poste, un secret que le
  coffre garde chiffré, annulerait l'intérêt de le chiffrer.
- **Les littéraux de `.env.dist` sont lus avant tout rendu.** Un projet qui
  déclare `MYOS_USER=hco` ou `DOMAIN=hco.st` doit être entendu dès le premier
  `up`, sinon son premier déploiement est nommé d'après celui qui l'a lancé.
  Une valeur qui se calcule (`$(...)`, `${...}`) n'est pas une déclaration :
  elle reste un modèle, rendu une fois.

## Conséquences

L'ordre des couches, du plus fort au plus faible :

```
ligne de commande > environnement > .env.<ENV> > .env > coffre (config + secrets)
  > littéraux de .env.dist > valeurs des stacks > configuration machine > moteur
```

- Une CI n'a besoin que de deux choses : le dépôt de configuration et la clé
  age du cluster. Elle tape la même commande que l'opérateur.
- Le texte clair ne touche jamais le disque : il vit dans une variable de shell
  le temps de l'appel.
- `myos secrets` liste les fichiers et les **noms**, jamais les valeurs.

## Alternatives écartées

- **Recopier le `.env` d'un poste à l'autre** : ce que le PaaS doit supprimer.
- **Un secret par variable d'environnement de CI** : ça marche pour une CI et
  pas pour un opérateur, donc les deux chemins divergent — et c'est exactement
  ce qu'on voulait éviter.
