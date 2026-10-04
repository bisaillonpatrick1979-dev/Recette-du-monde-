# Lot 30 — régions et villes, 4 octobre 2026

Sept nouveaux plats, adaptés pour une cuisine domestique. Titres FR/EN/ES; contenu français avec fallback existant. Photos Wikimedia Commons examinées individuellement, avec auteur et licence conservés dans `photos.json` et `recipe_images`. Aucun ancien plat modifié ou archivé dans ce lot.

| Plat | Pays | Lieu principal | Vérification géographique |
|---|---|---|---|
| Kiritanpo nabe | JP | Préfecture d’Akita | [MAFF](https://www.maff.go.jp/e/policies/market/k_ryouri/search_menu/2602/index.html) : tradition liée à Odate et Kazuno; attribution à la préfecture plutôt qu’à une seule ville. |
| Hiyajiru | JP | Préfecture de Miyazaki | [MAFF](https://www.maff.go.jp/e/policies/market/k_ryouri/search_menu/4019/index.html) : plaines centrales de Miyazaki; variante froide au poisson, sans udon. |
| Saffranspannkaka | SE | Île de Gotland | [Visit Gotland](https://visitgotland.se/tips-och-reseguide/klassiska-ratter/) et [ICA](https://www.ica.se/recept/gotlandsk-saffranspannkaka-327821/). |
| Gooey butter cake | US | Saint-Louis, Missouri | [Explore St. Louis](https://explorestlouis.com/guide/emblematic-eats/) et [King Arthur Baking](https://www.kingarthurbaking.com/recipes/st-louis-gooey-butter-cake-recipe). |
| Dresdner Eierschecke | DE | Dresde, Saxe | [Tourisme de Saxe](https://www.sachsen-tourismus.de/blog/rezept-fuer-dresdner-eierschecke) : trois couches, dont quark, contrairement à la variante de Freiberg. |
| Oyakodon | JP | Tokyo | [MAFF](https://www.maff.go.jp/e/policies/market/k_ryouri/search_menu/3539/index.html) : association historique documentée, mais récits d’invention multiples. Recette adaptée depuis [Kikkoman](https://www.kikkoman.com/en/cookbook/washoku/oyakodon.html). |
| Stovies | GB | Écosse | [Parent Club](https://www.parentclub.scot/recipe/stovies), service du gouvernement écossais. Aucune ville attribuée. |

## Photos retenues

- Kiritanpo : cylindres de riz grillé dans la marmite au poulet; exclure les brochettes seules au miso.
- Hiyajiru : fichier `12 2夕食（冷や汁定食） (2097833934).jpg`, CC BY-SA 2.0, Yamaguchi Yoshiaki. La description japonaise nomme le plat; la soupe est visible à droite dans un repas complet. Le texte de recette précise ce cadrage. Recherche complémentaire par nom japonais après absence de résultat latin du robot.
- Gotland : `Saffranspannkaka.jpg`, tranche de gâteau de riz jaune avec crème et confiture sombre; buffet générique exclu.
- Saint-Louis : `182365 Gooey Butter Cake.jpg`, gâteau au beurre nature en carrés; variantes à la citrouille exclues. La photographie identifie le plat, sans établir la formule exacte du pâtissier.
- Dresde : `Dresdner Eierschecke 2.jpg`, trois couches visibles.
- Tokyo : `Oyakodon 003.jpg`, poulet et œufs sur riz; variante avec jaune cru exclue.
- Écosse : `Stovies with beef leftovers & oatcakes.jpg`, pommes de terre et restes de bœuf, avec galettes d’avoine.

## Candidat écarté

Tarte al djote de Nivelles : aucune photo exacte validée. `Chard and Cheese Tart.jpg`, utilisé par une page Wikipédia, décrit une tarte de blog générique; il ne prouve pas la boulette de Nivelles. Ne pas importer ce candidat ni sa photo. Openverse a renvoyé HTTP 403; ce blocage ne constitue pas une preuve d’absence de photo.

## Contrôles

- Comparaison avec les 1 719 recettes présentes, publiées ou archivées : aucun de ces sept noms de plats déjà présent. Contrôle supplémentaire des lots locaux et garde SQL à l’import.
- Pays et lieux distincts : Saint-Louis au Missouri, pas Saint-Louis au Sénégal. Réutilisation des lieux existants Dresde et Écosse; cinq nouveaux lieux.
- Sept photos licenciées, URLs accessibles, inspection visuelle; crédits et pages source conservés.
- Migration idempotente, ingrédients, étapes, portions, trois titres, photo prête et rattachements pays/lieu vérifiés après import.
- Les anciennes photos du catalogue ne sont pas toutes réauditées dans ce lot.
