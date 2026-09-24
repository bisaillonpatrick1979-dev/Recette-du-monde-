# Cuisine du monde

Plateforme mondiale de recettes, communauté culinaire et chef IA.

## Vision

- Recettes authentiques classées par pays, région et catégorie
- Profils, publications, notes, commentaires, abonnements et favoris
- Traduction automatique des recettes et commentaires
- Conversion intelligente des unités, portions et températures
- Onboarding par pays, langue et préférences de mesure
- Chef IA côté serveur avec crédits d'utilisation
- Abonnements payants à venir

## Stack

- Next.js 16 + React 19 + TypeScript
- Vercel pour le déploiement
- Supabase prévu pour Auth, Postgres, Storage et RLS
- Stripe prévu pour les abonnements
- OpenAI prévu côté serveur uniquement

## État actuel

- Globe interactif (MapLibre) : marqueurs pays → régions → villes selon le zoom, avec la spécialité locale
- Lien direct vers un lieu : `/explore?lieu=<slug>` (ex. `fr-marseille`)
- Recettes rattachées au lieu d'origine le plus précis connu (`recipes.primary_place_id`)
- « Classiques sans frontières » (`recipes.is_borderless`) : recettes internationales sans origine unique,
  sur `/continents/sans-frontieres`
- Recherche complète : `/search?q=`, `?categorie=`, `?filtre=`
- Communauté : publication, photos, vidéos, notes, J'aime, commentaires, profils publics `/cooks/<id>`,
  abonnements et fil « Mes abonnements »

## Migrations à appliquer

`supabase/migrations/20260924030000_recipe_videos.sql` (table `recipe_videos` + bucket `recipe-videos`)
n'est pas encore appliquée en production. Tant qu'elle ne l'est pas, la section vidéo reste en lecture seule.

## Sécurité

Aucune clé secrète ne doit être préfixée par `NEXT_PUBLIC_`. Les clés OpenAI, Stripe secrètes et Supabase service-role resteront exclusivement côté serveur.

## Déploiement

Déploiement continu prévu sur Vercel depuis la branche `main`.
