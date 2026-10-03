-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 4 recettes, 3 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"aguachile-sinaloa","country":"MX","original":"Aguachile","title":"Aguachile de Sinaloa (crevettes crues à la lime et piment)","en":"Sinaloa aguachile (raw shrimp in chili-lime water)","es":"Aguachile sinaloense","desc":"Crevettes crues ouvertes en papillon, « cuites » minute dans un jus de lime mixé au piment serrano ou chiltepín, avec concombre et oignon rouge.","cat":"Fruits de mer","diff":"easy","prep":20,"cook":0,"serv":4,"place":{"slug":"mx-sinaloa","name":"Sinaloa","type":"region","lat":25,"lng":-107.5,"summary":"État du Pacifique (Culiacán, Mazatlán) réputé pour ses fruits de mer et l’aguachile."},"ing":[["Crevettes crues très fraîches",500,"g","décortiquées, en papillon"],["Jus de lime",200,"ml",null],["Piments serrano ou chiltepín",3,null,null],["Coriandre",1,"bouquet",null],["Concombre",1,null,"en demi-rondelles"],["Oignon rouge",0.5,null,"émincé"],["Sel",1,"c. à thé",null],["Tostadas",8,null,null]],"steps":["Saler les crevettes et les disposer à plat sur un plat creux.","Mixer jus de lime, piments, coriandre et sel.","Verser sur les crevettes.","Ajouter concombre et oignon rouge.","Laisser reposer 10 minutes au frais jusqu’à ce que les crevettes deviennent opaques.","Servir aussitôt avec des tostadas."],"photo":{"file":"File:Aguachile de camarón, Sonora, México.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/d/de/Aguachile_de_camar%C3%B3n%2C_Sonora%2C_M%C3%A9xico.jpg","page":"https://commons.wikimedia.org/wiki/File:Aguachile_de_camar%C3%B3n,_Sonora,_M%C3%A9xico.jpg","author":"Betoknifes","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"sanuki-udon","country":"JP","original":"Sanuki udon (讃岐うどん)","title":"Sanuki udon de Kagawa (nouilles de blé épaisses et fermes)","en":"Sanuki udon (Kagawa thick wheat noodles)","es":"Sanuki udon de Kagawa","desc":"Nouilles de blé épaisses, carrées et très élastiques, pétries aux pieds selon la tradition, servies en bouillon iriko-dashi ou kake, fierté de la préfecture de Kagawa.","cat":"Soupe","diff":"medium","prep":60,"cook":15,"serv":4,"place":{"slug":"jp-kagawa","name":"Kagawa","type":"region","lat":34.2226,"lng":134.0199,"summary":"Plus petite préfecture du Japon (Shikoku), surnommée la « préfecture udon »."},"ing":[["Farine de blé moyenne",500,"g",null],["Eau",220,"ml",null],["Sel",25,"g",null],["Fécule pour fariner",3,"c. à soupe",null],["Iriko (petites sardines séchées)",30,"g",null],["Kombu",10,"g",null],["Sauce soya claire",4,"c. à soupe",null],["Mirin",2,"c. à soupe",null],["Oignons verts",3,null,null],["Tempura ou aburaage",4,"portions","facultatif"]],"steps":["Dissoudre le sel dans l’eau, l’ajouter à la farine et former une pâte ferme.","Mettre la pâte dans un sac et la piétiner 5 minutes; plier et répéter 3 fois; reposer 2 heures.","Étaler à 3 mm et couper en nouilles de 3 mm.","Préparer le dashi : faire tremper iriko et kombu, puis chauffer 10 minutes; assaisonner de soya et mirin.","Cuire les nouilles 10 à 12 minutes et les rincer à l’eau froide.","Réchauffer et servir dans le bouillon avec oignons verts et garniture."],"photo":{"file":"File:Sanuki udon by open-arms.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Sanuki_udon_by_open-arms.jpg/1280px-Sanuki_udon_by_open-arms.jpg","page":"https://commons.wikimedia.org/wiki/File:Sanuki_udon_by_open-arms.jpg","author":"open-arms","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0","source":"Wikimedia Commons"}},{"slug":"guoqiao-mixian","country":"CN","original":"Guòqiáo mǐxiàn (过桥米线)","title":"Nouilles « traversée du pont » du Yunnan (guoqiao mixian)","en":"Yunnan crossing-the-bridge noodles","es":"Fideos de cruzar el puente de Yunnan","desc":"Bouillon de poulet brûlant couvert d’huile servi à part, dans lequel on cuit soi-même tranches crues de viande, œuf de caille, légumes et nouilles de riz, spécialité de Mengzi au Yunnan.","cat":"Soupe","diff":"medium","prep":40,"cook":180,"serv":4,"place":{"slug":"cn-yunnan","name":"Yunnan","type":"region","lat":24.9,"lng":102.7,"summary":"Province du sud-ouest chinois (Kunming, Mengzi) : mixian, champignons sauvages et jambon de Xuanwei."},"ing":[["Poule et os de porc",2,"kg","pour le bouillon"],["Nouilles de riz mixian",400,"g",null],["Blanc de poulet",150,"g","tranché très finement"],["Filet de porc",150,"g","tranché très finement"],["Jambon de Yunnan",50,"g","en lamelles"],["Œufs de caille",8,null,null],["Pois mange-tout et ciboule",1,"portion",null],["Champignons et pousses de bambou",150,"g",null],["Graisse de poulet",4,"c. à soupe",null],["Sel",2,"c. à thé",null]],"steps":["Cuire 3 heures la poule et les os pour un bouillon riche; saler.","Disposer viandes crues, jambon, œufs de caille et légumes sur de petites assiettes.","Blanchir les nouilles.","Chauffer de grands bols épais et y verser le bouillon bouillant couvert d’une couche de graisse de poulet.","À table, plonger d’abord les viandes crues, puis les œufs et les légumes.","Ajouter les nouilles en dernier et déguster."],"photo":{"file":"File:Cross Bridge Noodles 过桥米线 (8605054559).jpg","url":"https://upload.wikimedia.org/wikipedia/commons/1/19/Cross_Bridge_Noodles_%E8%BF%87%E6%A1%A5%E7%B1%B3%E7%BA%BF_%288605054559%29.jpg","page":"https://commons.wikimedia.org/wiki/File:Cross_Bridge_Noodles_%E8%BF%87%E6%A1%A5%E7%B1%B3%E7%BA%BF_(8605054559).jpg","author":"Maxime Guilbot","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0","source":"Wikimedia Commons"}},{"slug":"dongnae-pajeon","country":"KR","original":"Dongnae pajeon (동래파전)","title":"Dongnae pajeon de Busan (galette à la ciboule et fruits de mer)","en":"Busan dongnae pajeon (scallion and seafood pancake)","es":"Dongnae pajeon de Busan (tortita de cebolleta y marisco)","desc":"Épaisse galette de ciboules entières, fruits de mer et œuf, liée d’une pâte de farine de riz gluant, ancienne spécialité du marché de Dongnae à Busan.","cat":"Entrée","diff":"easy","prep":20,"cook":15,"serv":4,"place":"kr-busan","ing":[["Ciboules fines (jjokpa)",200,"g",null],["Farine de riz gluant",100,"g",null],["Farine de blé",50,"g",null],["Bouillon d’anchois froid",200,"ml",null],["Fruits de mer mélangés (calmar, palourdes, crevettes)",250,"g",null],["Œufs",2,null,null],["Piment rouge",1,null,"émincé"],["Huile",4,"c. à soupe",null],["Sauce soya au vinaigre",4,"c. à soupe","pour tremper"]],"steps":["Mélanger les farines avec le bouillon en pâte fluide.","Huiler une poêle chaude et y aligner les ciboules entières.","Verser un peu de pâte pour les lier.","Répartir fruits de mer et piment, puis le reste de pâte.","Verser les œufs battus dessus, couvrir et cuire 4 minutes.","Retourner, cuire 4 minutes et servir avec la sauce soya vinaigrée."],"photo":{"file":"File:Korean pan cake-Dongnae pajeon-01.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Korean_pan_cake-Dongnae_pajeon-01.jpg/1280px-Korean_pan_cake-Dongnae_pajeon-01.jpg","page":"https://commons.wikimedia.org/wiki/File:Korean_pan_cake-Dongnae_pajeon-01.jpg","author":"by Jinho Jung from South Korea","license":"CC BY-SA 3.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/3.0","source":"Wikimedia Commons"}}]$batch$::jsonb);
