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

La branche `build/initial-app` contient le premier MVP visuel et fonctionnel :
- onboarding
- préférences locales
- page d'accueil multilingue FR/EN/ES
- recherche de démonstration
- recettes vedettes
- exploration par pays
- aperçu de communauté
- mise en page mobile

## Sécurité

Aucune clé secrète ne doit être préfixée par `NEXT_PUBLIC_`. Les clés OpenAI, Stripe secrètes et Supabase service-role resteront exclusivement côté serveur.

## Déploiement

Déploiement continu prévu sur Vercel depuis la branche `main`.
