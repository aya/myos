# 2026-10-18 : fabio se route vers lui-même quand un service perd son réseau

**Impact** : sur sonic, de 17:35 à 18:49, fabio a renvoyé vers lui-même
toute requête sans route propre, jusqu'au timeout :
- environ 1 500 lignes de log par seconde ;
- 4 CPU occupés ;
- des 500 sur une vingtaine de sites.

Cause première : `sonic-nginx-1` avait perdu son réseau dans un reboot
(`infra/incidents/2026-10-18-sonic-reseaux-perdus-au-reboot.md`, workspace aya).

**Déclencheur** : `sonic-nginx-1` porte les tags `urlprefix-*:80/*` et
`urlprefix-*:443/*`. Il tournait sans réseau.

## Cause racine

Stack host du moteur Makefile, constatée dans les logs :

- registrator tourne avec `-internal -useIpFromNetwork sonic`. Pour un
  conteneur qui n'est pas sur le réseau `sonic`, il écrit
  `Network 'sonic' not found in container configuration` et **l'annonce
  quand même**, avec l'IP de l'hôte et le port **exposé**. nginx devient
  donc `161.97.174.60:443`, et cette adresse est celle de fabio
  (`-proxy.addr :80,:443`, réseau host) ;
- rien, ni dans fabio ni dans les tags, n'interdit une route vers l'adresse
  d'écoute de fabio. Avec une route attrape-tout, toute requête inconnue
  boucle.

Le même mécanisme vaut pour tout service annoncé sur le port 80 ou 443 sans
réseau `sonic` : `aya-mediawiki-local-mediawiki-80` l'était aussi le
2026-10-18.

## Pourquoi le filet a manqué

- registrator a été écrit pour des conteneurs qu'il joint par l'IP de l'hôte
  et un port publié. Avec `-internal`, l'IP de l'hôte combinée au port exposé
  n'a plus de sens, et pourtant il s'en sert en repli.
- Personne ne surveille les routes de fabio. La table est passée de 65 à 34
  routes sans alerte.

## Correctif

Aucun dans le moteur Makefile. Pour la réécriture (chantier
`chantiers/reprise-sonic/`) :
- ne jamais annoncer un service sans IP sur le réseau public de l'hôte ;
- refuser une route dont la destination est l'adresse d'écoute du routeur.

Une vérification « aucune route vers l'hôte sur 80/443 » se ferait aussi
contre l'API de fabio (`:9998/api/routes`).

## Leçon

Un repli silencieux dans l'annonce des services fabrique une boucle dès que
le routeur écoute là où le repli pointe.
