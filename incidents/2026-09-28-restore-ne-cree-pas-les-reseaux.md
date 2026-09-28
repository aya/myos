# 2026-09-28 : `restore` ne crée pas les réseaux du projet

**Impact** : aucun en production. Trouvé par la répétition de restauration de
l'ERPNext de HCO sur une copie (`infra/stack/erpnext/tests/test-backup.sh`).
La copie ne démarrait plus :
`network hco-restau declared as external, but could not be found`.

**Déclencheur** : le frontend d'ERPNext a rejoint le réseau privé du tenant
(`private`, `hco-<env>`) le 28/09. La copie vit dans un autre environnement
(`ENV=restau`), dont le réseau privé `hco-restau` n'avait jamais été créé.

## Cause racine

`up` appelle `myos_networks_ensure` avant `compose up`. `restore` appelait
`compose up -d` directement. Il ne créait donc ni le réseau privé ni le réseau
public, alors que les fichiers compose les déclarent externes. Sur une machine
neuve, une restauration échouait de la même façon.

## Pourquoi le filet a manqué

La spec de `restore` simulait une machine qui avait déjà ses réseaux. Et la
répétition du 27/09 passait, parce que le frontend n'utilisait alors que le
réseau public, qui existait déjà sur le poste.

## Correctif

`myos_restore_default` appelle `myos_networks_ensure` avant `up`. Nouvel
exemple dans `spec/verbs/restore_spec.sh` : vu rouge sans le correctif, vert
avec. Suite complète : pas de nouvel échec (les deux échecs connus restent).
