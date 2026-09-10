# 0003. Les secrets : sops + age, une paire de clés par cluster

**Statut** : accepté — 2026-09-10

## Contexte

Le dépôt doit pouvoir porter des secrets sans que tous les clusters puissent
tous les lire, et sans dépendre d'un service à sceller et à sauvegarder dès le
premier jour.

## Décision

`secrets.<ENV>.env` puis `secrets.env`, chiffrés par sops, une paire age **par
cluster** : un secret est chiffré pour la clé du cluster destinataire (plus une
clé de secours). Déchiffrés dans une couche de `myos_var` placée **entre
`$WORKDIR/.env` et les défauts des stacks**. `MYOS_SECRETS=sops|none` est la
couture par laquelle un fournisseur OpenBao entrera.

## Conséquences

- Le cluster `wbr` ne peut pas déchiffrer les secrets de `c411`,
  mathématiquement. La clé privée ne quitte pas la machine qui applique.
- La ligne de commande, l'environnement et `.env` gagnent toujours : déboguer un
  déploiement ne doit pas obliger à réécrire le coffre.
- Honnêtement : les secrets restent dans l'historique git **pour toujours**, il
  n'y a pas de révocation, et la rotation est manuelle. C'est le prix payé pour
  ne pas exploiter un coffre HA tout de suite, et la raison de la couture.
- Livraison en **Docker Swarm secrets** sous `/run/secrets`, jamais en variable
  d'environnement : `docker inspect`, les logs et un rapport de crash sont
  publics.
- `myos secrets` liste les noms, jamais les valeurs.

## Alternatives écartées

- **OpenBao / Vault** : credentials dynamiques, baux révocables, journal
  d'audit. Écarté pour l'instant : un service HA à sceller, sauvegarder,
  exploiter, et un nouveau problème d'amorçage (qui descelle au redémarrage ?).
