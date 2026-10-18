# 2026-10-18 : ufw-docker ne gère plus les conteneurs de sonic

**Impact** : les règles `route:allow` qui ouvrent les ports publiés des
conteneurs ne se mettent plus à jour. Quand le pare-feu de sonic a été
rétabli (`infra/adr/0010`, workspace aya), le FTP de `sonic-ftps` (21,
18700-18710), recréé avec une nouvelle IP, est resté fermé depuis
l'extérieur. Les anciennes règles visent des IP que d'autres conteneurs
ont reprises (clickhouse, twenty-server, une base duniter). Elles sont sans
effet, puisqu'aucun port n'y est redirigé.

**Déclencheur** : `make host SERVICE=ftps` (moteur Makefile, `setup-ufw`)
répond `ERROR: Docker instance "sonic-ftps" doesn't exist.` pour chaque port,
alors que le conteneur tourne.

## Cause racine

Établie en partie seulement :
- l'image de l'agent que lance le conteneur `sonic-ufw-docker`
  (`chaifeng/ufw-docker-agent:181003`) **n'existe plus sur le registre**
  (`manifest unknown`) ;
- le message `doesn't exist` vient du script `ufw-docker`. Il n'a pas été
  établi s'il vient de l'agent absent, ou d'un client docker trop ancien dans
  `sonic/ufw-docker:latest` (2022) face à docker 29 (API minimale 1.40).

## Pourquoi le filet a manqué

Le pare-feu de sonic était coupé à chaque boot
(`infra/incidents/2026-10-18-sonic-pare-feu-coupe-a-chaque-boot.md`). Tant
qu'il l'était, une règle manquante ne fermait rien : la panne d'ufw-docker
était invisible.

## Correctif

Aucun pour l'instant. Pour la réécriture : `firewall apply` (delta noté dans
`RESTART.md`) doit écrire les règles d'après l'IP courante du conteneur à
chaque `up`, sans agent tiers épinglé à une image de 2018.
