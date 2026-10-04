-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 7 recettes, 5 nouveaux lieux.
-- Recettes rédigées pour l'application (adaptations éditoriales) à partir des compositions traditionnelles documentées.
-- Données source : data/recipe-batches/. Photos : Wikimedia Commons, vérifiées une à une (auteur et licence conservés).
-- Chargeur temporaire (pg_temp : disparaît à la fin de la session, jamais exposé à l'API).
create or replace function pg_temp.spoontrotter_import(batch jsonb) returns integer
language plpgsql as $fn$
declare
  r jsonb;
  p jsonb;
  ph jsonb;
  rid uuid;
  country_place uuid;
  place uuid;
  place_name text;
  region_text text;
  source_name constant text := 'Spoontrotter — adaptation éditoriale';
  author constant uuid := 'ac515660-4852-4ebd-8cb5-3348d60e06e9';
  total integer := 0;
begin
  for r in select value from jsonb_array_elements(batch) loop
    select id into country_place from public.culinary_places
      where country_code = r->>'country' and place_type = 'country' order by created_at limit 1;
    if country_place is null then
      raise exception 'Pays absent de l''atlas : %', r->>'country';
    end if;

    p := r->'place';
    if jsonb_typeof(p) = 'object' then
      insert into public.culinary_places (slug, name, country_code, place_type, parent_id, latitude, longitude, default_zoom, summary, is_active)
      values (p->>'slug', p->>'name', r->>'country', p->>'type', country_place, (p->>'lat')::float8, (p->>'lng')::float8,
              coalesce((p->>'zoom')::float8, case when p->>'type' = 'region' then 7 else 9 end), p->>'summary', true)
      on conflict (slug) do nothing;
      select id, name into place, place_name from public.culinary_places where slug = p->>'slug';
    elsif jsonb_typeof(p) = 'string' then
      select id, name into place, place_name from public.culinary_places where slug = p #>> '{}';
      if place is null then
        raise exception 'Lieu absent de l''atlas : %', p #>> '{}';
      end if;
    else
      place := country_place;
      place_name := null;
    end if;

    region_text := coalesce(r->>'region', place_name);
    rid := md5('spoontrotter:recipe:' || (r->>'slug'))::uuid;
    ph := r->'photo';
    if jsonb_typeof(ph) is distinct from 'object'
       or nullif(ph->>'url', '') is null or nullif(ph->>'page', '') is null
       or nullif(ph->>'license', '') is null then
      raise exception 'Photo vérifiée obligatoire pour %', r->>'slug';
    end if;
    -- Un nouveau slug ne doit pas recréer un plat déjà importé sous un autre nom.
    if exists (
      select 1 from public.recipes existing
      where existing.id <> rid and existing.country_code = r->>'country'
        and lower(regexp_replace(regexp_replace(coalesce(existing.original_title, existing.title), '\([^)]*\)', '', 'g'), '[^[:alnum:]]', '', 'g'))
          = lower(regexp_replace(regexp_replace(r->>'original', '\([^)]*\)', '', 'g'), '[^[:alnum:]]', '', 'g'))
    ) then
      raise exception 'Doublon de plat détecté pour %', r->>'slug';
    end if;

    insert into public.recipes (id, author_id, title, original_title, slug, description, excerpt, source_language, country_code, region,
      category, authenticity, status, difficulty, prep_minutes, cook_minutes, servings, published_at, primary_place_id,
      is_editorial, is_borderless, source_name, source_url, source_notes)
    values (rid, author, r->>'title', r->>'original', r->>'slug', r->>'desc', r->>'desc', 'fr', r->>'country', region_text,
      r->>'cat', coalesce(r->>'auth', 'adapted')::public.recipe_authenticity, 'published', (r->>'diff')::public.recipe_difficulty,
      (r->>'prep')::int, (r->>'cook')::int, (r->>'serv')::numeric, now(), place,
      true, false, source_name, coalesce(r->>'reference', ph->>'page'),
      'Recette éditoriale rédigée pour l’application à partir de la composition traditionnelle documentée du plat.')
    on conflict (id) do update set title = excluded.title, original_title = excluded.original_title, description = excluded.description,
      excerpt = excluded.excerpt, country_code = excluded.country_code, region = excluded.region, category = excluded.category,
      difficulty = excluded.difficulty, prep_minutes = excluded.prep_minutes, cook_minutes = excluded.cook_minutes,
      servings = excluded.servings, primary_place_id = excluded.primary_place_id, source_url = excluded.source_url, updated_at = now();

    delete from public.recipe_ingredients where recipe_id = rid;
    insert into public.recipe_ingredients (recipe_id, position, name, quantity, unit, note)
    select rid, (t.o - 1)::int, t.e->>0, (t.e->>1)::numeric, t.e->>2, t.e->>3
    from jsonb_array_elements(r->'ing') with ordinality as t(e, o);

    delete from public.recipe_steps where recipe_id = rid;
    insert into public.recipe_steps (recipe_id, position, instruction)
    select rid, (t.o - 1)::int, t.s from jsonb_array_elements_text(r->'steps') with ordinality as t(s, o);

    delete from public.recipe_title_translations where recipe_id = rid;
    insert into public.recipe_title_translations (recipe_id, language_code, title, model) values
      (rid, 'fr', r->>'title', 'editorial-seed'),
      (rid, 'en', r->>'en', 'editorial-reviewed'),
      (rid, 'es', r->>'es', 'editorial-reviewed');

    delete from public.recipe_locations where recipe_id = rid;
    insert into public.recipe_locations (recipe_id, place_id, relation, is_primary) values (rid, place, 'origin', true);
    if place <> country_place then
      insert into public.recipe_locations (recipe_id, place_id, relation, is_primary) values (rid, country_place, 'origin', false);
    end if;

    delete from public.place_specialties where recipe_id = rid;
    insert into public.place_specialties (place_id, recipe_id, name, description, origin_note, is_signature, sort_order, source_name, source_url)
    values (place, rid, r->>'original', r->>'desc', coalesce(region_text, (select name from public.culinary_places where id = country_place)),
            place <> country_place, 10, source_name, ph->>'page');

    delete from public.recipe_images where recipe_id = rid and source_type = 'external_licensed';
    if jsonb_typeof(ph) = 'object' then
      insert into public.recipe_images (recipe_id, source_type, status, external_url, alt_text, source_name, source_page_url,
        photographer_name, license_name, license_url, attribution_text, is_primary, is_representative, moderation_notes)
      values (rid, 'external_licensed', 'ready', ph->>'url', r->>'title', coalesce(ph->>'source', 'Wikimedia Commons'), ph->>'page',
        nullif(ph->>'author', ''), ph->>'license', nullif(ph->>'licenseUrl', ''),
        'Photo : ' || coalesce(nullif(ph->>'author', ''), 'auteur inconnu') || ' · ' || (ph->>'license') || ' · ' || coalesce(ph->>'source', 'Wikimedia Commons'),
        true, true, 'Photo libre vérifiée à l’œil : le fichier représente ce plat.');
    end if;

    total := total + 1;
  end loop;
  return total;
end;
$fn$;
select pg_temp.spoontrotter_import($batch$[{"slug":"kiritanpo-nabe-akita","country":"JP","original":"Kiritanpo nabe (きりたんぽ鍋)","title":"Kiritanpo nabe d’Akita","en":"Akita kiritanpo chicken hotpot","es":"Kiritanpo nabe de Akita","desc":"Marmite d’Akita aux cylindres de riz grillé, poulet et légumes. Tradition associée notamment à Odate et Kazuno; adaptation avec bouillon préparé.","cat":"Plat principal","diff":"medium","prep":30,"cook":35,"serv":4,"reference":"https://www.maff.go.jp/e/policies/market/k_ryouri/search_menu/2602/index.html","place":{"slug":"jp-akita","name":"Préfecture d’Akita","type":"region","lat":39.72,"lng":140.1,"summary":"Préfecture du nord du Japon, associée au kiritanpo notamment à Odate et Kazuno."},"ing":[["Riz japonais cuit",600,"g","encore tiède"],["Poulet désossé",350,"g","en morceaux"],["Bouillon de poulet",1200,"ml",null],["Maitake",150,"g",null],["Bardane",100,"g","brossée, en lamelles"],["Poireau",1,null,"émincé"],["Persil japonais seri",50,"g",null],["Sauce soja",60,"ml",null],["Saké",30,"ml",null]],"steps":["Écraser partiellement le riz. Avec les mains humides, former 8 cylindres serrés autour de brochettes épaisses.","Griller en tournant 10 à 15 minutes jusqu’à légère coloration. Retirer les brochettes et couper chaque cylindre en deux.","Porter bouillon, soja et saké à frémissement. Ajouter poulet et bardane; mijoter 15 minutes, jusqu’à 74 °C au cœur du poulet.","Ajouter champignons et poireau; cuire 8 minutes. Déposer le riz grillé et le seri, puis frémir 2 à 3 minutes. Servir immédiatement."],"photo":{"file":"File:Kiritanpo nabe z.JPG","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Kiritanpo_nabe_z.JPG/1280px-Kiritanpo_nabe_z.JPG","page":"https://commons.wikimedia.org/wiki/File:Kiritanpo_nabe_z.JPG","author":"Chensiyuan","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"hiyajiru-miyazaki","country":"JP","original":"Hiyajiru (冷や汁)","title":"Hiyajiru de Miyazaki","en":"Miyazaki chilled miso and fish soup","es":"Hiyajiru de Miyazaki","desc":"Soupe froide de Miyazaki au poisson, miso, sésame et concombre, servie avec du riz. Adaptation au maquereau grillé; la photo montre un repas avec le hiyajiru à droite.","cat":"Plat principal","diff":"easy","prep":25,"cook":15,"serv":4,"reference":"https://www.maff.go.jp/e/policies/market/k_ryouri/search_menu/4019/index.html","place":{"slug":"jp-miyazaki","name":"Préfecture de Miyazaki","type":"region","lat":31.91,"lng":131.42,"summary":"Préfecture de Kyushu dont les plaines centrales sont associées au hiyajiru."},"ing":[["Filet de maquereau",150,"g","sans arêtes"],["Miso",3,"c. à soupe",null],["Sésame grillé",2,"c. à soupe",null],["Dashi",600,"ml","refroidi"],["Tofu ferme",200,"g",null],["Concombre",1,null,"finement tranché"],["Shiso",6,"feuilles","ciselées"],["Riz cuit",500,"g",null]],"steps":["Griller le poisson 10 à 15 minutes jusqu’à cuisson complète. Retirer peau et arêtes, puis émietter.","Piler poisson, sésame et miso. Étaler dans un plat et passer brièvement sous le gril pour légèrement colorer, sans brûler.","Délayer cette pâte avec le dashi froid. Incorporer tofu émietté, concombre et shiso. Réfrigérer 30 minutes.","Servir la soupe bien froide sur le riz ou à côté, pour la verser au moment de manger."],"photo":{"file":"File:12 2夕食（冷や汁定食） (2097833934).jpg","url":"https://upload.wikimedia.org/wikipedia/commons/1/1a/12_2%E5%A4%95%E9%A3%9F%EF%BC%88%E5%86%B7%E3%82%84%E6%B1%81%E5%AE%9A%E9%A3%9F%EF%BC%89_%282097833934%29.jpg","page":"https://commons.wikimedia.org/wiki/File:12_2%E5%A4%95%E9%A3%9F%EF%BC%88%E5%86%B7%E3%82%84%E6%B1%81%E5%AE%9A%E9%A3%9F%EF%BC%89_(2097833934).jpg","author":"Yamaguchi Yoshiaki from Japan","license":"CC BY-SA 2.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/2.0","source":"Wikimedia Commons"}},{"slug":"saffranspannkaka-gotland","country":"SE","original":"Saffranspannkaka","title":"Saffranspannkaka de Gotland","en":"Gotland saffron rice pancake","es":"Saffranspannkaka de Gotland","desc":"Dessert de Gotland : un gâteau de riz au safran et aux amandes, servi avec crème et confiture de mûres de ronce bleue, ou de mûres ordinaires.","cat":"Dessert","diff":"easy","prep":15,"cook":80,"serv":8,"reference":"https://www.ica.se/recept/gotlandsk-saffranspannkaka-327821/","geography_reference":"https://visitgotland.se/tips-och-reseguide/klassiska-ratter/","place":{"slug":"se-gotland","name":"Gotland","type":"island","lat":57.5,"lng":18.5,"summary":"Île suédoise associée à la saffranspannkaka, traditionnellement accompagnée de salmbärssylt."},"ing":[["Riz rond à dessert",150,"g",null],["Eau",300,"ml",null],["Lait",800,"ml",null],["Safran",0.5,"g",null],["Sucre",80,"g",null],["Œufs",3,null,null],["Amandes",70,"g","hachées"],["Sel",0.25,"c. à thé",null],["Beurre",10,"g","pour le plat"],["Crème et confiture de mûres",null,null,"pour servir"]],"steps":["Cuire riz, eau et sel à couvert 10 minutes. Ajouter le lait, puis cuire doucement 35 à 45 minutes en remuant régulièrement, jusqu’à riz tendre et crémeux.","Laisser tiédir. Écraser le safran avec un peu de sucre, puis l’incorporer avec le reste du sucre, les amandes et les œufs battus.","Verser dans un plat beurré de 9 pouces de côté. Cuire à 175 °C environ 30 minutes, jusqu’à centre pris et surface dorée.","Servir tiède ou froid avec crème et confiture."],"photo":{"file":"File:Saffranspannkaka.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/d/df/Saffranspannkaka.jpg","page":"https://commons.wikimedia.org/wiki/File:Saffranspannkaka.jpg","author":"Per Ola Wiberg from Ekerö, Sweden","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0","source":"Wikimedia Commons"}},{"slug":"gooey-butter-cake-st-louis","country":"US","original":"Gooey butter cake","title":"Gooey butter cake de Saint-Louis","en":"St. Louis gooey butter cake","es":"Pastel de mantequilla de San Luis","desc":"Gâteau emblématique de Saint-Louis au Missouri, avec fond levé et garniture au beurre fondante. Version sans fromage à la crème.","cat":"Dessert","diff":"medium","prep":25,"cook":40,"serv":16,"reference":"https://www.kingarthurbaking.com/recipes/st-louis-gooey-butter-cake-recipe","geography_reference":"https://explorestlouis.com/guide/emblematic-eats/","place":{"slug":"us-st-louis","name":"Saint-Louis (Missouri)","type":"city","lat":38.63,"lng":-90.2,"summary":"Ville du Missouri dont le gooey butter cake est une spécialité emblématique."},"ing":[["Farine",360,"g","210 g fond, 150 g garniture"],["Beurre mou",255,"g","85 g fond, 170 g garniture"],["Sucre",335,"g","35 g fond, 300 g garniture"],["Levure sèche",2,"c. à thé",null],["Lait",45,"ml",null],["Eau tiède",60,"ml","30 ml par couche"],["Œufs",2,null,"un par couche"],["Sirop de maïs clair",80,"g",null],["Vanille",2,"c. à thé",null],["Sel",1,"c. à thé","moitié par couche"],["Sucre glace",null,null,"finition"]],"steps":["Mélanger levure, lait et 30 ml d’eau. Crémer 85 g de beurre avec 35 g de sucre et la moitié du sel; ajouter un œuf, puis 210 g de farine et le liquide. Battre 5 minutes.","Étaler dans un moule beurré de 9 × 13 pouces. Couvrir; laisser presque doubler, environ 2 h 30.","Crémer le beurre, sucre et sel restants; ajouter l’autre œuf. Incorporer alternativement farine restante et mélange sirop, vanille et eau restante.","Étaler sur le fond levé. Cuire à 175 °C, 30 à 45 minutes : dessus doré, centre très souple. Refroidir complètement avant de poudrer et couper."],"photo":{"file":"File:182365 Gooey Butter Cake.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/182365_Gooey_Butter_Cake.jpg/1280px-182365_Gooey_Butter_Cake.jpg","page":"https://commons.wikimedia.org/wiki/File:182365_Gooey_Butter_Cake.jpg","author":"Amanda","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0","source":"Wikimedia Commons"}},{"slug":"eierschecke-dresden","country":"DE","original":"Dresdner Eierschecke","title":"Eierschecke de Dresde","en":"Dresden Eierschecke quark cake","es":"Eierschecke de Dresde","desc":"Gâteau de Dresde à trois couches : pâte, quark et crème aux œufs. Prévoir 45 minutes de levée et 3 heures de refroidissement.","cat":"Dessert","diff":"hard","prep":40,"cook":65,"serv":12,"reference":"https://www.sachsen-tourismus.de/blog/rezept-fuer-dresdner-eierschecke","place":"de-dresden","region":"Dresde, Saxe","ing":[["Farine",170,"g",null],["Levure sèche",7,"g",null],["Lait",460,"ml","60 ml pâte, 400 ml crème"],["Beurre mou",230,"g","30 g pâte, 100 g quark, 100 g crème"],["Sucre",160,"g","30 g pâte, 100 g quark, 30 g crème"],["Sucre glace",100,"g",null],["Œufs",7,null,"1 pâte, 2 quark, 4 séparés crème"],["Quark maigre",500,"g",null],["Poudre de pudding vanille à cuire",74,"g","37 g quark, 37 g crème"],["Zeste de citron",0.5,null,"citron"],["Sel",2,"pincées",null]],"steps":["Pétrir farine, levure, 60 ml de lait, 30 g de beurre, 30 g de sucre, un œuf et sel. Lever 45 minutes; étaler dans un moule beurré de 10 pouces.","Mélanger 100 g de beurre, 100 g de sucre, 2 œufs, quark, zeste et 37 g de poudre. Étaler sur la pâte.","Cuire poudre restante, 400 ml de lait et 30 g de sucre; tiédir. Mélanger beurre restant, sucre glace et 4 jaunes; incorporer le pudding.","Monter les blancs salés; incorporer délicatement, puis étaler sur le quark.","Cuire 60 minutes à 165 °C, chaleur tournante. Reposer 30 minutes dans le four éteint entrouvert; refroidir puis réfrigérer 3 heures."],"photo":{"file":"File:Dresdner Eierschecke 2.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Dresdner_Eierschecke_2.jpg/1280px-Dresdner_Eierschecke_2.jpg","page":"https://commons.wikimedia.org/wiki/File:Dresdner_Eierschecke_2.jpg","author":"Brücke-Osteuropa","license":"CC0","licenseUrl":"http://creativecommons.org/publicdomain/zero/1.0/deed.en","source":"Wikimedia Commons"}},{"slug":"oyakodon-japonais","country":"JP","original":"Oyakodon (親子丼)","title":"Oyakodon japonais de Tokyo","en":"Tokyo oyakodon chicken and egg rice bowl","es":"Oyakodon de Tokio","desc":"Bol de riz au poulet et aux œufs associé à Tokyo. Les récits d’invention varient; cette adaptation domestique utilise des œufs entièrement cuits.","cat":"Plat principal","diff":"easy","prep":10,"cook":15,"serv":2,"reference":"https://www.kikkoman.com/en/cookbook/washoku/oyakodon.html","geography_reference":"https://www.maff.go.jp/e/policies/market/k_ryouri/search_menu/3539/index.html","place":{"slug":"jp-tokyo","name":"Tokyo","type":"city","lat":35.68,"lng":139.76,"summary":"Ville associée à l’histoire de l’oyakodon, notamment au restaurant Tamahide; plusieurs récits d’origine existent."},"ing":[["Riz cuit",400,"g",null],["Poulet désossé",200,"g","en petits morceaux"],["Oignon",0.5,null,"émincé"],["Œufs",3,null,null],["Dashi",150,"ml",null],["Sauce soja",2,"c. à soupe",null],["Mirin",2,"c. à soupe",null],["Sucre",1,"c. à thé",null],["Mitsuba",null,null,"quelques feuilles"]],"steps":["Porter dashi, soja, mirin et sucre à frémissement dans une petite poêle. Ajouter oignon et poulet.","Cuire à couvert 8 à 10 minutes, jusqu’à poulet entièrement cuit à 74 °C au centre.","Battre légèrement les œufs et les répartir sur le poulet. Couvrir à feu doux jusqu’à ce qu’ils soient pris.","Répartir le riz dans deux bols, glisser la garniture dessus avec son jus, puis ajouter le mitsuba."],"photo":{"file":"File:Oyakodon 003.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Oyakodon_003.jpg/1280px-Oyakodon_003.jpg","page":"https://commons.wikimedia.org/wiki/File:Oyakodon_003.jpg","author":"Ocdp","license":"CC0","licenseUrl":"http://creativecommons.org/publicdomain/zero/1.0/deed.en","source":"Wikimedia Commons"}},{"slug":"stovies-ecossais","country":"GB","original":"Stovies","title":"Stovies écossais au bœuf","en":"Scottish beef stovies","es":"Stovies escoceses de ternera","desc":"Pommes de terre et oignons mijotés avec des restes de bœuf rôti. Plat familial écossais aux nombreuses variantes; adaptation sans ville d’origine attribuée.","cat":"Plat principal","diff":"easy","prep":15,"cook":40,"serv":4,"reference":"https://www.parentclub.scot/recipe/stovies","place":"gb-scotland","ing":[["Pommes de terre",1000,"g","pelées, en tranches épaisses"],["Oignons",2,null,"émincés"],["Bœuf rôti cuit",300,"g","effiloché"],["Graisse de cuisson ou beurre",30,"g",null],["Bouillon de bœuf",350,"ml",null],["Sel et poivre",null,null,"au goût"]],"steps":["Faire fondre la graisse dans une casserole. Ajouter les oignons et cuire doucement 8 minutes.","Ajouter pommes de terre et bouillon. Couvrir et mijoter 25 à 30 minutes, jusqu’à pommes de terre très tendres; ajouter un peu d’eau si nécessaire.","Incorporer le bœuf et réchauffer 5 minutes, jusqu’à 74 °C au centre. Écraser quelques pommes de terre pour lier, en laissant des morceaux.","Rectifier l’assaisonnement et servir chaud, avec des galettes d’avoine si désiré."],"photo":{"file":"File:Stovies with beef leftovers & oatcakes.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Stovies_with_beef_leftovers_%26_oatcakes.jpg/1280px-Stovies_with_beef_leftovers_%26_oatcakes.jpg","page":"https://commons.wikimedia.org/wiki/File:Stovies_with_beef_leftovers_%26_oatcakes.jpg","author":"Mutt Lunker","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}}]$batch$::jsonb);
