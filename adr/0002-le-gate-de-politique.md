# 0002. Le gate de politique est la frontière du self-service

**Statut** : accepté — 2026-09-10

## Contexte

Des développeurs client doivent pouvoir déployer leurs applications. Or l'accès
au socket Docker d'un manager est root sur le cluster, et Swarm n'a pas de
RBAC : on ne peut littéralement pas donner d'accès Docker à un client. Le
self-service exige donc un courtier, et ce courtier a besoin d'une règle.

## Décision

`myos policy [audit]` lit les fichiers compose et refuse, pour toute stack qui
n'est pas une stack `host/` :

- **deny** — l'évasion : `privileged`, `cap_add`, namespace hôte (`pid`, `ipc`,
  `userns_mode`, `network_mode`), `devices`, `security_opt` unconfined,
  bind-mount de l'hôte, socket Docker.
- **warn** — l'hygiène de cluster partagé : pas de `healthcheck`, pas de
  `deploy.resources.limits`. `MYOS_POLICY_REQUIRE` les promeut en denials.

Le gate **s'exécute là où l'auteur de la stack ne peut pas le modifier** : sur
la machine qui applique, jamais dans le CI du projet. `MYOS_POLICY_ENFORCE=true`
le place devant `up` ; `apply` l'active toujours.

## Conséquences

- Les évasions d'une stack `host/` sont rapportées en `warn` et non en `deny` :
  c'est la couche de confiance du modèle. Rapportées quand même — un proxy qui
  lit l'API Docker veut un socket-proxy en lecture seule, pas le socket.
- Le dosage warn/deny est ce qui rend le gate adoptable : en tout-deny il
  refuserait l'intégralité du catalogue actuel dès le premier jour, serait
  désactivé, et ne protégerait plus rien.
- Sur le catalogue existant il trouve déjà du vrai : `drone/drone-runner-docker`
  monte le socket, `x2go/vdi` cumule `SYS_ADMIN` et deux profils unconfined.
