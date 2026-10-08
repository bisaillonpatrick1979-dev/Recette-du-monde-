# Spoontrotter

*Travel the world, one spoon at a time — Faites le tour du monde, une cuillère à la fois.*

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
- Vercel pour le déploiement (projet `recettes`)
- Supabase pour Auth, Postgres, Storage et RLS (projet `Cuisine-du-monde`, ca-central-1)
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
- Vidéos de recettes : table `recipe_videos` et bucket `recipe-videos` en production
- Titres trilingues : chaque recette publiée a un titre FR, EN et ES dans `recipe_title_translations`
- Favoris (`favorites`) et « Je l'ai cuisinée » (`cook_attempts`) sur chaque recette; section « Mes favoris » du profil
- Chef IA sur chaque recette : route serveur `/api/chef` (OpenAI, `OPENAI_MODEL` facultatif, `gpt-4o-mini` par défaut).
  Forfait gratuit de 10 questions par mois (`entitlements`), débité seulement après une réponse réussie
  (`credits_ia()` puis `consommer_credit_ia()`), journalisé dans `ai_usage_events`
- Notifications créées par déclencheurs SQL (j'aime, note, commentaire, abonnement, cuisinée), page `/notifications`
- Modération : signalements (`content_reports`, à consulter dans Supabase) et blocage de membres (`user_blocks`)

## Catalogue (5 octobre 2026)

- 1 892 recettes publiées et 121 archivées (retrait réversible, faute de photo exacte validée)
- Chaque recette publiée a une photo validée, des ingrédients, des étapes et ses trois titres
- Aucun doublon pays + titre original parmi les recettes publiées
- 634 recettes proviennent du Wikibooks Cookbook (CC BY-SA 4.0) : leurs titres FR et ES ont été ajoutés
  (`model = 'claude-titres-2026-10-05'`), mais la description et les étapes restent en anglais
- Règles d'ajout de recettes : `data/editorial-batches/PIPELINE.md`

## Base de données et migrations

La base Supabase fait foi. L'historique du dépôt et celui de la base ne concordent pas entièrement :

- certaines passes photo ont été appliquées en production sans fichier dans `supabase/migrations/`
  (`recipe_photos_third_pass` à `recipe_photos_seventh_pass`);
- les lots 23 à 32 et les nettoyages photo ont des fichiers dans le dépôt, mais ont été exécutés
  hors de l'historique des migrations Supabase.

La migration `20261006030000_notifications_et_credits_chef_ia` a été exécutée par morceaux (`execute_sql`)
puis inscrite à la main dans `supabase_migrations.schema_migrations`.

Le contenu est bien en production; c'est seulement l'historique qui diverge. Avant un `supabase db reset`
ou une nouvelle base, comparer avec `supabase migration list` plutôt que de rejouer le dossier tel quel.

## Robot photo

Le workflow « Recherche photos » publie les miniatures candidates sur des branches orphelines
`photo-review/run-<n>`. Ces branches ne contiennent pas l'application : le workflow y dépose un
`vercel.json` (`deploymentEnabled: false`) pour que Vercel ne tente plus de les construire.

## Sécurité

Aucune clé secrète ne doit être préfixée par `NEXT_PUBLIC_`. Les clés OpenAI, Stripe secrètes et Supabase service-role resteront exclusivement côté serveur.

À faire dans le tableau de bord Supabase : activer la protection contre les mots de passe compromis (Auth).

## Déploiement

Déploiement continu sur Vercel depuis la branche `main`; chaque branche poussée obtient une preview.
