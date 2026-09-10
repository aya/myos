# 2026-09-10 : `.env.dist` ne pouvait pas initialiser DOMAIN, silencieusement

**Impact** : aucun en production — trouvé en préparant la première stack
(`crm`) sur `infra`. Le potentiel était large : toute stack déclarant
`DOMAIN=` dans son `.env.dist` recevait `localhost` à la place, donc des
`APP_HOST`, `SERVER_URL`, routes et noms de certificats faux, **sans un mot**.

**Déclencheur** : `infra/.env.dist` déclare `DOMAIN=hco.st`. Après
`myos env-update crm`, le `.env` rendu contenait `DOMAIN=localhost`, et
`SERVER_URL` sortait en `https://crm.localhost`.

## Cause racine

`myos_env_lookup` (`lib/env.sh`) commençait par `myos_var "$1"; [ -n
"$MYOS_ORIGIN" ] && return 0` : si **une** couche répondait, la ligne du
`.env.dist` était ignorée. Or le moteur répond toujours pour une poignée de
noms qu'il fournit avec un défaut : `DOMAIN` (localhost), `ENV` (local),
`USER`, `HOSTNAME`, `DOCKER_IMAGE_TAG` (latest). Ce défaut était pris pour une
réponse, donc ces noms-là ne pouvaient **jamais** être initialisés par un
`.env.dist`.

**Pourquoi c'est pire qu'une erreur** : la valeur écrite était plausible.
`DOMAIN=localhost` ne ressemble pas à une panne, il ressemble à un
environnement de développement. Rien ne signalait l'écrasement.

## Correctif

`lib/env.sh` : le repli du moteur n'est plus tenu pour une réponse. Toute
autre couche (ligne de commande, environnement, `.env`) gagne toujours, les
défauts du moteur étant la couche la plus basse.

```sh
myos_var "$1"; _el_engine=$R
case $MYOS_ORIGIN in ''|engine) ;; *) return 0 ;; esac
myos_env_dist_value "$1"; [ -n "$R" ] || { R=$_el_engine; return 0; }
```

Test de non-régression : `spec/verbs/vendored_spec.sh`, cas « lets a .env.dist
line beat the default the engine holds ». Il utilise `DOCKER_IMAGE_TAG` et non
`DOMAIN`, parce que le harnais pose `DOMAIN=example.test` dans l'environnement
— et l'environnement doit continuer de gagner. Vérifié rouge en annulant le
correctif.

## Playbook si ça se reproduit

- Symptôme : une valeur de `.env.dist` n'arrive pas dans `.env`, et la valeur
  écrite est un défaut plausible.
- `myos print-<NOM> <stack>` puis comparer à la ligne du `.env.dist`.
- Se rappeler que `.env` n'est **jamais réécrit** : une clé déjà fausse le
  reste. Supprimer la ligne (ou le fichier) avant de re-rendre.
