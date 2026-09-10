# Décisions — myos

La conception du moteur. Ce qui lie tous les projets est dans l'atelier
(`../adr.md`) ; ce qui concerne une plateforme est chez elle (`../infra/adr.md`).

Format et règles : `../AGENTS.md`. Prochain numéro : **0006**.

| # | Décision | Statut |
|---|---|---|
| [0001](adr/0001-une-cible-nomme-la-machine.md) | Une cible nomme la machine, et les valeurs d'hôte la suivent | accepté |
| [0002](adr/0002-le-gate-de-politique.md) | Le gate de politique est la frontière du self-service | accepté |
| [0003](adr/0003-secrets-sops-age.md) | Les secrets : sops + age, une paire de clés par cluster | accepté |
| [0004](adr/0004-la-route-comme-format-pivot.md) | La route comme format pivot, le routeur comme choix de la stack host | accepté |
| [0005](adr/0005-compose-amont-vendore.md) | Le compose amont est vendoré et jamais modifié | accepté |

## Ce qui reste à trancher

- **Le format de nom de projet** sur les machines existantes : `sonic` est au
  format historique `user-app-env` (`aya-duniter-master`), le moteur produit
  `user-env-app`. `myos migrate pin` fige l'ancien — désormais pour de vrai.
- **`status --strict` en backend swarm** : les compteurs de réplicas ne sont pas
  les paires state/health de l'audit. Exit 2 explicite pour l'instant.
- **Le gate et la fusion compose** : `policy` lit les fichiers bruts, donc une
  surcharge qui retire un montage par `volumes: !override` lui échappe encore.
