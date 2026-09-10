# 0005. Le compose amont est vendoré et jamais modifié

**Statut** : accepté — 2026-09-10

## Contexte

C'est l'idée principale de myos telle que l'opérateur l'énonce : pouvoir
utiliser le docker compose original d'un projet **sans le modifier**, pour que
les montées de version amont restent des diffs lisibles, et le surcharger avec
un compose et des variables dynamiques pour lancer le projet sans aucune
configuration manuelle.

## Décision

Dans un répertoire de stack, `docker-compose.yml` est le fichier amont copié
octet pour octet. myos le charge **avant** `<nom>.yml`, la surcharge, qui gagne.
Tout ce que le déploiement décide vit dans `<nom>.yml`, `<nom>.settings` et
`.env.dist`. Un `UPSTREAM.md` porte la provenance, le sha256 et la procédure de
mise à jour.

## Conséquences

- Un upgrade amont est un `curl`, un `diff -u` qu'on lit, et un `cp`.
- Si la surcharge doit un jour répéter quelque chose de l'amont, c'est le moment
  de se demander ce qui manque à myos — pas de patcher le fichier vendoré.
- Trois choses de l'amont sont connues de la surcharge et casseraient
  silencieusement à un upgrade : les ports publiés, les noms de services, et les
  variables lues. `UPSTREAM.md` les nomme.
- Deux défauts du moteur découverts en appliquant ce principe :
  [l'audit aveugle à la surcharge](../incidents/2026-09-10-audit-firewall-aveugle-a-la-surcharge.md)
  et [`.env.dist` écrasé par le défaut du moteur](../incidents/2026-09-10-env-dist-ecrase-par-le-defaut-du-moteur.md).
