-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 5 recettes, 0 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"poutine-smoked-meat","country":"CA","place":"ca-montreal","original":"Poutine au smoked meat","title":"Poutine au smoked meat (frites, fromage en grains, sauce brune et viande fumée)","en":"Montreal smoked meat poutine","es":"Poutine con smoked meat de Montreal","desc":"La poutine classique — frites dorées, fromage en grains qui fait couic et sauce brune bien chaude — garnie de smoked meat de Montréal tranché et réchauffé, l’une des variantes les plus populaires des delicatessens montréalais.","cat":"Street food","diff":"medium","prep":30,"cook":40,"serv":4,"reference":"https://fr.wikipedia.org/wiki/Poutine","ing":[["Pommes de terre Russet",1.2,"kg","en bâtonnets"],["Huile de friture",2,"l",null],["Fromage en grains frais",400,"g","à température ambiante"],["Smoked meat de Montréal",300,"g","tranché puis haché grossièrement"],["Beurre",40,"g",null],["Farine",40,"g",null],["Bouillon de bœuf",400,"ml",null],["Bouillon de poulet",200,"ml",null],["Sauce Worcestershire",1,"c. à thé",null],["Ketchup",1,"c. à soupe",null],["Poivre noir",0.5,"c. à thé",null],["Cornichon à l’aneth",4,null,"pour servir"]],"steps":["Rincer les frites à l’eau froide, bien les sécher, puis les cuire une première fois 6 minutes à 160 °C ; égoutter.","Préparer la sauce : faire un roux brun avec beurre et farine, mouiller avec les bouillons, ajouter Worcestershire, ketchup et poivre, et mijoter 10 minutes jusqu’à ce qu’elle nappe.","Réchauffer le smoked meat 5 minutes à la vapeur ou dans un peu de bouillon pour qu’il reste tendre.","Frire les frites une seconde fois 3 minutes à 190 °C jusqu’à ce qu’elles soient croustillantes ; saler.","Dans chaque bol, alterner frites et fromage en grains, puis napper de sauce brûlante.","Couvrir de smoked meat et servir aussitôt avec un cornichon à l’aneth."],"photo":{"file":"Smoked meat poutine","url":"https://live.staticflickr.com/8232/8392258439_a6aab8c232_b.jpg","page":"https://www.flickr.com/photos/51035707449@N01/8392258439","author":"Matt Biddulph","license":"CC BY-SA 2.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/2.0/","source":"Flickr (via Openverse)"}},{"slug":"michigan-quebecois","country":"CA","place":"ca-quebec","original":"Michigan","title":"Michigan (hot-dog à la sauce à la viande épicée)","en":"Michigan hot dog (Quebec style)","es":"Michigan (perrito con salsa de carne)","desc":"Saucisse grillée dans un pain vapeur, recouverte d’une sauce à la viande hachée épicée à la tomate et au cumin, avec ou sans oignons hachés : née dans la région de Plattsburgh, la michigan est devenue un classique des casse-croûte du sud du Québec, souvent servie avec des frites et la même sauce.","cat":"Street food","diff":"easy","prep":15,"cook":60,"serv":6,"reference":"https://en.wikipedia.org/wiki/Michigan_hot_dog","ing":[["Saucisses à hot-dog",12,null,null],["Pains à hot-dog",12,null,null],["Bœuf haché mi-maigre",500,"g",null],["Oignon",1,null,"haché très fin"],["Ail",2,"gousses","hachées"],["Pâte de tomate",156,"ml",null],["Eau",500,"ml",null],["Assaisonnement au chili (chili powder)",1,"c. à soupe",null],["Cumin moulu",1,"c. à thé",null],["Paprika",1,"c. à thé",null],["Piment de Cayenne",0.25,"c. à thé",null],["Cassonade",1,"c. à thé",null],["Moutarde jaune",3,"c. à soupe","pour servir"],["Oignon blanc",1,null,"haché, pour servir"],["Sel",1,"c. à thé",null]],"steps":["Dans une casserole, émietter le bœuf cru dans l’eau froide à la fourchette pour obtenir une texture très fine.","Ajouter l’oignon, l’ail, la pâte de tomate, les épices, la cassonade et le sel, porter à ébullition.","Mijoter à découvert 45 minutes à 1 heure en remuant, jusqu’à une sauce épaisse et bien liée.","Griller ou pocher les saucisses et réchauffer les pains à la vapeur.","Badigeonner le pain de moutarde, y déposer la saucisse et napper généreusement de sauce à la viande.","Servir avec ou sans oignons hachés, et des frites nappées du reste de sauce."],"photo":{"file":"File:Michigan hot dogs with and without onions 01.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Michigan_hot_dogs_with_and_without_onions_01.jpg/1280px-Michigan_hot_dogs_with_and_without_onions_01.jpg","page":"https://commons.wikimedia.org/wiki/File:Michigan_hot_dogs_with_and_without_onions_01.jpg","author":"William Graham","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"pouding-au-riz-quebecois","country":"CA","place":"ca-quebec","original":"Pouding au riz","title":"Pouding au riz à l’ancienne (riz au lait vanillé et raisins secs)","en":"Old-fashioned Quebec rice pudding","es":"Arroz con leche a la antigua de Quebec","desc":"Riz à grains ronds cuit lentement dans le lait sucré jusqu’à devenir crémeux, parfumé à la vanille et à la muscade, avec des raisins secs : le dessert réconfortant des cuisines familiales québécoises, servi tiède ou froid saupoudré de cannelle.","cat":"Dessert","diff":"easy","prep":10,"cook":50,"serv":6,"reference":"https://fr.wikipedia.org/wiki/Riz_au_lait","ing":[["Riz à grains ronds (ou arborio)",150,"g",null],["Lait entier",1,"l",null],["Sucre",100,"g",null],["Raisins secs",75,"g",null],["Œufs",2,null,"jaunes seulement"],["Crème 35 %",125,"ml",null],["Vanille",1,"c. à thé",null],["Muscade râpée",1,"pincée",null],["Cannelle",0.5,"c. à thé","pour servir"],["Sel",1,"pincée",null]],"steps":["Rincer le riz, le mettre dans une grande casserole avec le lait, le sucre et le sel.","Porter doucement à frémissement puis cuire à feu très doux 40 minutes en remuant souvent, jusqu’à ce que le riz soit tendre et crémeux.","Ajouter les raisins secs pour les 10 dernières minutes.","Fouetter les jaunes avec la crème, la vanille et la muscade, incorporer une louche de riz chaud puis reverser dans la casserole.","Cuire 2 minutes en remuant sans laisser bouillir, jusqu’à épaississement.","Verser dans des bols et servir tiède ou froid, saupoudré de cannelle."],"photo":{"file":"File:Bol de riz au lait.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Bol_de_riz_au_lait.jpg/1280px-Bol_de_riz_au_lait.jpg","page":"https://commons.wikimedia.org/wiki/File:Bol_de_riz_au_lait.jpg","author":"anonyme","license":"CC BY-SA 3.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/3.0","source":"Wikimedia Commons"}},{"slug":"pate-au-poulet-quebecois","country":"CA","place":"ca-quebec","original":"Pâté au poulet","title":"Pâté au poulet québécois (tourte au poulet et aux légumes)","en":"Quebec chicken pot pie","es":"Pastel de pollo quebequense","desc":"Morceaux de poulet et légumes (carottes, petits pois, céleri, oignon) liés dans une sauce veloutée au bouillon, cuits sous une croûte de pâte brisée dorée : un souper réconfortant de semaine dans les familles du Québec.","cat":"Plat principal","diff":"medium","prep":40,"cook":60,"serv":6,"reference":"https://en.wikipedia.org/wiki/Pot_pie","ing":[["Poulet cuit",600,"g","en morceaux"],["Pâte brisée",400,"g",null],["Carottes",2,null,"en dés"],["Céleri",2,"branches","en dés"],["Oignon",1,null,"haché"],["Petits pois",150,"g",null],["Pommes de terre",2,null,"en dés"],["Beurre",60,"g",null],["Farine",60,"g",null],["Bouillon de poulet",600,"ml",null],["Lait",125,"ml",null],["Sarriette séchée",1,"c. à thé",null],["Œuf",1,null,"pour dorer"],["Sel et poivre",1,"c. à thé",null]],"steps":["Cuire carottes et pommes de terre 8 minutes à l’eau salée, égoutter.","Faire fondre l’oignon et le céleri dans le beurre, ajouter la farine et cuire 2 minutes.","Verser le bouillon et le lait en fouettant, ajouter la sarriette, saler, poivrer et laisser épaissir 5 minutes.","Ajouter le poulet, les légumes cuits et les petits pois, puis verser dans un plat allant au four.","Couvrir de pâte abaissée, souder les bords, faire une cheminée au centre et dorer à l’œuf.","Cuire 35 à 40 minutes à 200 °C jusqu’à ce que la croûte soit bien dorée et que la sauce bouillonne."],"photo":{"file":"File:Chickenpie1.JPG","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Chickenpie1.JPG/1280px-Chickenpie1.JPG","page":"https://commons.wikimedia.org/wiki/File:Chickenpie1.JPG","author":"Thecopse","license":"Public domain","licenseUrl":null,"source":"Wikimedia Commons"}},{"slug":"pain-dore-au-sirop-derable","country":"CA","place":"ca-quebec","original":"Pain doré","title":"Pain doré au sirop d’érable et bacon","en":"Quebec French toast with maple syrup","es":"Torrijas quebequenses con jarabe de arce","desc":"Tranches épaisses de pain trempées dans un mélange d’œufs, de lait, de cannelle et de vanille, dorées au beurre et arrosées de sirop d’érable, servies avec du bacon croustillant : le déjeuner du dimanche au Québec.","cat":"Petit-déjeuner","diff":"easy","prep":10,"cook":20,"serv":4,"reference":"https://fr.wikipedia.org/wiki/Pain_perdu","ing":[["Pain de ménage tranché épais (ou pain brioché)",8,"tranches","de la veille"],["Œufs",4,null,null],["Lait",250,"ml",null],["Cannelle",1,"c. à thé",null],["Vanille",1,"c. à thé",null],["Cassonade",1,"c. à soupe",null],["Beurre",40,"g",null],["Bacon",8,"tranches",null],["Sirop d’érable",125,"ml","pour servir"]],"steps":["Cuire le bacon à la poêle ou au four jusqu’à ce qu’il soit croustillant, le garder au chaud.","Fouetter les œufs avec le lait, la cannelle, la vanille et la cassonade dans une assiette creuse.","Tremper chaque tranche de pain quelques secondes de chaque côté.","Dorer les tranches dans le beurre 2 à 3 minutes par face à feu moyen.","Servir aussitôt avec le bacon et beaucoup de sirop d’érable."],"photo":{"file":"File:Breakfast on The Canadian.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Breakfast_on_The_Canadian.jpg/1280px-Breakfast_on_The_Canadian.jpg","page":"https://commons.wikimedia.org/wiki/File:Breakfast_on_The_Canadian.jpg","author":"Martin Cathrae","license":"CC BY-SA 2.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/2.0","source":"Wikimedia Commons"}}]$batch$::jsonb);
