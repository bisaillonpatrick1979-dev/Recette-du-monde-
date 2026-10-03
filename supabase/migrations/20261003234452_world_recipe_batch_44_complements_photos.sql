-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 5 recettes, 4 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"pain-d-epices-dijon","country":"FR","original":"Pain d’épices de Dijon","title":"Pain d’épices de Dijon (au miel et aux épices)","en":"Dijon pain d’épices (honey spice bread)","es":"Pan de especias de Dijon","desc":"Pain moelleux à la farine de froment, au miel et aux épices (anis, cannelle, girofle), spécialité de Dijon depuis le XVIIᵉ siècle.","cat":"Dessert","diff":"easy","prep":15,"cook":60,"serv":10,"place":{"slug":"fr-dijon","name":"Dijon","type":"city","lat":47.322,"lng":5.0415,"summary":"Capitale de la Bourgogne : moutarde, pain d’épices, cassis."},"ing":[["Miel",250,"g",null],["Lait",150,"ml",null],["Farine",250,"g",null],["Sucre roux",50,"g",null],["Levure chimique",2,"c. à thé",null],["Mélange quatre-épices et anis",2,"c. à thé",null],["Cannelle",1,"c. à thé",null],["Œuf",1,null,null],["Zeste d’orange",1,null,null]],"steps":["Chauffer miel et lait sans bouillir.","Mélanger farine, sucre, levure et épices.","Ajouter le mélange miel-lait tiède, l’œuf et le zeste.","Verser dans un moule à cake beurré.","Cuire 1 heure à 160 °C.","Laisser reposer 24 heures emballé avant de trancher."],"photo":{"file":"File:Pain d'épices 01.JPG","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Pain_d%27%C3%A9pices_01.JPG/1280px-Pain_d%27%C3%A9pices_01.JPG","page":"https://commons.wikimedia.org/wiki/File:Pain_d%27%C3%A9pices_01.JPG","author":"Arnaud 25","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"hollandse-nieuwe-haring","country":"NL","original":"Hollandse Nieuwe","title":"Hareng « Hollandse Nieuwe » aux oignons","en":"Dutch new herring","es":"Arenque Hollandse Nieuwe","desc":"Hareng de début de saison légèrement saumuré, mangé cru avec oignon haché et cornichons, rituel des échoppes de poisson néerlandaises.","cat":"Cuisine de rue","diff":"easy","prep":10,"cook":0,"serv":4,"place":{"slug":"nl-scheveningen","name":"Scheveningen","type":"locality","lat":52.1083,"lng":4.2733,"summary":"Port de pêche de La Haye où l'on fête chaque juin l'arrivée du premier hareng nouveau."},"ing":[["Filets de hareng nouveau (maatjes)",4,null,null],["Oignon blanc",1,null,"finement haché"],["Cornichons",4,null,"facultatif"],["Petits pains blancs",4,null,"facultatif"]],"steps":["Garder les filets bien froids jusqu'au service.","Hacher finement l'oignon.","Parsemer les filets d'oignon.","Les manger en les tenant par la queue, tête renversée, ou les couper en tronçons.","Servir avec cornichons, ou dans un petit pain (broodje haring)."],"photo":{"file":"File:Hollandse Nieuwe 001.JPG","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/Hollandse_Nieuwe_001.JPG/1280px-Hollandse_Nieuwe_001.JPG","page":"https://commons.wikimedia.org/wiki/File:Hollandse_Nieuwe_001.JPG","author":"Janericloebe","license":"Public domain","licenseUrl":null,"source":"Wikimedia Commons"}},{"slug":"oliebollen","country":"NL","original":"Oliebollen","title":"Oliebollen du Nouvel An","en":"Dutch oliebollen (New Year doughnuts)","es":"Oliebollen","desc":"Beignets ronds à la pâte levée et aux raisins, poudrés de sucre glace, vendus dans les kiosques néerlandais pour la Saint-Sylvestre.","cat":"Dessert","diff":"medium","prep":20,"cook":30,"serv":20,"place":"nl-gouda","ing":[["Farine",500,"g",null],["Lait tiède",450,"ml",null],["Levure fraîche",25,"g",null],["Sucre",30,"g",null],["Œuf",1,null,null],["Raisins secs et de Corinthe",200,"g",null],["Pomme",1,null,"en petits dés"],["Huile de friture",1.5,"l",null],["Sucre glace",50,"g",null]],"steps":["Délayer la levure dans un peu de lait tiède.","Mélanger farine, sucre, sel, œuf, lait et levure en pâte épaisse et collante.","Incorporer raisins et pomme; laisser lever 1 heure au chaud.","Chauffer l'huile à 180 °C.","Former des boules avec deux cuillères huilées et les plonger dans l'huile.","Frire 6 à 8 minutes en les retournant.","Égoutter et poudrer de sucre glace."],"photo":{"file":"File:Oliebollen.JPG","url":"https://upload.wikimedia.org/wikipedia/commons/d/d4/Oliebollen.JPG","page":"https://commons.wikimedia.org/wiki/File:Oliebollen.JPG","author":"Koos Jol at Dutch Wikibooks","license":"CC BY-SA 3.0","licenseUrl":"http://creativecommons.org/licenses/by-sa/3.0/","source":"Wikimedia Commons"}},{"slug":"congri-oriental","country":"CU","original":"Congrí oriental","title":"Congrí oriental (riz aux haricots rouges de Santiago de Cuba)","en":"Cuban congrí oriental","es":"Congrí oriental","desc":"Riz cuit avec des haricots rouges, du lard et un sofrito, spécialité de l'Oriente cubain, cousin du moros y cristianos aux haricots noirs.","cat":"Accompagnement","diff":"easy","prep":15,"cook":90,"serv":6,"place":{"slug":"cu-santiago","name":"Santiago de Cuba","type":"city","lat":20.0247,"lng":-75.8219,"summary":"Grande ville de l'Oriente cubain, berceau du son et du congrí."},"ing":[["Haricots rouges secs",250,"g",null],["Riz long",400,"g",null],["Lard fumé",100,"g",null],["Oignon",1,null,null],["Poivron vert",1,null,null],["Ail",3,"gousses",null],["Cumin",1,"c. à café",null],["Origan",1,"c. à café",null],["Feuille de laurier",1,null,null]],"steps":["Tremper les haricots une nuit puis les cuire 1 heure avec le laurier; garder l'eau de cuisson.","Faire fondre le lard, ajouter oignon, poivron et ail (sofrito).","Ajouter cumin, origan et le riz rincé.","Verser les haricots et 800 ml de leur eau de cuisson; saler.","Cuire à couvert à feu doux 25 minutes.","Égrener à la fourchette et servir."],"photo":{"file":"File:Arroz \"Congri\".jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Arroz_%22Congri%22.jpg/1280px-Arroz_%22Congri%22.jpg","page":"https://commons.wikimedia.org/wiki/File:Arroz_%22Congri%22.jpg","author":"Juan Emilio Prades Bel","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"bammy","country":"JM","original":"Bammy","title":"Bammy (galettes de manioc de Sainte-Élisabeth)","en":"Jamaican bammy (cassava flatbread)","es":"Bammy jamaicano","desc":"Galettes de manioc râpé et pressé héritées des Taïnos, trempées dans le lait de coco puis frites, accompagnement classique du poisson.","cat":"Accompagnement","diff":"medium","prep":40,"cook":25,"serv":8,"place":{"slug":"jm-st-elizabeth","name":"Sainte-Élisabeth","type":"region","lat":18.05,"lng":-77.7,"summary":"Paroisse du sud-ouest jamaïcain, terre traditionnelle du bammy."},"ing":[["Manioc frais",1,"kg",null],["Sel",1,"c. à café",null],["Lait de coco",250,"ml",null],["Huile",100,"ml",null]],"steps":["Éplucher et râper finement le manioc.","Presser fortement dans un linge pour en extraire tout le jus.","Émietter, saler et tasser en disques de 1 cm dans un cercle sur une poêle sèche.","Cuire 5 minutes par face jusqu'à ce qu'ils se tiennent.","Tremper les galettes 10 minutes dans le lait de coco salé.","Les frire dans l'huile jusqu'à ce qu'elles soient dorées."],"photo":{"file":"File:Fried bammy.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/d/d6/Fried_bammy.jpg","page":"https://commons.wikimedia.org/wiki/File:Fried_bammy.jpg","author":"Xaymacan","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}}]$batch$::jsonb);
