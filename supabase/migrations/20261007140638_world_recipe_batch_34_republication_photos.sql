-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 4 recettes, 0 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"fah-fah-djiboutien","country":"DJ","original":"Fah-fah","title":"Fah-fah djiboutien (soupe épicée de chevreau)","en":"Djiboutian fah-fah (spicy goat soup)","es":"Fah-fah yibutiano (sopa picante de cabrito)","desc":"Soupe de chevreau ou d’agneau aux légumes, piment vert et coriandre, servie avec du pain ou du lahoh.","cat":"Soupe","diff":"easy","prep":20,"cook":90,"serv":6,"ing":[["Chevreau ou agneau",800,"g","en morceaux"],["Pommes de terre",3,null,"en cubes"],["Carottes",2,null,"en rondelles"],["Chou",0.25,null,"émincé"],["Oignon",1,null,null],["Piment vert",2,null,null],["Coriandre fraîche",1,"bouquet",null],["Ail",4,"gousses",null],["Sel",1.5,"c. à thé",null]],"steps":["Couvrir la viande de 2,5 litres d’eau, porter à ébullition et écumer.","Mixer oignon, ail, piment et la moitié de la coriandre; ajouter au bouillon.","Mijoter 1 heure.","Ajouter les pommes de terre, les carottes et le chou; cuire 25 minutes.","Saler, parsemer du reste de coriandre et servir."],"photo":{"file":"File:Fahfah.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Fahfah.jpg/1280px-Fahfah.jpg","page":"https://commons.wikimedia.org/wiki/File:Fahfah.jpg","author":"U.S. Department of Agriculture","license":"Public domain","licenseUrl":null,"source":"Wikimedia Commons"}},{"slug":"muriwo-une-dovi","country":"ZW","original":"Muriwo une dovi","title":"Muriwo une dovi zimbabwéen (légumes verts au beurre de cacahuète)","en":"Zimbabwean muriwo une dovi (greens with peanut butter)","es":"Muriwo une dovi zimbabuense (verduras con mantequilla de cacahuete)","desc":"Feuilles de chou ou de rape cuites avec tomate et oignon puis liées au beurre de cacahuète (dovi), servies avec la sadza.","cat":"Accompagnement","diff":"easy","prep":10,"cook":20,"serv":4,"ing":[["Chou vert ou feuilles de rape",500,"g","émincés"],["Beurre de cacahuète",4,"c. à soupe",null],["Oignon",1,null,"haché"],["Tomates",2,null,"en dés"],["Huile",1,"c. à soupe",null],["Sel",1,"c. à thé",null]],"steps":["Faire revenir l’oignon dans l’huile, puis les tomates 5 minutes.","Ajouter les légumes verts et un peu d’eau; cuire 8 minutes.","Délayer le beurre de cacahuète dans un peu d’eau chaude.","L’incorporer et cuire 5 minutes en remuant.","Saler et servir avec la sadza."],"photo":{"file":"File:White sadza and tsunga with dovi.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/4/46/White_sadza_and_tsunga_with_dovi.jpg","page":"https://commons.wikimedia.org/wiki/File:White_sadza_and_tsunga_with_dovi.jpg","author":"Shark2025","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"sapasui","country":"WS","original":"Sapasui","title":"Sapasui samoan (vermicelles sautés au bœuf et soja)","en":"Samoan sapasui (chop suey)","es":"Sapasui samoano (fideos salteados con ternera)","desc":"Version samoane du chop suey : vermicelles de haricot mungo sautés avec bœuf ou poulet, gingembre et sauce soja, incontournable des fêtes.","cat":"Plat principal","diff":"easy","prep":20,"cook":25,"serv":6,"ing":[["Vermicelles de haricot mungo",250,"g","trempés"],["Bœuf ou poulet",500,"g","en lanières"],["Oignon",1,null,"émincé"],["Gingembre",20,"g","râpé"],["Ail",3,"gousses",null],["Sauce soja",100,"ml",null],["Carottes et chou",300,"g","en julienne"],["Huile",3,"c. à soupe",null]],"steps":["Faire revenir oignon, ail et gingembre dans l’huile.","Ajouter la viande et la saisir.","Ajouter les légumes et la moitié de la sauce soja.","Ajouter les vermicelles égouttés et le reste de sauce avec un peu d’eau.","Sauter jusqu’à absorption et servir."],"photo":{"file":"File:Pisupo and supoketi.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Pisupo_and_supoketi.jpg/1280px-Pisupo_and_supoketi.jpg","page":"https://commons.wikimedia.org/wiki/File:Pisupo_and_supoketi.jpg","author":"Wyldephang","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"potato-greens-liberia","country":"LR","original":"Potato greens","title":"Potato greens libériennes (feuilles de patate douce en sauce)","en":"Liberian potato greens","es":"Hojas de boniato liberianas en salsa","desc":"Feuilles de patate douce finement émincées cuites avec viande, poisson séché et huile de palme, accompagnées de riz.","cat":"Plat principal","diff":"easy","prep":30,"cook":60,"serv":6,"ing":[["Feuilles de patate douce ou épinards",800,"g","très finement émincées"],["Poulet ou bœuf",500,"g","en morceaux"],["Poisson séché",150,"g",null],["Huile de palme ou végétale",150,"ml",null],["Oignon",1,null,"haché"],["Piment",1,null,null],["Cube de bouillon",1,null,null],["Sel",1,"c. à thé",null]],"steps":["Faire revenir la viande et l’oignon dans l’huile.","Ajouter 500 ml d’eau et le bouillon; cuire 25 minutes.","Ajouter le poisson séché et les feuilles.","Cuire 20 minutes en remuant jusqu’à ce que les feuilles soient fondantes.","Saler, ajouter le piment et servir avec du riz."],"photo":{"file":"File:Liberia sweet potato green.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/7/7d/Liberia_sweet_potato_green.jpg","page":"https://commons.wikimedia.org/wiki/File:Liberia_sweet_potato_green.jpg","author":"Antoshananarivo","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}}]$batch$::jsonb);
-- Ces quatre recettes avaient été archivées faute de photo exacte; elles ont désormais une photo vérifiée.
update public.recipes r
  set status = 'published', updated_at = now()
  where r.slug in ('fah-fah-djiboutien', 'potato-greens-liberia', 'sapasui', 'muriwo-une-dovi')
    and r.status = 'archived'
    and exists (select 1 from public.recipe_images i where i.recipe_id = r.id and i.status = 'ready');
