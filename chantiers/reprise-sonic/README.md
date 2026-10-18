# Chantier : reprendre sonic avec la réécriture

**But** : que le moteur réécrit (`tdd`) puisse recréer à l'identique chaque
projet que sonic fait tourner, puis remplacer le moteur Makefile sur cette
machine sans recréation involontaire. C'est l'étape « the fleet » de
`RESTART.md`, appliquée à l'hôte le plus chargé.

Ce qu'on sait, au 2026-10-18 :

- [`moteur-make-sur-sonic.md`](moteur-make-sur-sonic.md) : comment le moteur
  Makefile fonctionne sur sonic (deux moteurs, `make` et `myos`, aux défauts
  différents), la commande exacte qui recrée chaque projet, la stack hôte
  (nginx, fabio, consul, registrator), et ce que la réécriture doit reproduire
  (§5) ; le §6 dit ce que la réparation du 2026-10-18 a constaté en
  exécutant ces commandes ;
- l'inventaire des conteneurs et de leur provenance, régénérable :
  `../../../infra/machines/sonic.md` (workspace aya, dépôt `infra`).

Prochain pas : pour chaque projet de l'inventaire lancé par un moteur myos,
comparer `make config` (ancien) et `myos -n` (nouveau) — projet, fichiers et
leur ordre, `config --hash`, images, réseaux (§5.4).
