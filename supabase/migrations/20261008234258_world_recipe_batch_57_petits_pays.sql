-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 4 recettes, 1 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"cracked-conch-bahamas","country":"BS","place":{"slug":"bs-grand-bahama","name":"Grand Bahama","type":"island","lat":26.65,"lng":-78.35,"summary":"Île du nord des Bahamas, aux restaurants de plage servant conque frite, peas n’ rice et bière Kalik."},"original":"Cracked conch","title":"Cracked conch (conque attendrie et frite)","en":"Bahamian cracked conch","es":"Caracol (conch) frito de Bahamas","desc":"Chair de lambi (strombe géant) attendrie au maillet, marinée au citron vert puis panée et frite jusqu’à être dorée et tendre, servie avec peas n’ rice, salade de chou et sauce piquante : le plat emblématique des Bahamas.","cat":"Plat principal","diff":"medium","prep":30,"cook":15,"serv":4,"reference":"https://en.wikipedia.org/wiki/Bahamian_cuisine","ing":[["Chair de conque (lambi) nettoyée",600,"g",null],["Citrons verts",3,null,"en jus"],["Œufs",2,null,"battus"],["Lait évaporé",60,"ml",null],["Farine",150,"g",null],["Chapelure de craquelins",100,"g",null],["Thym séché",1,"c. à thé",null],["Piment goat pepper ou habanero",1,null,"haché très fin, facultatif"],["Huile de friture",750,"ml",null],["Sel et poivre",1,"c. à thé",null],["Sauce piquante et quartiers de citron vert",1,null,"pour servir"]],"steps":["Couper la conque en escalopes de 1 cm et les attendrir longuement au maillet jusqu’à ce qu’elles soient très fines.","Les mariner 20 minutes dans le jus de citron vert avec le sel, le poivre, le thym et le piment.","Mélanger les œufs et le lait évaporé ; mélanger la farine et la chapelure de craquelins.","Passer chaque escalope dans l’œuf puis dans la panure en pressant.","Frire 2 à 3 minutes à 180 °C jusqu’à ce qu’elles soient dorées.","Servir avec peas n’ rice, salade de chou, citron vert et sauce piquante."],"photo":{"file":"File:GrandBahama ConchPeasRice.JPG","url":"https://upload.wikimedia.org/wikipedia/commons/c/c8/GrandBahama_ConchPeasRice.JPG","page":"https://commons.wikimedia.org/wiki/File:GrandBahama_ConchPeasRice.JPG","author":"Pasi Patokallio (téléversé par Jpatokal)","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"coca-de-llardons-andorra","country":"AD","original":"Coca de llardons","title":"Coca de llardons (galette sucrée aux grattons et pignons)","en":"Coca de llardons (crackling flatbread)","es":"Coca de llardons (coca de chicharrones)","desc":"Pâte fine sucrée parsemée de llardons (grattons de porc), de sucre et de pignons, cuite jusqu’à caraméliser : un gâteau de la tradition catalane partagée par l’Andorre, préparé pour le Dijous Gras avant le carême.","cat":"Dessert","diff":"medium","prep":30,"cook":25,"serv":8,"reference":"https://ca.wikipedia.org/wiki/Coca_de_llardons","ing":[["Pâte feuilletée ou pâte à pain levée",400,"g",null],["Llardons (grattons de porc)",150,"g","hachés grossièrement"],["Pignons de pin",60,"g",null],["Sucre",100,"g",null],["Anis ou moscatell",2,"c. à soupe",null],["Œuf",1,null,"battu"]],"steps":["Préchauffer le four à 190 °C.","Abaisser la pâte en un rectangle fin et la poser sur une plaque.","Badigeonner d’œuf battu et d’un peu d’anis.","Répartir les llardons hachés, puis les pignons, et couvrir généreusement de sucre.","Cuire 20 à 25 minutes jusqu’à ce que le sucre caramélise et que la pâte soit dorée.","Laisser tiédir et couper en carrés."],"photo":{"file":"File:Coca de llardons.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Coca_de_llardons.jpg/1280px-Coca_de_llardons.jpg","page":"https://commons.wikimedia.org/wiki/File:Coca_de_llardons.jpg","author":"Slastic","license":"Public domain","licenseUrl":null,"source":"Wikimedia Commons"}},{"slug":"crema-catalana-andorra","country":"AD","original":"Crema catalana","title":"Crema catalana (crème à la cannelle et au citron, sucre brûlé)","en":"Crema catalana","es":"Crema catalana","desc":"Crème cuite à la casserole, parfumée au zeste de citron et à la cannelle, refroidie en cassolettes de terre puis recouverte de sucre brûlé au fer ; le dessert de la Saint-Joseph dans les maisons catalanes et andorranes.","cat":"Dessert","diff":"easy","prep":15,"cook":20,"serv":6,"reference":"https://en.wikipedia.org/wiki/Crema_catalana","ing":[["Lait entier",1,"l",null],["Jaunes d’œufs",8,null,null],["Sucre",200,"g","dont 80 g pour caraméliser"],["Fécule de maïs",40,"g",null],["Zeste de citron",1,null,"en ruban"],["Bâton de cannelle",1,null,null]],"steps":["Infuser le lait avec le zeste de citron et la cannelle à frémissement, puis laisser reposer 15 minutes et filtrer.","Fouetter les jaunes avec 120 g de sucre et la fécule.","Verser le lait chaud en fouettant, remettre sur feu doux et remuer sans cesse jusqu’à épaississement, sans bouillir.","Répartir dans des cassolettes en terre et réfrigérer au moins 3 heures.","Au moment de servir, saupoudrer de sucre et le brûler au fer chaud ou au chalumeau jusqu’à une croûte ambrée."],"photo":{"file":"File:Crema Catalana (7 Portes).jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Crema_Catalana_%287_Portes%29.jpg/1280px-Crema_Catalana_%287_Portes%29.jpg","page":"https://commons.wikimedia.org/wiki/File:Crema_Catalana_(7_Portes).jpg","author":"Tamorlan","license":"CC BY 3.0","licenseUrl":"https://creativecommons.org/licenses/by/3.0","source":"Wikimedia Commons"}},{"slug":"kandu-kukulhu","country":"MV","original":"Kandu kukulhu","title":"Kandu kukulhu (curry de thon maldivien au lait de coco)","en":"Maldivian kandu kukulhu tuna curry","es":"Kandu kukulhu (curry de atún maldivo)","desc":"Morceaux de thon listao mijotés dans un curry au lait de coco, aux feuilles de curry, au piment et au curcuma, servi avec du riz, des roshi et un sambol d’oignon au citron vert : un plat du quotidien des îles Maldives.","cat":"Plat principal","diff":"medium","prep":20,"cook":30,"serv":4,"reference":"https://en.wikipedia.org/wiki/Maldivian_cuisine","ing":[["Thon frais (listao ou albacore)",600,"g","en cubes"],["Lait de coco",400,"ml",null],["Oignon",1,null,"émincé"],["Ail",3,"gousses",null],["Gingembre",15,"g","râpé"],["Feuilles de curry",12,null,null],["Piments verts",2,null,"fendus"],["Curcuma",1,"c. à thé",null],["Poudre de curry maldivien (ou de poisson)",2,"c. à soupe",null],["Citron vert",1,null,null],["Huile de coco",2,"c. à soupe",null],["Sel",1,"c. à thé",null],["Riz et roshi",1,null,"pour servir"]],"steps":["Frotter le thon de curcuma, de sel et de jus de citron vert.","Faire revenir l’oignon, l’ail, le gingembre et les feuilles de curry dans l’huile de coco.","Ajouter la poudre de curry et les piments et cuire 1 minute.","Verser le lait de coco, porter à frémissement 10 minutes.","Ajouter le thon et cuire 8 à 10 minutes à feu doux sans trop remuer.","Servir avec du riz, des roshi et un sambol d’oignon au citron vert."],"photo":{"file":"File:Maldivian dish - Kandu Kulkulhu 01.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Maldivian_dish_-_Kandu_Kulkulhu_01.jpg/1280px-Maldivian_dish_-_Kandu_Kulkulhu_01.jpg","page":"https://commons.wikimedia.org/wiki/File:Maldivian_dish_-_Kandu_Kulkulhu_01.jpg","author":"Satdeep Gill","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}}]$batch$::jsonb);
