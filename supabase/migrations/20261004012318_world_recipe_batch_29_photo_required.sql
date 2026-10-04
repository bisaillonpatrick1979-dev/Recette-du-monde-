insert into public.culinary_places (slug,name,country_code,place_type,latitude,longitude,default_zoom,summary)
values ('sy','Syrie','SY','country',35,38,5,'Cuisine syrienne, traditions culinaires du Levant.')
on conflict (slug) do nothing;

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
select pg_temp.spoontrotter_import($batch$[{"slug":"omurice-japonais","country":"JP","original":"Omurice (オムライス)","title":"Omurice japonais (omelette au riz sauté au poulet)","en":"Omurice (Japanese chicken rice omelette)","es":"Omurice (tortilla japonesa de arroz y pollo)","desc":"Un classique familial japonais : du riz sauté au poulet et au ketchup enveloppé dans une omelette. Version domestique à œufs entièrement cuits.","cat":"Plat principal","diff":"medium","prep":15,"cook":20,"serv":2,"reference":"https://japan-food.jetro.go.jp/en/recipe/125.html","ing":[["Riz cuit refroidi",300,"g",null],["Poulet désossé",150,"g","en petits dés"],["Oignon",1,null,"petit, haché"],["Petits pois",50,"g",null],["Ketchup",3,"c. à soupe",null],["Œufs",4,null,null],["Huile neutre",2,"c. à soupe",null],["Sel et poivre",null,null,"au goût"]],"steps":["Chauffer la moitié de l’huile. Faire revenir l’oignon 3 minutes, puis le poulet jusqu’à cuisson complète (74 °C au centre).","Ajouter les petits pois et le riz; faire sauter 3 minutes. Incorporer le ketchup, saler et poivrer. Réserver au chaud.","Battre 2 œufs. Huiler une petite poêle antiadhésive et y verser les œufs; cuire à feu moyen doux jusqu’à ce que la surface soit prise.","Déposer la moitié du riz sur une moitié de l’omelette, replier puis faire glisser dans une assiette. Répéter avec les œufs et le riz restants."],"photo":{"source":"Wikimedia Commons","file":"File:Omurice by chechecherry in Nanba, Osaka.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/3/3d/Omurice_by_chechecherry_in_Nanba%2C_Osaka.jpg","page":"https://commons.wikimedia.org/wiki/File:Omurice_by_chechecherry_in_Nanba,_Osaka.jpg","author":"紫貓物語 (chechecherry)","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0"}},{"slug":"spanakorizo-grec","country":"GR","original":"Spanakorizo (Σπανακόρυζο)","title":"Spanakorizo grec (riz aux épinards et citron)","en":"Spanakorizo (Greek spinach and lemon rice)","es":"Spanakorizo (arroz griego con espinacas y limón)","desc":"Riz mijoté aux épinards, à l’huile d’olive et aux herbes, servi avec du citron. Cette adaptation familiale reste rattachée à la Grèce sans lui attribuer une ville d’origine.","cat":"Accompagnement","diff":"easy","prep":15,"cook":25,"serv":4,"reference":"https://www.pbs.org/food/recipes/greek-spanakorizo","ing":[["Riz à grain moyen",200,"g",null],["Épinards frais",500,"g","lavés"],["Oignon",1,null,"haché"],["Huile d’olive",3,"c. à soupe",null],["Eau chaude",500,"ml","ajuster selon le riz"],["Aneth",2,"c. à soupe","haché"],["Jus de citron",2,"c. à soupe",null],["Sel et poivre",null,null,"au goût"]],"steps":["Faire fondre l’oignon dans l’huile d’olive pendant 5 minutes à feu moyen.","Ajouter progressivement les épinards et remuer jusqu’à ce qu’ils retombent.","Incorporer le riz rincé et l’eau chaude. Saler, couvrir et cuire à petit feu 18 à 22 minutes; ajouter un peu d’eau si nécessaire.","Quand le riz est tendre, ajouter l’aneth et le citron. Laisser reposer 5 minutes puis ajuster l’assaisonnement."],"photo":{"source":"Wikimedia Commons","file":"File:Spanakorizo.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/Spanakorizo.jpg/1280px-Spanakorizo.jpg","page":"https://commons.wikimedia.org/wiki/File:Spanakorizo.jpg","author":"KaterinaStrak","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0"}},{"slug":"strapatsada-grecque","country":"GR","original":"Strapatsada (Στραπατσάδα)","title":"Strapatsada grecque (œufs brouillés aux tomates)","en":"Strapatsada (Greek scrambled eggs with tomatoes)","es":"Strapatsada (huevos revueltos griegos con tomate)","desc":"Œufs brouillés dans des tomates mûres bien réduites à l’huile d’olive. La feta, ajoutée ici, reste facultative.","cat":"Petit-déjeuner","diff":"easy","prep":10,"cook":20,"serv":2,"reference":"https://www.argiro.gr/en/recipe/strapatsada/","ing":[["Tomates mûres",500,"g","râpées, peau retirée"],["Œufs",4,null,null],["Huile d’olive",2,"c. à soupe",null],["Feta",50,"g","facultative"],["Origan séché",0.5,"c. à thé",null],["Sel et poivre",null,null,"au goût"]],"steps":["Mettre les tomates râpées et l’huile dans une poêle. Cuire à découvert à feu moyen 12 à 15 minutes pour évaporer l’excès d’eau.","Battre les œufs, saler légèrement et poivrer. Réduire le feu puis verser les œufs dans les tomates.","Remuer doucement jusqu’à ce que les œufs soient pris sans devenir secs.","Ajouter l’origan et, si désiré, la feta émiettée. Servir aussitôt avec du pain."],"photo":{"source":"Wikimedia Commons","file":"File:Strapatsada.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Strapatsada.jpg/1280px-Strapatsada.jpg","page":"https://commons.wikimedia.org/wiki/File:Strapatsada.jpg","author":"Saintfevrier","license":"CC BY-SA 3.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/3.0"}},{"slug":"muhammara-syrienne","country":"SY","original":"Muhammara (محمرة)","title":"Muhammara syrienne (trempette de poivrons et noix)","en":"Muhammara (Syrian red pepper and walnut dip)","es":"Muhammara (crema siria de pimientos y nueces)","desc":"Trempette levantine associée à Alep en Syrie, mêlant poivrons rouges rôtis, noix et mélasse de grenade. Version adaptée à un four domestique.","cat":"Entrée","diff":"easy","prep":20,"cook":25,"serv":6,"reference":"https://vidarbergum.com/recipe/muhammara/","ing":[["Poivrons rouges",3,null,null],["Noix",100,"g",null],["Chapelure",40,"g",null],["Mélasse de grenade",2,"c. à soupe",null],["Huile d’olive",3,"c. à soupe",null],["Jus de citron",1,"c. à soupe",null],["Ail",1,"gousse",null],["Piment d’Alep",1,"c. à thé",null],["Cumin moulu",0.5,"c. à thé",null],["Sel",0.5,"c. à thé","ajuster au goût"]],"steps":["Couper les poivrons en deux et retirer les graines. Les rôtir peau vers le haut à 230 °C pendant 20 à 25 minutes, jusqu’à peau boursouflée. Couvrir 10 minutes puis peler et égoutter.","Torréfier les noix à sec 3 à 4 minutes en remuant; laisser refroidir.","Mixer brièvement poivrons, noix, chapelure, mélasse, huile, citron, ail et épices pour obtenir une texture encore légèrement granuleuse.","Goûter et ajuster le sel. Réfrigérer 30 minutes avant de servir avec du pain plat."],"photo":{"source":"Wikimedia Commons","file":"File:Tanoreen muhammara.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/4/4c/Tanoreen_muhammara.jpg","page":"https://commons.wikimedia.org/wiki/File:Tanoreen_muhammara.jpg","author":"Krista","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0"}}]$batch$::jsonb);
