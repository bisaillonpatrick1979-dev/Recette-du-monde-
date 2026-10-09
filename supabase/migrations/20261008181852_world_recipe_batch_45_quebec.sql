-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 6 recettes, 1 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"ragout-boulettes-pattes-cochon","country":"CA","place":"ca-quebec","original":"Ragoût de pattes de cochon","title":"Ragoût de boulettes et de pattes de cochon","en":"Quebec meatball and pork hock stew","es":"Guiso de albóndigas y patas de cerdo de Quebec","desc":"Jarrets de porc mijotés longuement avec des boulettes de porc haché parfumées au clou de girofle et à la cannelle, dans une sauce brune liée à la farine grillée, servis avec des pommes de terre pilées : le grand classique du temps des Fêtes au Québec.","cat":"Plat principal","diff":"medium","prep":45,"cook":210,"serv":8,"reference":"https://fr.wikipedia.org/wiki/Ragoût_de_pattes_de_cochon","ing":[["Jarrets (pattes) de porc",4,null,"environ 2 kg"],["Porc haché",900,"g",null],["Oignons",3,null,"dont 1 râpé"],["Ail",3,"gousses",null],["Chapelure",60,"g",null],["Œuf",1,null,null],["Clou de girofle moulu",0.5,"c. à thé",null],["Cannelle",0.5,"c. à thé",null],["Muscade",0.25,"c. à thé",null],["Farine grillée",100,"g","grillée à sec jusqu’à couleur noisette"],["Eau froide",2.5,"l",null],["Laurier",2,"feuilles",null],["Sel et poivre",2,"c. à thé",null],["Pommes de terre pilées",1.5,"kg","pour servir"]],"steps":["Couvrir les jarrets d’eau froide avec 2 oignons, l’ail, le laurier, la moitié des épices, du sel et du poivre, et mijoter 2 h 30 à couvert.","Griller la farine à sec dans une poêle en remuant jusqu’à une couleur noisette et la laisser refroidir.","Mélanger le porc haché avec l’oignon râpé, la chapelure, l’œuf, le reste des épices, du sel et du poivre, et façonner des boulettes de 4 cm.","Retirer les jarrets, ajouter les boulettes au bouillon et cuire 30 minutes.","Délayer la farine grillée dans de l’eau froide, l’incorporer au bouillon en remuant et laisser épaissir 10 minutes ; remettre les jarrets désossés ou entiers.","Servir avec des pommes de terre pilées et des betteraves marinées."],"photo":{"file":"File:Ragout.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/Ragout.jpg/1280px-Ragout.jpg","page":"https://commons.wikimedia.org/wiki/File:Ragout.jpg","author":"Idéalités","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"pate-au-saumon-quebec","country":"CA","place":"ca-quebec","original":"Pâté au saumon","title":"Pâté au saumon québécois","en":"Quebec salmon pie","es":"Pastel de salmón de Quebec","desc":"Tourte à double croûte garnie de saumon émietté et de pommes de terre pilées à l’oignon et au beurre, assaisonnée de sarriette, servie chaude avec des cornichons, une sauce aux œufs ou du ketchup aux fruits.","cat":"Plat principal","diff":"easy","prep":30,"cook":50,"serv":6,"reference":"https://fr.wikipedia.org/wiki/Pâté_au_saumon","ing":[["Pâte brisée",500,"g","pour deux abaisses"],["Saumon en conserve (ou cuit)",500,"g","égoutté et émietté"],["Pommes de terre",600,"g","cuites et pilées"],["Oignon",1,null,"haché finement"],["Beurre",40,"g",null],["Lait",60,"ml",null],["Sarriette séchée",1,"c. à thé",null],["Œuf",1,null,"battu, pour dorer"],["Sel et poivre",1,"c. à thé",null],["Cornichons sucrés",4,null,"pour servir"]],"steps":["Préchauffer le four à 200 °C.","Faire fondre l’oignon dans le beurre sans le colorer.","Mélanger les pommes de terre pilées avec l’oignon, le lait, le saumon émietté, la sarriette, le sel et le poivre.","Foncer une assiette à tarte avec une abaisse, garnir de la préparation et couvrir de la seconde abaisse.","Souder et pincer les bords, faire des incisions sur le dessus et dorer à l’œuf.","Cuire 35 à 40 minutes jusqu’à ce que la croûte soit dorée et servir avec des cornichons."],"photo":{"file":"File:Paté au saumon.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Pat%C3%A9_au_saumon.jpg/1280px-Pat%C3%A9_au_saumon.jpg","page":"https://commons.wikimedia.org/wiki/File:Pat%C3%A9_au_saumon.jpg","author":"StevenBjerke97","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"oreilles-de-crisse","country":"CA","place":"ca-quebec","original":"Oreilles de crisse","title":"Oreilles de crisse (grillades de lard croustillantes)","en":"Oreilles de crisse (crispy fried pork rinds)","es":"Oreilles de crisse (cortezas de cerdo crujientes)","desc":"Tranches de lard salé dessalées puis rôties lentement jusqu’à ce qu’elles gonflent et deviennent croustillantes, servies en entrée ou en accompagnement dans les repas de cabane à sucre, souvent arrosées de sirop d’érable.","cat":"Accompagnement","diff":"easy","prep":15,"cook":60,"serv":6,"reference":"https://fr.wikipedia.org/wiki/Oreilles_de_crisse","ing":[["Lard salé avec couenne",500,"g","en tranches fines"],["Eau",2,"l","pour dessaler"],["Sirop d’érable",60,"ml","pour servir"]],"steps":["Faire tremper le lard salé 1 heure dans l’eau froide pour le dessaler, puis l’égoutter.","Le blanchir 10 minutes dans l’eau bouillante, l’égoutter et le sécher soigneusement.","Disposer les tranches sur une plaque à rebord, sans les superposer.","Rôtir au four à 180 °C 45 minutes à 1 heure, en les retournant et en vidant le gras, jusqu’à ce qu’elles soient gonflées et bien croustillantes.","Égoutter sur du papier absorbant et servir chaudes avec du sirop d’érable."],"photo":{"file":"File:Oreilles de Crisse 2.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Oreilles_de_Crisse_2.jpg/1280px-Oreilles_de_Crisse_2.jpg","page":"https://commons.wikimedia.org/wiki/File:Oreilles_de_Crisse_2.jpg","author":"Abxzo","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"gibelotte-sorel","country":"CA","place":{"slug":"ca-sorel-tracy","name":"Sorel-Tracy","type":"city","lat":46.042,"lng":-73.113,"summary":"Ville de la Montérégie au confluent du Richelieu et du Saint-Laurent, près des îles de Sorel, patrie de la gibelotte."},"original":"Gibelotte des Îles de Sorel","title":"Gibelotte des îles de Sorel (ragoût de barbotte et de légumes)","en":"Sorel gibelotte (catfish and vegetable stew)","es":"Gibelotte de Sorel (guiso de bagre y verduras)","desc":"Ragoût de légumes à la tomate (pommes de terre, carottes, haricots, maïs, petits pois) dans lequel on dépose des filets de barbotte frits, la spécialité des îles de Sorel célébrée chaque été par le Festival de la gibelotte.","cat":"Plat principal","diff":"medium","prep":40,"cook":60,"serv":6,"reference":"https://fr.wikipedia.org/wiki/Gibelotte_(Sorel)","ing":[["Filets de barbotte (ou de perchaude)",1,"kg",null],["Farine",80,"g","pour fariner"],["Beurre",60,"g",null],["Oignons",2,null,"hachés"],["Pommes de terre",4,null,"en cubes"],["Carottes",3,null,"en rondelles"],["Haricots jaunes et verts",200,"g","en tronçons"],["Maïs en grains",200,"g",null],["Petits pois",200,"g",null],["Tomates en dés",800,"g",null],["Soupe aux tomates condensée",1,"boîte",null],["Bouillon de poulet",1,"l",null],["Sarriette",1,"c. à thé",null],["Sel et poivre",1,"c. à thé",null]],"steps":["Faire fondre les oignons dans la moitié du beurre dans une grande marmite.","Ajouter pommes de terre, carottes, tomates, soupe aux tomates, bouillon et sarriette, et mijoter 30 minutes.","Ajouter haricots, maïs et petits pois et cuire encore 15 minutes, rectifier l’assaisonnement.","Saler et poivrer les filets de barbotte, les fariner et les frire dans le reste du beurre jusqu’à ce qu’ils soient dorés.","Servir le ragoût dans des bols et déposer les filets frits sur le dessus, avec du pain et du beurre."],"photo":{"file":"File:Gibelotte-Sorel.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/9/97/Gibelotte-Sorel.jpg","page":"https://commons.wikimedia.org/wiki/File:Gibelotte-Sorel.jpg","author":"Frappier","license":"CC BY-SA 3.0","licenseUrl":"http://creativecommons.org/licenses/by-sa/3.0/","source":"Wikimedia Commons"}},{"slug":"hot-dog-steame","country":"CA","place":"ca-montreal","original":"Hot-dog steamé","title":"Hot-dog steamé « all-dressed » (chien chaud vapeur montréalais)","en":"Montreal steamed hot dog","es":"Hot dog al vapor de Montreal","desc":"Saucisse cuite à la vapeur dans un pain moelleux lui aussi étuvé, garnie « all-dressed » de moutarde jaune, de relish, d’oignon haché et de chou en salade : le casse-croûte des stands et des restaurants de quartier de Montréal, servi avec des frites.","cat":"Street food","diff":"easy","prep":15,"cook":10,"serv":4,"reference":"https://fr.wikipedia.org/wiki/Hot-dog_steamé","ing":[["Saucisses à hot-dog",8,null,null],["Pains à hot-dog",8,null,null],["Chou vert",250,"g","finement émincé"],["Mayonnaise",2,"c. à soupe",null],["Vinaigre blanc",1,"c. à soupe",null],["Sucre",1,"c. à thé",null],["Oignon blanc",1,null,"haché fin"],["Moutarde jaune",4,"c. à soupe",null],["Relish verte",4,"c. à soupe",null],["Sel",1,"pincée",null]],"steps":["Mélanger le chou avec la mayonnaise, le vinaigre, le sucre et le sel et laisser reposer 30 minutes.","Cuire les saucisses 5 à 6 minutes à la vapeur au-dessus d’une eau frémissante.","Étuver les pains 1 minute à la vapeur, juste pour qu’ils soient chauds et très moelleux.","Placer une saucisse dans chaque pain, garnir de moutarde, de relish, d’oignon et de chou.","Servir aussitôt, avec des frites."],"photo":{"file":"File:Montreal steamie hotdog.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/d/df/Montreal_steamie_hotdog.jpg","page":"https://commons.wikimedia.org/wiki/File:Montreal_steamie_hotdog.jpg","author":"Mindme","license":"Public domain","licenseUrl":null,"source":"Wikimedia Commons"}},{"slug":"bouilli-quebecois","country":"CA","place":"ca-quebec","original":"Bouilli de légumes","title":"Bouilli québécois (bœuf, lard et légumes du jardin)","en":"Quebec boiled dinner","es":"Cocido de Quebec (bouilli)","desc":"Pièce de bœuf et lard salé mijotés lentement avec chou, carottes, navet, pommes de terre, oignons et haricots jaunes et verts, le grand plat des récoltes de la fin de l’été dans les familles québécoises.","cat":"Plat principal","diff":"easy","prep":30,"cook":210,"serv":8,"reference":"https://fr.wikipedia.org/wiki/Bouilli","ing":[["Pointe de poitrine ou palette de bœuf",1.5,"kg",null],["Lard salé",250,"g",null],["Chou vert",1,null,"en quartiers"],["Carottes",6,null,null],["Navet (rutabaga)",1,null,"en gros cubes"],["Pommes de terre",8,null,null],["Oignons",3,null,null],["Haricots jaunes et verts",400,"g",null],["Laurier",2,"feuilles",null],["Sarriette",1,"c. à thé",null],["Sel et poivre",2,"c. à thé",null]],"steps":["Déposer le bœuf et le lard salé dans une grande marmite, couvrir d’eau froide et porter à ébullition en écumant.","Ajouter oignons, laurier, sarriette, poivre et cuire 2 heures à petit frémissement.","Ajouter le navet et les carottes et cuire 30 minutes.","Ajouter les pommes de terre et le chou et cuire encore 25 minutes.","Ajouter les haricots pour les 10 dernières minutes et rectifier le sel.","Servir la viande tranchée entourée des légumes, avec un peu de bouillon, de la moutarde et du ketchup maison."],"photo":{"file":"File:Bouilli quebecois.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Bouilli_quebecois.jpg/1280px-Bouilli_quebecois.jpg","page":"https://commons.wikimedia.org/wiki/File:Bouilli_quebecois.jpg","author":"Marc-Lautenbacher","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}}]$batch$::jsonb);
