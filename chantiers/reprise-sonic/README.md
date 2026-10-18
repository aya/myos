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

## L'état réel de sonic, versionné (2026-10-18)

Les trois checkouts du moteur Makefile sur sonic avaient des modifications
jamais commitées. Elles sont maintenant sur `git.p2p.legal/aya/myos`
(remote `upstream` de ces checkouts), sans secret : les mots de passe en dur
sont passés dans leur `/.env`, et le rendu de `make config` a été vérifié
identique avant et après. Ce sont les sources de vérité à comparer avec le
nouveau moteur :

| Checkout sur sonic | Branche | Commit |
|---|---|---|
| `~aya/Sources/myos` | `sonic` | `0e9af4f` (et `b2c7284` : restart always pour la stack host) |
| `~aya/Sources/myos.gtest` | `sonic-gtest` | `a7ae0d5` |
| `~aya/Applications/myos` | `sonic-applications` | `8092f9b` |

Hors des commits : `.env.gtest` et `LocalSettings.php` (des secrets), les
extensions MediaWiki (code tiers), et, dans `Applications/myos`, une image
docker décompressée par erreur à la racine (`blobs/`, `oci-layout`…).

## Le plan

[`plan.md`](plan.md) : la reprise préparée le 2026-10-18 au soir. Un dépôt
par user sous `~/dev/<user>/infra`, l'empreinte de chaque service comparée à
celle de son conteneur, les défauts du moteur trouvés en chemin, et l'ordre de
la bascule.

