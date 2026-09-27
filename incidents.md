# Incidents — myos

Les défauts du moteur. Format et règles : `../AGENTS.md`.

Cinq d'entre eux ont été trouvés le même jour, en construisant la première
stack réelle (`../infra/stack/twenty`). C'est la leçon la plus utile de la
journée : **une suite verte ne dit rien tant qu'un usage réel ne l'a pas
traversée.** Quatre étaient invisibles pour la même raison — le harnais de test
fixe une valeur, et chaque valeur qu'il fixe est un chemin de lecture que rien
n'exerce.

| Date | Incident | Portée |
|---|---|---|
| 2026-09-27 | [`print` et `up` ne sont pas d'accord sur le nom du projet](incidents/2026-09-27-print-et-up-divergent-sur-le-nom-du-projet.md) | quasi-accident, ouvert |
| 2026-09-26 | [`cert --check` répondait ok pour un certificat expiré, et rien ne renouvelait](incidents/2026-09-26-cert-check-ok-sur-un-certificat-expire.md) | v2, corrigé |
| 2026-09-26 | [un `up` à blanc écrit le `.env` et y génère des secrets, qui masquent le coffre](incidents/2026-09-26-un-up-a-blanc-ecrit-le-env.md) | quasi-accident, ouvert |
| 2026-09-26 | [un `COMPOSE_FILE_<X>` posé dans un `.settings` est accepté puis ignoré](incidents/2026-09-26-interrupteur-de-surcharge-ignore-dans-un-settings.md) | défaut, ouvert |
| 2026-09-10 | [la config machine écrasait le domaine du projet](incidents/2026-09-10-config-machine-ecrase-le-domaine-du-projet.md) | quasi-accident |
| 2026-09-10 | [`migrate pin` n'avait aucun effet, et rapportait un succès](incidents/2026-09-10-migrate-pin-sans-effet.md) | défaut |
| 2026-09-10 | [un déploiement distant allait créer un réseau nommé d'après le portable](incidents/2026-09-10-hostname-du-poste-sur-une-cible-distante.md) | quasi-accident |
| 2026-09-10 | [`firewall audit` ne voyait pas la surcharge](incidents/2026-09-10-audit-firewall-aveugle-a-la-surcharge.md) | défaut |
| 2026-09-10 | [`.env.dist` ne pouvait pas initialiser DOMAIN, silencieusement](incidents/2026-09-10-env-dist-ecrase-par-le-defaut-du-moteur.md) | défaut |
