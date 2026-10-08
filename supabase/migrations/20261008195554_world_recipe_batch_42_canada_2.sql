-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 4 recettes, 2 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"bc-roll-vancouver","country":"CA","place":"ca-vancouver","original":"BC roll","title":"BC roll de Vancouver (maki à la peau de saumon grillée et sauce sucrée)","en":"Vancouver BC roll (grilled salmon skin maki)","es":"BC roll de Vancouver (maki de piel de salmón a la parrilla)","desc":"Maki inventé à Vancouver dans les années 1970 par le chef Hidekazu Tojo : peau de saumon grillée et croustillante, concombre et sauce sucrée-salée, roulés dans du riz à sushi, parfois avec œufs de poisson volant.","cat":"Plat principal","diff":"medium","prep":40,"cook":25,"serv":4,"reference":"https://en.wikipedia.org/wiki/B.C._roll","ing":[["Riz à sushi",300,"g",null],["Eau",330,"ml",null],["Vinaigre de riz",60,"ml",null],["Sucre",1,"c. à soupe",null],["Sel",1,"c. à thé",null],["Peau de saumon",200,"g","écaillée"],["Feuilles de nori",4,null,null],["Concombre",1,null,"en bâtonnets"],["Sauce soja",3,"c. à soupe",null],["Mirin",2,"c. à soupe",null],["Graines de sésame",1,"c. à soupe","grillées"],["Œufs de poisson volant (tobiko)",40,"g","facultatif"]],"steps":["Rincer le riz jusqu’à ce que l’eau soit claire, le cuire avec l’eau, puis l’assaisonner du vinaigre mélangé au sucre et au sel; laisser tiédir.","Griller la peau de saumon au four à 220 °C ou à la poêle jusqu’à ce qu’elle soit très croustillante, puis la couper en lanières.","Faire réduire la sauce soja et le mirin 2 minutes pour obtenir une sauce sirupeuse.","Étaler le riz sur une feuille de nori, parsemer de sésame, puis retourner la feuille sur une natte recouverte de pellicule plastique.","Disposer la peau de saumon et le concombre, arroser d’un peu de sauce et rouler fermement.","Rouler dans le tobiko si désiré, couper en 8 morceaux et servir avec le reste de la sauce."],"photo":{"file":"File:BC Roll.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/0/07/BC_Roll.jpg","page":"https://commons.wikimedia.org/wiki/File:BC_Roll.jpg","author":"Underbar dk","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0"}},{"slug":"japadog-terimayo-vancouver","country":"CA","place":"ca-vancouver","original":"Japadog terimayo","title":"Hot-dog terimayo à la japonaise (style Japadog de Vancouver)","en":"Vancouver terimayo hot dog (Japadog style)","es":"Perrito terimayo al estilo japonés (Japadog de Vancouver)","desc":"Le hot-dog de rue de Vancouver revisité à la japonaise depuis 2005 : saucisse grillée nappée de sauce teriyaki et de mayonnaise japonaise, couverte de fines lanières d’algue nori.","cat":"Street food","diff":"easy","prep":10,"cook":10,"serv":4,"reference":"https://en.wikipedia.org/wiki/Japadog","ing":[["Saucisses de porc ou de bœuf",4,null,null],["Pains à hot-dog",4,null,null],["Sauce soja",3,"c. à soupe","pour la sauce teriyaki"],["Mirin",2,"c. à soupe","pour la sauce teriyaki"],["Sucre",1,"c. à soupe","pour la sauce teriyaki"],["Mayonnaise japonaise",4,"c. à soupe",null],["Oignon",0.5,null,"en fines lamelles, facultatif"],["Feuille de nori",1,null,"en très fines lanières"]],"steps":["Faire réduire la sauce soja, le mirin et le sucre 2 à 3 minutes jusqu’à ce que la sauce teriyaki nappe la cuillère.","Griller les saucisses sur le barbecue ou dans une poêle en les badigeonnant d’un peu de sauce.","Réchauffer les pains et y déposer les saucisses, avec l’oignon si désiré.","Arroser en zigzag de sauce teriyaki puis de mayonnaise japonaise.","Couvrir de lanières de nori juste avant de servir pour qu’elles restent croustillantes."],"photo":{"file":"File:Japadog - Terimayo (2696843021) (2).jpg","url":"https://upload.wikimedia.org/wikipedia/commons/8/8f/Japadog_-_Terimayo_%282696843021%29_%282%29.jpg","page":"https://commons.wikimedia.org/wiki/File:Japadog_-_Terimayo_(2696843021)_(2).jpg","author":"Dan from Vancouver, Canada","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0"}},{"slug":"goldeye-fume-winnipeg","country":"CA","place":{"slug":"ca-winnipeg","name":"Winnipeg","type":"city","lat":49.8951,"lng":-97.1384,"summary":"Capitale du Manitoba, célèbre pour le goldeye fumé du lac Winnipeg."},"original":"Winnipeg goldeye","title":"Goldeye fumé de Winnipeg (laquaiche aux yeux d’or saumurée et fumée au chêne)","en":"Winnipeg smoked goldeye","es":"Goldeye ahumado de Winnipeg","desc":"Spécialité du Manitoba : la laquaiche aux yeux d’or du lac Winnipeg, saumurée puis fumée à chaud au bois de chêne jusqu’à prendre une robe cuivrée, servie entière en entrée ou au déjeuner.","cat":"Poisson","diff":"medium","prep":30,"cook":120,"serv":4,"reference":"https://en.wikipedia.org/wiki/Goldeye","ing":[["Goldeyes entiers (laquaiches aux yeux d’or)",4,null,"vidés, tête conservée"],["Eau",2,"l","pour la saumure"],["Gros sel",150,"g","pour la saumure"],["Cassonade",75,"g","pour la saumure"],["Feuilles de laurier",2,null,null],["Copeaux de chêne",500,"g","trempés 30 minutes"],["Citron",1,null,"pour servir"]],"steps":["Dissoudre le sel et la cassonade dans l’eau avec le laurier, refroidir, puis y plonger les poissons 4 à 6 heures au réfrigérateur.","Rincer les poissons, les éponger et les laisser sécher 1 heure à l’air sur une grille jusqu’à ce que la peau soit collante.","Préparer un fumoir à 80–90 °C avec les copeaux de chêne.","Fumer les goldeyes 1 h 30 à 2 heures, jusqu’à ce que la chair se détache facilement et que la peau soit dorée cuivrée.","Servir tiède ou froid, entier, avec des quartiers de citron et du pain de seigle."],"photo":{"file":"File:Smoked goldeye.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/3/3d/Smoked_goldeye.jpg","page":"https://commons.wikimedia.org/wiki/File:Smoked_goldeye.jpg","author":"Mzajac","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0"}},{"slug":"souper-homard-ile-du-prince-edouard","country":"CA","place":{"slug":"ca-ile-du-prince-edouard","name":"Île-du-Prince-Édouard","type":"island","lat":46.25,"lng":-63.13,"summary":"Province insulaire du golfe du Saint-Laurent, réputée pour ses soupers de homard, ses moules et ses huîtres de Malpeque."},"original":"Lobster supper","title":"Homard bouilli des soupers de homard de l’Île-du-Prince-Édouard","en":"Prince Edward Island lobster supper (boiled lobster)","es":"Langosta hervida de las cenas de langosta de la Isla del Príncipe Eduardo","desc":"Tradition des salles paroissiales et des quais de l’Île-du-Prince-Édouard depuis les années 1950 : homard entier bouilli à l’eau de mer, servi avec beurre fondu, salade de chou, pommes de terre et petits pains.","cat":"Fruits de mer","diff":"easy","prep":15,"cook":20,"serv":4,"reference":"https://en.wikipedia.org/wiki/Canadian_cuisine","ing":[["Homards vivants",4,null,"de 600 à 700 g chacun"],["Eau de mer ou eau très salée",6,"l","30 g de sel par litre"],["Beurre",150,"g","fondu, pour servir"],["Citrons",2,null,"en quartiers"],["Pommes de terre nouvelles",800,"g","bouillies, pour servir"],["Salade de chou crémeuse",400,"g","pour servir"]],"steps":["Porter à grande ébullition une grande marmite d’eau de mer ou d’eau très salée.","Plonger les homards la tête la première, couvrir et compter 12 à 14 minutes après la reprise de l’ébullition pour des homards de 600 à 700 g.","Les homards sont cuits quand ils sont rouge vif et qu’une antenne se détache facilement.","Égoutter et laisser reposer 2 minutes, puis fendre les pinces et la queue.","Servir aussitôt avec le beurre fondu, les quartiers de citron, les pommes de terre et la salade de chou."],"photo":{"file":"File:Fisherman's Wharf Lobster Supper, North Rustico (471173) (24977047075).jpg","url":"https://upload.wikimedia.org/wikipedia/commons/e/e4/Fisherman%27s_Wharf_Lobster_Supper%2C_North_Rustico_%28471173%29_%2824977047075%29.jpg","page":"https://commons.wikimedia.org/wiki/File:Fisherman%27s_Wharf_Lobster_Supper,_North_Rustico_(471173)_(24977047075).jpg","author":"Robert Linsdell from St. Andrews, Canada","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0"}}]$batch$::jsonb);
