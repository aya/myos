# 0007. Le renouvellement des certificats appartient au conteneur dehydrated

**Statut** : accepté — 2026-09-26

## Contexte

`myos cert host` dérive les noms des routes (ADR 0004), écrit `domains.txt`
dans le volume host et lance `dehydrated -c` une fois. Rien ne le relançait
ensuite : un certificat émis par la v2 aurait expiré 90 jours plus tard, sans
un mot. Et `cert --check` répondait `ok` pour un certificat expiré, puisqu'il
ne vérifiait que sa présence.

Le défaut n'a pas encore coûté en v2, qui ne tourne sur aucune machine. Il a
été trouvé en cherchant pourquoi `ci.axiom-team.fr` avait expiré sur sonic,
où l'ancien couple acme-companion + post-hook échouait en silence :
[l'incident](../../infra/incidents/2026-09-26-certificats-renouveles-jamais-servis.md).

## Décision

Le conteneur `dehydrated` de la stack `host` renouvelle lui-même : son mode
`serve` lance `dehydrated -c` au démarrage (après 60 s, le temps que httpd
réponde aux challenges), puis toutes les `DEHYDRATED_INTERVAL` secondes
(`HOST_DEHYDRATED_INTERVAL`, 12 heures). Un certificat qui n'est pas dû
(`RENEW_DAYS`, 30 jours) est sauté sans requête à l'autorité : tourner souvent
ne coûte rien. Un échec est écrit sur stderr et n'arrête pas la boucle.

`myos cert host` garde deux rôles : réécrire `domains.txt` quand les routes
changent, et émettre tout de suite un nom nouveau. `myos cert host --check`
est le filet : exit 4 sur un certificat absent, expiré, ou à moins de
`MYOS_CERT_WARN_DAYS` (20) jours de sa fin. Comme dehydrated renouvelle à 30,
un certificat qui passe sous 20 est un certificat dont le renouvellement
échoue depuis dix jours.

Le code est dans le catalogue (`stack/host/dehydrated/entrypoint.sh`, testé
par `test-entrypoint.sh` à côté), la vérification ici (`lib/verb/cert.sh`,
`spec/verbs/cert_spec.sh`).

## Alternatives écartées

- **Un cron ou un timer systemd sur l'hôte appelant `myos cert host`** : il
  faut myos installé sur la machine, les droits d'y écrire une tâche, et une
  planification de plus à surveiller par machine. Le renouvellement tomberait
  en panne avec myos, alors que c'est la seule chose qui doit continuer quand
  personne ne regarde.
- **`myos up host` qui renouvelle** : un renouvellement qui dépend d'un
  déploiement n'a lieu que si l'on déploie. C'est précisément le cas oublié.
- **Un conteneur séparé (un « cron » sidecar)** : un service de plus pour
  lancer un binaire qui est déjà dans le conteneur qui sert les challenges.
- **Garder un post-hook qui recopie les certificats vers `/host/certs`**
  (l'ancien acme-companion) : c'est la copie, et son filtre, qui ont échoué
  sur sonic. dehydrated écrit directement là où fabio lit.

## Conséquences

- `myos cert host` peut échouer sur le verrou de dehydrated s'il tombe
  pendant un renouvellement périodique ; il suffit de le relancer.
- Personne n'appelle encore `cert --check` régulièrement : il faudra le
  brancher sur la supervision, ou dans `doctor`. Ce n'est pas fait.
- Une stack `host` qui n'utilise pas ce conteneur (sonic aujourd'hui) n'a
  aucun de ces filets.
