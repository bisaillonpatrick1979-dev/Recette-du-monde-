# Pipeline éditorial — Recette de la planète

Ce pipeline s'applique à toute nouvelle recette officielle ajoutée à l'application.

## 1. Géographie

Avant publication :
- vérifier le pays avec une source culinaire ou touristique fiable;
- ajouter une région, une ville, une île ou une localité uniquement quand l'association est documentée;
- conserver le pays ISO dans `country_code`;
- relier la recette à `culinary_places` via `primary_place_id` et `recipe_locations`.

Une association populaire mais non spécifique ne doit pas être transformée en origine locale précise.

## 2. Contenu de la recette

Chaque recette publiée doit avoir :
- un `original_title`;
- une description;
- des portions de base;
- des ingrédients avec quantités numériques quand c'est applicable;
- des étapes;
- temps de préparation et de cuisson;
- une source de référence éditoriale.

Les méthodes peuvent être marquées comme adaptées lorsqu'une technique traditionnelle n'est pas raisonnablement reproductible à la maison.

## 3. Langues

Langues actuellement supportées :
- français;
- anglais;
- espagnol.

Chaque recette officielle doit avoir :
- un titre FR / EN / ES dans `recipe_title_translations`;
- une traduction complète EN / ES dans `recipe_translations` au fur et à mesure du backfill;
- le français sert de fallback si une traduction complète manque.

## 4. Photos

Règle stricte : une photo présentée comme photo de la recette doit représenter le plat lui-même.

Ordre de priorité :
1. photo enregistrée et vérifiée dans `recipe_images`;
2. photo Wikimedia Commons trouvée avec correspondance stricte du nom du plat;
3. aucune photo : placeholder « Photo exacte à ajouter ».

Interdit :
- utiliser une photo générique de cuisine du pays comme si elle représentait le plat;
- utiliser une image dont le fichier ou la description correspond à une autre recette;
- retirer l'attribution ou la licence d'une image externe.

Pour une image Wikimedia persistée, conserver au minimum :
- `external_url`;
- `source_page_url`;
- auteur / photographe si connu;
- `license_name`;
- `license_url`;
- `source_type = external_licensed`;
- `status = ready`.

## 5. Contrôle avant fusion

Vérifier :
- aucune recette en double;
- pays / région / ville cohérents;
- portions non nulles;
- ingrédients et étapes présents;
- trois titres localisés présents;
- traduction complète quand le lot la prévoit;
- photo exacte ou statut explicite à compléter;
- Build GitHub vert;
- preview Vercel READY.

Le pipeline privilégie la précision à la quantité : une recette sans photo exacte est acceptable temporairement; une mauvaise photo ne l'est pas.
