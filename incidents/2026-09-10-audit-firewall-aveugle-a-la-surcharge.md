# 2026-09-10 : `firewall audit` ne voyait pas la surcharge, rendant `--strict` insatisfiable

**Impact** : aucun en production — trouvé sur la première stack vendorée
(`crm`). Le potentiel : **toute** stack construite selon l'ADR 0007 (compose
amont non modifié plus surcharge) produisait un faux positif permanent, donc
un `--strict` que personne ne peut satisfaire, donc un `--strict` qu'on
désactive, donc l'invariant de bind qui cesse d'être tenu.

**Déclencheur** : le compose amont de twenty publie `"3000:3000"`, sur toutes
les adresses. La surcharge le remplace par `ports: !override` avec
`${MYOS_BIND_PRIVATE}::3000`. `docker compose config` confirmait un seul
binding, sur `127.0.0.1`. `myos firewall crm --strict` sortait quand même en 4
sur `server:3000 public 0.0.0.0`.

## Cause racine

`myos_ports_raw` (`lib/verb/firewall.sh`) analyse les fichiers compose **bruts**
en awk, un par un. C'est délibéré — l'audit doit fonctionner sans démon docker.
Mais il ignorait les balises de fusion de compose : une liste `ports:` d'un
fichier ultérieur s'ajoutait à celle du précédent au lieu de la remplacer.

## Correctif

L'awk honore désormais `!override` et `!reset` : il accumule les ports par
service dans l'ordre de fusion et vide la liste du service quand la balise
apparaît. L'audit reste statique, sans docker.

Test de non-régression : `spec/verbs/vendored_spec.sh`, cas « sees through a
ports: !override of the overlay ». Vérifié rouge en neutralisant la condition.

## Ce que ça dit de plus général

Un audit qui lit les fichiers bruts et une exécution qui lit la fusion sont
deux vérités différentes. À chaque fois qu'on ajoutera une règle statique sur
les fichiers compose, il faudra se demander ce que la fusion en fait. Le gate
de politique (ADR 0004) a exactement la même cécité : une surcharge qui
retirerait un montage par `volumes: !override` ne serait pas vue. Non corrigé,
noté ici.

## Playbook si ça se reproduit

- Symptôme : `firewall` ou `policy` rapporte quelque chose que la surcharge a
  supprimé.
- Arbitre : `myos config <stack>` (c'est-à-dire `compose config`), qui est la
  seule vérité sur ce qui sera lancé.
