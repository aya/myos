# 2026-09-26 : `cert --check` répondait ok pour un certificat expiré, et rien ne renouvelait

**Impact** : aucun en production, la v2 n'y tourne pas. Mais une stack host v2
aurait perdu ses certificats 90 jours après leur émission, et le seul contrôle
prévu, `myos cert host --check`, aurait répondu `ok` jusqu'au bout.

**Déclencheur** : l'expiration de `ci.axiom-team.fr` sur sonic, sous l'ancien
moteur ([l'incident infra](../../infra/incidents/2026-09-26-certificats-renouveles-jamais-servis.md)).
En se demandant si la v2 aurait fait mieux, la réponse était non.

## Les deux défauts

- `myos_cert_check` lisait `openssl x509 -enddate` et traitait toute date
  comme un succès : `check ok (Sep 26 15:39:01 2026 GMT)` pour un certificat
  déjà mort. Son affichage texte ne nommait même pas le certificat, la cible
  d'un événement n'étant pas imprimée.
- `cert` lance `dehydrated -c` une fois ; aucun cron, aucun timer, aucune
  boucle ne le relançait. Le commentaire de l'entrypoint (« `myos cert issue`
  runs `dehydrated --cron` ») laissait croire le contraire.

## Pourquoi le filet a manqué

- **Le mock docker ne répondait rien à la commande de vérification**, donc
  `--check` ne pouvait être exercé que dans son cas d'échec, et aucun exemple
  de `spec/verbs/cert_spec.sh` ne le faisait. Un verbe sans test sur son chemin
  nominal passe pour couvert parce que le fichier de spec existe.
- **Le renouvellement est un comportement dans le temps** : aucune suite ne le
  voit, puisqu'aucune ne fait passer 60 jours. Il fallait l'écrire comme une
  exigence (« renouvelle encore, pas une fois ») pour pouvoir la tester.

## Correction

- `cert --check` : un mot d'état calculé dans le conteneur par
  `openssl x509 -checkend` — `expired`, `expiring` (sous `MYOS_CERT_WARN_DAYS`,
  20 jours), `valid` ; exit 4 sur les trois cas d'échec, chaque ligne nomme son
  certificat. Le mock répond `MOCK_CERT_STATE=<état>:<nom>`. Cinq exemples,
  rouges contre l'ancien `cert.sh` (5 échecs), verts avec le nouveau ;
  `make test` 321 exemples, 0 échec (les 3 warnings préexistants) ; `make lint`
  propre. `make test-portability` **non lancé** : pas de démon docker sur le
  poste.
- Le renouvellement : [ADR 0007](../adr/0007-le-renouvellement-appartient-au-conteneur.md),
  dans le catalogue (`host/dehydrated/entrypoint.sh`, `test-entrypoint.sh`
  rouge avant, vert après, sous sh et dash). **Non éprouvé dans une image
  construite** : les tests remplacent dehydrated, sleep et busybox.
