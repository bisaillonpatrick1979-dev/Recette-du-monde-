-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 3 recettes, 0 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"jambon-a-lerable","country":"CA","place":"ca-quebec","original":"Jambon à l'érable","title":"Jambon à l’érable (jambon glacé au sirop d’érable et à la moutarde)","en":"Quebec maple-glazed ham","es":"Jamón glaseado con jarabe de arce","desc":"Jambon fumé cuit lentement puis badigeonné à plusieurs reprises d’un glaçage au sirop d’érable, à la moutarde et au clou de girofle jusqu’à ce qu’il soit laqué et doré : la pièce centrale des repas de Pâques et des cabanes à sucre au Québec.","cat":"Plat principal","diff":"easy","prep":20,"cook":180,"serv":10,"reference":"https://fr.wikipedia.org/wiki/Cabane_à_sucre","ing":[["Jambon fumé avec os (ou demi-jambon)",3,"kg",null],["Sirop d’érable",250,"ml",null],["Cassonade",60,"g",null],["Moutarde de Dijon",3,"c. à soupe",null],["Clous de girofle entiers",20,null,null],["Bière blonde ou cidre",341,"ml",null],["Oignon",1,null,"en quartiers"],["Poivre noir",1,"c. à thé",null]],"steps":["Préchauffer le four à 160 °C. Placer le jambon dans une rôtissoire avec l’oignon et la bière, couvrir d’aluminium.","Cuire 2 heures (environ 20 minutes par 500 g), en arrosant de temps en temps.","Pendant ce temps, faire réduire le sirop d’érable avec la cassonade, la moutarde et le poivre 5 minutes jusqu’à consistance sirupeuse.","Retirer la couenne en laissant une fine couche de gras, quadriller le gras au couteau et piquer un clou de girofle à chaque intersection.","Monter le four à 200 °C, badigeonner le jambon de glaçage et cuire 45 minutes à découvert en badigeonnant toutes les 15 minutes, jusqu’à ce qu’il soit laqué.","Laisser reposer 15 minutes, trancher et servir avec le jus de cuisson, des fèves au lard et des pommes de terre."],"photo":{"file":"File:Glazed and sliced ham.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Glazed_and_sliced_ham.jpg/1280px-Glazed_and_sliced_ham.jpg","page":"https://commons.wikimedia.org/wiki/File:Glazed_and_sliced_ham.jpg","author":"Michael Coté from Austin, Texas, Texas","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0","source":"Wikimedia Commons"}},{"slug":"beignes-de-grand-mere","country":"CA","place":"ca-quebec","original":"Beignes","title":"Beignes de grand-mère (beignets à l’ancienne à la crème sure)","en":"Quebec old-fashioned doughnuts","es":"Rosquillas caseras de Quebec","desc":"Beignets en couronne à pâte levée chimiquement, parfumés à la muscade et à la crème sure, frits jusqu’à ce que leur surface craquelle puis roulés dans le sucre : la gourmandise des Fêtes que les grands-mères québécoises préparaient par dizaines.","cat":"Dessert","diff":"medium","prep":40,"cook":30,"serv":24,"reference":"https://fr.wikipedia.org/wiki/Beigne","ing":[["Farine tout usage",500,"g",null],["Sucre",200,"g","dont 100 g pour l’enrobage"],["Œufs",2,null,null],["Crème sure",250,"ml",null],["Beurre fondu",30,"g",null],["Poudre à pâte",2,"c. à thé",null],["Bicarbonate de soude",1,"c. à thé",null],["Muscade râpée",1,"c. à thé",null],["Vanille",1,"c. à thé",null],["Sel",0.5,"c. à thé",null],["Huile ou graisse végétale",1.5,"l","pour la friture"]],"steps":["Fouetter les œufs avec 100 g de sucre jusqu’à ce qu’ils blanchissent, ajouter la crème sure, le beurre fondu et la vanille.","Mélanger la farine, la poudre à pâte, le bicarbonate, la muscade et le sel, puis les incorporer à la cuillère jusqu’à une pâte molle. Réfrigérer 1 heure.","Abaisser la pâte farinée à 1 cm et découper des couronnes avec un emporte-pièce à beignes.","Chauffer l’huile à 180 °C et frire 3 ou 4 beignes à la fois, environ 1 minute par face, jusqu’à ce qu’ils soient dorés et craquelés.","Égoutter sur du papier absorbant puis rouler les beignes encore tièdes dans le reste du sucre.","Frire aussi les « trous » de beignes et conserver en boîte hermétique."],"photo":{"file":"File:Old fashioned doughnut.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/6/68/Old_fashioned_doughnut.jpg","page":"https://commons.wikimedia.org/wiki/File:Old_fashioned_doughnut.jpg","author":"BrokenSphere","license":"CC BY 3.0","licenseUrl":"https://creativecommons.org/licenses/by/3.0","source":"Wikimedia Commons"}},{"slug":"fromage-en-grains-maison","country":"CA","place":"ca-quebec","original":"Fromage en grains","title":"Fromage en grains maison (le fromage « qui fait couic »)","en":"Homemade Quebec cheese curds","es":"Queso en granos casero de Quebec","desc":"Caillé de cheddar frais égoutté, découpé en morceaux et salé, mangé le jour même pendant qu’il fait encore « couic » sous la dent : la collation des fromageries du Québec et l’ingrédient indispensable de la poutine.","cat":"Collation","diff":"hard","prep":60,"cook":120,"serv":6,"reference":"https://fr.wikipedia.org/wiki/Fromage_en_grains","ing":[["Lait entier non homogénéisé",4,"l",null],["Ferment mésophile",0.25,"c. à thé",null],["Présure liquide",1,"c. à thé","diluée dans 60 ml d’eau froide non chlorée"],["Chlorure de calcium",0.5,"c. à thé","si lait pasteurisé"],["Sel fin non iodé",1,"c. à soupe",null]],"steps":["Chauffer le lait à 32 °C, ajouter le chlorure de calcium puis le ferment, mélanger et laisser mûrir 45 minutes à 32 °C.","Ajouter la présure diluée, mélanger 1 minute et laisser coaguler 40 minutes sans bouger, jusqu’à une cassure nette.","Couper le caillé en cubes de 1 cm, laisser reposer 5 minutes, puis chauffer très lentement jusqu’à 38 °C en 30 minutes en remuant doucement.","Maintenir 30 minutes à 38 °C, puis égoutter le caillé et le presser en bloc dans une passoire tiède pendant 1 heure, en le retournant toutes les 15 minutes (cheddarisation).","Couper le bloc en lanières de la taille d’un doigt, puis en grains, et les saler en mélangeant bien.","Manger à température ambiante le jour même, nature ou sur des frites avec une sauce brune."],"photo":{"file":"File:Cheese curds 2.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Cheese_curds_2.jpg/1280px-Cheese_curds_2.jpg","page":"https://commons.wikimedia.org/wiki/File:Cheese_curds_2.jpg","author":"TShilo12 at English Wikipedia","license":"CC BY-SA 3.0","licenseUrl":"http://creativecommons.org/licenses/by-sa/3.0/","source":"Wikimedia Commons"}}]$batch$::jsonb);
