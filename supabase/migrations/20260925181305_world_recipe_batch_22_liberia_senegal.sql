-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 6 recettes, 0 nouveaux lieux.
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

    insert into public.recipes (id, author_id, title, original_title, slug, description, excerpt, source_language, country_code, region,
      category, authenticity, status, difficulty, prep_minutes, cook_minutes, servings, published_at, primary_place_id,
      is_editorial, is_borderless, source_name, source_url, source_notes)
    values (rid, author, r->>'title', r->>'original', r->>'slug', r->>'desc', r->>'desc', 'fr', r->>'country', region_text,
      r->>'cat', coalesce(r->>'auth', 'adapted')::public.recipe_authenticity, 'published', (r->>'diff')::public.recipe_difficulty,
      (r->>'prep')::int, (r->>'cook')::int, (r->>'serv')::numeric, now(), place,
      true, false, source_name, ph->>'page',
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
      values (rid, 'external_licensed', 'ready', ph->>'url', r->>'title', 'Wikimedia Commons', ph->>'page',
        nullif(ph->>'author', ''), ph->>'license', nullif(ph->>'licenseUrl', ''),
        'Photo : ' || coalesce(nullif(ph->>'author', ''), 'auteur inconnu') || ' · ' || (ph->>'license') || ' · Wikimedia Commons',
        true, true, 'Photo Wikimedia Commons vérifiée : le fichier représente ce plat.');
    end if;

    total := total + 1;
  end loop;
  return total;
end;
$fn$;
select pg_temp.spoontrotter_import($batch$[{"slug":"cassava-leaf-liberia","country":"LR","original":"Cassava leaf","title":"Cassava leaf libérien (feuilles de manioc à l’huile de palme)","en":"Liberian cassava leaf stew","es":"Hojas de yuca liberianas (guiso con aceite de palma)","desc":"Feuilles de manioc pilées mijotées avec viande, poisson fumé, huile de palme et piment, plat national servi sur du riz au Liberia.","cat":"Plat principal","diff":"medium","prep":30,"cook":120,"serv":6,"ing":[["Feuilles de manioc pilées",800,"g","fraîches ou surgelées"],["Poulet ou bœuf",600,"g","en morceaux"],["Poisson fumé",200,"g","émietté"],["Huile de palme",200,"ml",null],["Oignons",2,null,"hachés"],["Piment scotch bonnet",2,null,null],["Cube de bouillon",1,null,null],["Sel",1,"c. à thé",null]],"steps":["Cuire la viande avec les oignons et le bouillon 30 minutes.","Ajouter les feuilles de manioc et 1 litre d’eau; cuire 1 heure à couvert.","Ajouter le poisson fumé, l’huile de palme et les piments.","Mijoter 30 minutes jusqu’à ce que l’huile remonte.","Saler et servir avec du riz blanc."],"photo":null},{"slug":"potato-greens-liberia","country":"LR","original":"Potato greens","title":"Potato greens libériennes (feuilles de patate douce en sauce)","en":"Liberian potato greens","es":"Hojas de boniato liberianas en salsa","desc":"Feuilles de patate douce finement émincées cuites avec viande, poisson séché et huile de palme, accompagnées de riz.","cat":"Plat principal","diff":"easy","prep":30,"cook":60,"serv":6,"ing":[["Feuilles de patate douce ou épinards",800,"g","très finement émincées"],["Poulet ou bœuf",500,"g","en morceaux"],["Poisson séché",150,"g",null],["Huile de palme ou végétale",150,"ml",null],["Oignon",1,null,"haché"],["Piment",1,null,null],["Cube de bouillon",1,null,null],["Sel",1,"c. à thé",null]],"steps":["Faire revenir la viande et l’oignon dans l’huile.","Ajouter 500 ml d’eau et le bouillon; cuire 25 minutes.","Ajouter le poisson séché et les feuilles.","Cuire 20 minutes en remuant jusqu’à ce que les feuilles soient fondantes.","Saler, ajouter le piment et servir avec du riz."],"photo":null},{"slug":"rice-bread-liberia","country":"LR","original":"Rice bread","title":"Rice bread libérien (gâteau de riz à la banane)","en":"Liberian rice bread (banana rice cake)","es":"Pan de arroz liberiano (bizcocho de arroz y plátano)","desc":"Gâteau moelleux à la crème de riz, bananes mûres et muscade, pâtisserie familiale du Liberia.","cat":"Dessert","diff":"easy","prep":15,"cook":45,"serv":8,"ing":[["Crème de riz ou farine de riz",250,"g",null],["Bananes très mûres",4,null,"écrasées"],["Sucre",150,"g",null],["Œufs",2,null,null],["Lait",200,"ml",null],["Huile",100,"ml",null],["Levure chimique",2,"c. à thé",null],["Muscade",0.5,"c. à thé",null],["Sel",1,"pincée",null]],"steps":["Préchauffer le four à 180 °C.","Mélanger bananes, sucre, œufs, lait et huile.","Incorporer farine de riz, levure, muscade et sel.","Verser dans un moule huilé.","Cuire 40 à 45 minutes jusqu’à ce qu’une lame ressorte sèche."],"photo":null},{"slug":"mafe-senegalais","country":"SN","original":"Mafé","title":"Mafé sénégalais (ragoût de viande à la pâte d’arachide)","en":"Senegalese mafé (peanut stew)","es":"Mafé senegalés (guiso de cacahuete)","desc":"Viande mijotée dans une sauce tomate à la pâte d’arachide avec patate douce, carotte et chou, servie sur du riz.","cat":"Ragoût","diff":"easy","prep":20,"cook":75,"serv":6,"ing":[["Bœuf ou agneau",800,"g","en morceaux"],["Pâte d’arachide",200,"g",null],["Concentré de tomate",3,"c. à soupe",null],["Oignons",2,null,"hachés"],["Ail",3,"gousses",null],["Patate douce",1,null,"en morceaux"],["Carottes",2,null,null],["Chou",0.25,null,null],["Piment",1,null,null],["Huile",3,"c. à soupe",null],["Sel",1.5,"c. à thé",null]],"steps":["Faire dorer la viande dans l’huile avec les oignons et l’ail.","Ajouter le concentré de tomate et cuire 5 minutes.","Délayer la pâte d’arachide dans 1 litre d’eau chaude et verser.","Mijoter 40 minutes en remuant, puis ajouter les légumes et le piment.","Cuire 25 minutes, saler et servir avec du riz."],"photo":null},{"slug":"thiakry","country":"SN","original":"Thiakry","title":"Thiakry sénégalais (couscous de mil au lait caillé)","en":"Senegalese thiakry (millet couscous with sweetened yogurt)","es":"Thiakry senegalés (cuscús de mijo con yogur)","desc":"Dessert frais de couscous de mil (arraw) mélangé à du lait caillé sucré, vanille et muscade, parfois avec raisins secs.","cat":"Dessert","diff":"easy","prep":15,"cook":20,"serv":6,"ing":[["Couscous de mil (arraw) ou couscous fin",250,"g",null],["Lait caillé ou yaourt nature",500,"g",null],["Lait concentré sucré",150,"ml",null],["Sucre",60,"g",null],["Vanille",1,"c. à thé",null],["Muscade",0.5,"c. à thé",null],["Raisins secs",50,"g","facultatif"]],"steps":["Cuire le couscous de mil à la vapeur 20 minutes, puis l’égrener et laisser refroidir.","Fouetter lait caillé, lait concentré, sucre, vanille et muscade.","Incorporer le couscous et les raisins.","Réfrigérer au moins 1 heure.","Servir bien frais."],"photo":null},{"slug":"pastels-senegalais","country":"SN","original":"Pastels","title":"Pastels sénégalais (chaussons frits au poisson et sauce tomate pimentée)","en":"Senegalese pastels (fish-filled fried pastries)","es":"Pastels senegaleses (empanadillas fritas de pescado)","desc":"Petits chaussons frits farcis de poisson émietté au persil et piment, servis avec une sauce tomate relevée, en-cas des fêtes à Dakar.","cat":"Entrée","diff":"medium","prep":45,"cook":25,"serv":8,"ing":[["Farine",400,"g",null],["Beurre",60,"g",null],["Eau tiède",180,"ml",null],["Poisson blanc cuit",400,"g","émietté"],["Oignon",1,null,"haché"],["Persil et ail",1,"portion","pilés"],["Piment",1,null,null],["Huile",750,"ml","pour la friture"],["Sauce tomate pimentée",200,"ml","pour servir"],["Sel",1.5,"c. à thé",null]],"steps":["Sabler farine, beurre et sel; ajouter l’eau et pétrir; reposer 30 minutes.","Faire revenir l’oignon, ajouter poisson, persil, ail, piment et sel.","Étaler la pâte finement et découper des disques de 8 cm.","Garnir, replier et souder les bords à la fourchette.","Frire jusqu’à ce qu’ils soient dorés et servir avec la sauce tomate."],"photo":null}]$batch$::jsonb);
