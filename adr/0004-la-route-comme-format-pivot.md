# 0004. La route comme format pivot, le routeur comme choix de la stack host

**Statut** : accepté — 2026-09-10

## Contexte

Le catalogue déclare ses routes en tags consul `urlprefix-…` que fabio lit. Le
passage éventuel à Traefik ne doit pas obliger à redéclarer les routes de
chaque stack. Et `lib/verb/cert.sh` **dérive les noms de certificats de ces
tags** : il ne parle pas à consul, il relit la chaîne.

Constat vérifié au passage : il n'existe aujourd'hui aucun service mesh eBPF
pour Docker Swarm. Cilium a commencé comme plugin libnetwork en 2015 puis a
pivoté vers Kubernetes ; son L4LB standalone est le seul scénario non-Kubernetes
supporté. L'eBPF au niveau mesh est une capacité Kubernetes.

## Décision

Un service déclare sa route **une fois** (`<SVC>_SERVICE_<PORT>_URIS` et
`_PATH`). Elle se rend deux fois : `@tagprefix` donne la forme canonique
`urlprefix-…`, `@traefikrule` la même route en règle Traefik (un wildcard
devenant `HostRegexp`, Traefik v3 n'ayant pas de `Host` à joker).
`MYOS_ROUTER=fabio|traefik` dit laquelle est vivante.

`@tagprefix` reste canonique quel que soit le routeur, parce que `cert` la lit :
les certificats ne dépendent pas du proxy en façade.

## Conséquences

- Le routeur devient un choix de la stack `host/` et non une propriété de
  chaque stack qu'elle sert.
- Si l'eBPF compte vraiment dans la cible, c'est un argument pour k3s, pas pour
  Swarm — à verser au pari de l'ADR 0002.
