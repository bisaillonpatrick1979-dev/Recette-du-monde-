-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 8 recettes, 0 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"quetschentaart","country":"LU","original":"Quetschentaart","title":"Quetschentaart (tarte aux quetsches luxembourgeoise)","en":"Quetschentaart (Luxembourg damson plum tart)","es":"Quetschentaart (tarta luxemburguesa de ciruelas damascenas)","desc":"Tarte de fin d’été au Luxembourg, servie lors de la fête des quetsches : pâte briochée ou brisée couverte de quetsches coupées en deux et serrées comme des tuiles, saupoudrée de sucre et de cannelle.","cat":"Dessert","diff":"easy","prep":30,"cook":40,"serv":8,"reference":"https://fr.wikipedia.org/wiki/Quetschentaart","ing":[["Farine",250,"g",null],["Levure boulangère fraîche",10,"g",null],["Lait tiède",100,"ml",null],["Beurre mou",60,"g",null],["Œuf",1,null,null],["Sucre",30,"g","pour la pâte"],["Quetsches",1,"kg","dénoyautées et ouvertes en deux"],["Sucre",60,"g","pour saupoudrer"],["Cannelle",1,"c. à thé",null],["Chapelure ou semoule",2,"c. à soupe","pour le fond"]],"steps":["Pétrir la farine, la levure délayée dans le lait, l’œuf, le sucre et le beurre; laisser lever 1 heure.","Étaler la pâte finement dans un grand moule beurré et parsemer le fond de chapelure.","Ranger les demi-quetsches debout, peau vers le bas, en cercles très serrés.","Cuire 35 à 40 minutes à 190 °C.","À la sortie du four, saupoudrer de sucre mêlé de cannelle; servir tiède, éventuellement avec de la crème fouettée."],"photo":{"file":"File:Quetschentaart 02.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/4/4e/Quetschentaart_02.jpg","page":"https://commons.wikimedia.org/wiki/File:Quetschentaart_02.jpg","author":"Joel Bez","license":"CC BY 2.5","licenseUrl":"https://creativecommons.org/licenses/by/2.5"}},{"slug":"paschteit","country":"LU","original":"Paschtéit","title":"Paschtéit (bouchée à la reine luxembourgeoise au poulet et champignons)","en":"Paschtéit (Luxembourg chicken vol-au-vent)","es":"Paschtéit (volován luxemburgués de pollo y champiñones)","desc":"Plat de fête du Luxembourg : croûte feuilletée garnie d’un ragoût de poulet poché, de boulettes de viande et de champignons dans une sauce blanche au bouillon, liée à la crème et relevée de citron; servie avec des frites et une salade.","cat":"Plat principal","diff":"medium","prep":40,"cook":90,"serv":6,"reference":"https://lb.wikipedia.org/wiki/Paschtéit","ing":[["Poule ou poulet fermier",1.5,"kg",null],["Carottes, poireau et céleri",1,"botte","pour le bouillon"],["Bouchées feuilletées",6,null,null],["Chair à saucisse ou veau haché",250,"g","pour les boulettes"],["Champignons de Paris",300,"g",null],["Beurre",50,"g",null],["Farine",50,"g",null],["Crème",200,"ml",null],["Jaune d’œuf",1,null,null],["Citron",0.5,null,"jus"],["Sel, poivre et muscade",1,"pincée",null],["Frites",800,"g","pour servir"]],"steps":["Pocher la volaille 1 h 15 avec les légumes dans de l’eau salée, puis l’effeuiller; garder 750 ml de bouillon.","Former de petites boulettes de viande et les pocher 5 minutes dans le bouillon; faire sauter les champignons au beurre.","Préparer un roux avec le beurre et la farine, mouiller avec le bouillon chaud et cuire 10 minutes.","Lier avec la crème et le jaune d’œuf, ajouter citron, muscade, la volaille, les boulettes et les champignons.","Réchauffer les bouchées au four et les garnir généreusement; servir avec frites et salade."],"photo":{"file":"File:Paschtéitchen hausgemacht mat Hong Bistro 1865 Clervaux.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/4/4b/Pascht%C3%A9itchen_hausgemacht_mat_Hong_Bistro_1865_Clervaux.jpg","page":"https://commons.wikimedia.org/wiki/File:Pascht%C3%A9itchen_hausgemacht_mat_Hong_Bistro_1865_Clervaux.jpg","author":"Benreis","license":"CC BY 3.0","licenseUrl":"https://creativecommons.org/licenses/by/3.0"}},{"slug":"traipen","country":"LU","original":"Träipen","title":"Träipen (boudin noir luxembourgeois aux pommes et pommes de terre)","en":"Träipen (Luxembourg black pudding)","es":"Träipen (morcilla luxemburguesa)","desc":"Boudin noir du Luxembourg à base de sang, de lard, de viande de tête et de chou, poêlé et servi en hiver, notamment à la Saint-Sylvestre, avec des pommes de terre, de la compote ou des pommes poêlées et du raifort.","cat":"Plat principal","diff":"easy","prep":10,"cook":20,"serv":4,"reference":"https://lb.wikipedia.org/wiki/Träipen","ing":[["Träipen (boudin noir luxembourgeois)",4,null,"environ 600 g"],["Pommes de terre",800,"g",null],["Pommes",3,null,"en quartiers"],["Beurre",40,"g",null],["Raifort",2,"c. à soupe","facultatif"],["Moutarde",2,"c. à soupe",null],["Sel",1,"pincée",null]],"steps":["Cuire les pommes de terre à l’eau salée.","Piquer légèrement le boudin et le faire dorer 10 à 12 minutes à la poêle dans la moitié du beurre, à feu moyen.","Poêler les quartiers de pommes dans le reste du beurre jusqu’à ce qu’ils soient dorés et tendres.","Égoutter les pommes de terre.","Servir le boudin chaud avec pommes de terre, pommes poêlées, moutarde et raifort."],"photo":{"file":"File:Träipen.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/8/87/Tr%C3%A4ipen.jpg","page":"https://commons.wikimedia.org/wiki/File:Tr%C3%A4ipen.jpg","author":"Otets at Luxembourgish Wikipedia","license":"CC BY-SA 3.0 lu","licenseUrl":"https://creativecommons.org/licenses/by-sa/3.0/lu/deed.en"}},{"slug":"kachkeis","country":"LU","original":"Kachkéis","title":"Kachkéis (fromage cuit luxembourgeois sur pain beurré)","en":"Kachkéis (Luxembourg cooked cheese spread)","es":"Kachkéis (queso cocido luxemburgués para untar)","desc":"Fromage cuit coulant du Luxembourg, proche de la cancoillotte : fromage blanc affiné fondu avec du beurre et du bicarbonate, que l’on tartine sur du pain de campagne beurré, souvent avec un trait de moutarde.","cat":"Entrée","diff":"medium","prep":15,"cook":15,"serv":6,"reference":"https://lb.wikipedia.org/wiki/Kachkéis","ing":[["Fromage blanc maigre égoutté",500,"g",null],["Bicarbonate de soude",1,"c. à thé",null],["Beurre",50,"g",null],["Lait ou crème",100,"ml",null],["Sel",1,"pincée",null],["Pain de campagne",6,"tranches",null],["Moutarde",1,"c. à soupe","pour servir"]],"steps":["Mélanger le fromage blanc égoutté avec le bicarbonate et le laisser mûrir 2 à 3 jours à température ambiante, couvert, en remuant chaque jour, jusqu’à ce qu’il devienne translucide.","Faire fondre doucement le fromage dans une casserole avec le beurre.","Ajouter le lait ou la crème et le sel, et remuer jusqu’à obtenir une crème lisse et coulante.","Verser dans des pots et laisser refroidir.","Tartiner sur du pain beurré avec un peu de moutarde."],"photo":{"file":"File:Kachkéis 009.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/c/cc/Kachk%C3%A9is_009.jpg","page":"https://commons.wikimedia.org/wiki/File:Kachk%C3%A9is_009.jpg","author":"Les Meloures at Luxembourgish Wikipedia","license":"CC BY-SA 1.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/1.0"}},{"slug":"feierstengszalot","country":"LU","original":"Feierstengszalot","title":"Feierstengszalot (salade de bœuf bouilli à la vinaigrette)","en":"Feierstengszalot (Luxembourg boiled beef salad)","es":"Feierstengszalot (ensalada luxemburguesa de ternera hervida)","desc":"Salade froide du Luxembourg préparée avec les restes de bœuf du pot-au-feu : viande coupée en fines lanières, oignons, cornichons, œufs durs et persil, liés d’une vinaigrette à la moutarde; servie avec des frites.","cat":"Salade","diff":"easy","prep":25,"cook":0,"serv":4,"reference":"https://lb.wikipedia.org/wiki/Feierstengszalot","ing":[["Bœuf bouilli froid",600,"g","en fines lanières"],["Oignon",1,null,"finement haché"],["Échalotes",2,null,"ciselées"],["Cornichons",6,null,"en dés"],["Œufs durs",2,null,"hachés"],["Persil et ciboulette",2,"c. à soupe",null],["Moutarde",1,"c. à soupe",null],["Vinaigre de vin",3,"c. à soupe",null],["Huile",6,"c. à soupe",null],["Sel et poivre",1,"pincée",null]],"steps":["Couper le bœuf froid en très fines lanières ou en petits dés.","Fouetter la moutarde, le vinaigre, l’huile, le sel et le poivre.","Mélanger la viande avec l’oignon, les échalotes et les cornichons.","Arroser de vinaigrette et laisser mariner au moins 1 heure au frais.","Parsemer d’œufs durs et d’herbes au moment de servir."],"photo":{"file":"File:Feierstengszalot.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/8/82/Feierstengszalot.jpg","page":"https://commons.wikimedia.org/wiki/File:Feierstengszalot.jpg","author":"Otets at lb.wikipedia","license":"CC BY-SA 3.0 lu","licenseUrl":"https://creativecommons.org/licenses/by-sa/3.0/lu/deed.en"}},{"slug":"verwurelter","country":"LU","original":"Verwurelter","title":"Verwurelter (beignets noués du carnaval luxembourgeois)","en":"Verwurelter (Luxembourg carnival knot doughnuts)","es":"Verwurelter (buñuelos anudados del carnaval luxemburgués)","desc":"Beignets de carnaval au Luxembourg : pâte levée au beurre et aux œufs façonnée en nœuds, frite dans l’huile chaude et roulée dans le sucre.","cat":"Dessert","diff":"medium","prep":40,"cook":20,"serv":20,"reference":"https://lb.wikipedia.org/wiki/Verwurelter","ing":[["Farine",500,"g",null],["Levure boulangère fraîche",20,"g",null],["Lait tiède",200,"ml",null],["Œufs",2,null,null],["Beurre mou",60,"g",null],["Sucre",60,"g","pour la pâte"],["Sel",1,"pincée",null],["Zeste de citron",1,null,null],["Huile de friture",1,"l",null],["Sucre",100,"g","pour l’enrobage"]],"steps":["Pétrir la farine, la levure délayée dans le lait, les œufs, le sucre, le sel, le zeste et le beurre jusqu’à obtenir une pâte souple.","Laisser lever 1 heure.","Former des boudins de 20 cm et les nouer en huit ou en tresse; laisser lever 20 minutes.","Frire 2 à 3 minutes de chaque côté dans l’huile à 170 °C jusqu’à ce qu’ils soient dorés.","Égoutter et rouler aussitôt dans le sucre."],"photo":{"file":"File:Verwurelter.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/8/80/Verwurelter.jpg","page":"https://commons.wikimedia.org/wiki/File:Verwurelter.jpg","author":"Luxlady58","license":"CC BY 4.0","licenseUrl":"https://creativecommons.org/licenses/by/4.0"}},{"slug":"boxemannchen","country":"LU","original":"Boxemännchen","title":"Boxemännchen (bonhomme brioché de la Saint-Nicolas)","en":"Boxemännchen (Luxembourg St. Nicholas brioche man)","es":"Boxemännchen (muñeco de brioche de San Nicolás)","desc":"Petit bonhomme en pâte briochée offert aux enfants luxembourgeois à la Saint-Nicolas, le 6 décembre : pâte au lait et au beurre façonnée en personnage, avec des raisins secs pour les yeux et les boutons.","cat":"Pain","diff":"easy","prep":30,"cook":20,"serv":8,"reference":"https://lb.wikipedia.org/wiki/Boxemännchen","ing":[["Farine",500,"g",null],["Levure boulangère fraîche",20,"g",null],["Lait tiède",250,"ml",null],["Beurre mou",80,"g",null],["Sucre",60,"g",null],["Œuf",1,null,"plus 1 jaune pour la dorure"],["Sel",1,"pincée",null],["Raisins secs",30,"g","pour décorer"]],"steps":["Pétrir la farine, la levure délayée dans le lait, l’œuf, le sucre, le sel et le beurre jusqu’à obtenir une pâte lisse.","Laisser lever 1 heure.","Diviser en 8 pâtons, les façonner en bonshommes : boule pour la tête, entailles pour les bras et les jambes.","Poser les raisins pour les yeux et les boutons, dorer et laisser lever 20 minutes.","Cuire 18 à 20 minutes à 180 °C jusqu’à ce qu’ils soient dorés."],"photo":{"file":"File:Boxemännchen.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/b/b9/Boxem%C3%A4nnchen.jpg","page":"https://commons.wikimedia.org/wiki/File:Boxem%C3%A4nnchen.jpg","author":"Cornischong at lb.wikipedia","license":"CC BY-SA 3.0","licenseUrl":"http://creativecommons.org/licenses/by-sa/3.0/"}},{"slug":"wainzoossiss","country":"LU","original":"Wäinzoossiss mat Moschterzooss","title":"Wäinzoossiss à la sauce moutarde (saucisse au vin luxembourgeoise)","en":"Wäinzoossiss with mustard sauce (Luxembourg wine sausage)","es":"Wäinzoossiss con salsa de mostaza (salchicha luxemburguesa al vino)","desc":"Saucisse de porc au vin blanc de la Moselle, pochée puis dorée et nappée d’une sauce crémeuse à la moutarde; servie avec purée de pommes de terre ou Kniddelen.","cat":"Plat principal","diff":"easy","prep":15,"cook":25,"serv":4,"reference":"https://lb.wikipedia.org/wiki/Wäinzoossiss","ing":[["Wäinzoossissen (saucisses au vin)",8,null,null],["Beurre",30,"g",null],["Échalotes",2,null,"ciselées"],["Vin blanc de la Moselle (riesling ou rivaner)",150,"ml",null],["Crème",200,"ml",null],["Moutarde luxembourgeoise",2,"c. à soupe",null],["Persil",1,"c. à soupe","haché"],["Purée de pommes de terre ou Kniddelen",800,"g","pour servir"]],"steps":["Pocher les saucisses 10 minutes dans l’eau frémissante sans bouillir.","Les dorer ensuite à la poêle dans le beurre; réserver.","Faire fondre les échalotes dans la même poêle et déglacer au vin blanc.","Ajouter la crème et la moutarde et laisser réduire jusqu’à ce que la sauce nappe la cuillère.","Remettre les saucisses dans la sauce, parsemer de persil et servir avec purée ou Kniddelen."],"photo":{"file":"File:Kniddelen, mat Wäinzoossiss a Moschterzooss.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/d/d1/Kniddelen%2C_mat_W%C3%A4inzoossiss_a_Moschterzooss.jpg","page":"https://commons.wikimedia.org/wiki/File:Kniddelen,_mat_W%C3%A4inzoossiss_a_Moschterzooss.jpg","author":"Bdx","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0"}}]$batch$::jsonb);
