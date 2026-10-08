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
select pg_temp.spoontrotter_import($batch$[{"slug":"club-sandwich-quebecois","country":"CA","place":"ca-quebec","original":"Club sandwich","title":"Club sandwich québécois (poulet, bacon, frites et salade de chou)","en":"Quebec-style club sandwich","es":"Club sándwich quebequense","desc":"Trois tranches de pain grillé beurrées superposant poulet rôti, bacon croustillant, laitue, tomate et mayonnaise, coupé en quatre pointes piquées de cure-dents et servi, à la québécoise, avec une montagne de frites et une petite salade de chou.","cat":"Sandwich","diff":"easy","prep":20,"cook":20,"serv":2,"reference":"https://fr.wikipedia.org/wiki/Club_sandwich","ing":[["Pain blanc tranché",6,"tranches",null],["Poitrine de poulet rôtie",250,"g","tranchée"],["Bacon",6,"tranches",null],["Laitue iceberg",4,"feuilles",null],["Tomate",1,null,"en rondelles"],["Mayonnaise",3,"c. à soupe",null],["Beurre",20,"g",null],["Frites",500,"g","pour servir"],["Chou vert",200,"g","émincé finement"],["Vinaigre blanc",1,"c. à soupe",null],["Sucre",1,"c. à thé",null],["Sel et poivre",1,"pincée",null]],"steps":["Mélanger le chou avec 1 c. à soupe de mayonnaise, le vinaigre, le sucre, le sel et le poivre ; réserver au frais.","Cuire le bacon jusqu’à ce qu’il soit croustillant et l’égoutter.","Griller les tranches de pain, beurrer légèrement et tartiner de mayonnaise.","Monter : pain, poulet, laitue, pain, bacon, tomate, laitue, pain.","Piquer quatre cure-dents et couper en diagonale en quatre pointes.","Servir avec les frites bien chaudes et la salade de chou."],"photo":{"file":"File:Club Sandwich from Quebec.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Club_Sandwich_from_Quebec.jpg/1280px-Club_Sandwich_from_Quebec.jpg","page":"https://commons.wikimedia.org/wiki/File:Club_Sandwich_from_Quebec.jpg","author":"Kreddible Trout","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"pizza-toute-garnie","country":"CA","place":"ca-montreal","original":"Pizza toute garnie","title":"Pizza toute garnie (pepperoni, champignons et poivrons verts)","en":"Quebec all-dressed pizza","es":"Pizza «toute garnie» de Quebec","desc":"La pizza des pizzerias de quartier québécoises : sauce tomate, mozzarella généreuse, pepperoni, champignons tranchés et poivrons verts, cuite jusqu’à ce que le fromage soit doré et que le pepperoni recroqueville sur les bords.","cat":"Plat principal","diff":"medium","prep":30,"cook":15,"serv":4,"reference":"https://fr.wikipedia.org/wiki/Pizza","ing":[["Pâte à pizza",500,"g",null],["Sauce à pizza",200,"ml",null],["Mozzarella râpée",300,"g",null],["Pepperoni",120,"g","tranché"],["Champignons blancs",200,"g","tranchés"],["Poivron vert",1,null,"en lanières"],["Origan séché",1,"c. à thé",null],["Huile d’olive",1,"c. à soupe",null]],"steps":["Préchauffer le four à 250 °C avec une pierre ou une plaque à l’intérieur.","Abaisser la pâte en un disque de 35 cm et la déposer sur une plaque farinée.","Étaler la sauce en laissant un bord de 2 cm et saupoudrer d’origan.","Couvrir de la moitié du fromage, puis du pepperoni, des champignons et du poivron, et finir par le reste du fromage.","Badigeonner le bord d’huile et cuire 12 à 15 minutes, jusqu’à ce que le fromage soit doré.","Laisser reposer 2 minutes et couper en pointes."],"photo":{"file":"File:Pointe de pizza.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Pointe_de_pizza.jpg/1280px-Pointe_de_pizza.jpg","page":"https://commons.wikimedia.org/wiki/File:Pointe_de_pizza.jpg","author":"Jeangagnon","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"poutine-dejeuner","country":"CA","place":"ca-quebec","original":"Poutine déjeuner","title":"Poutine déjeuner (pommes de terre rissolées, bacon, saucisses et sauce hollandaise)","en":"Breakfast poutine","es":"Poutine de desayuno","desc":"Variante matinale de la poutine servie dans les casse-croûte et restaurants de déjeuner du Québec : pommes de terre rissolées, bacon, saucisses, fromage en grains et une généreuse sauce hollandaise au citron.","cat":"Petit-déjeuner","diff":"medium","prep":20,"cook":30,"serv":4,"reference":"https://fr.wikipedia.org/wiki/Poutine","ing":[["Pommes de terre",800,"g","en cubes"],["Bacon",200,"g","en morceaux"],["Saucisses à déjeuner",8,null,"en tronçons"],["Fromage en grains",300,"g",null],["Jaunes d’œufs",3,null,null],["Beurre",150,"g","fondu, dont 30 g pour la cuisson"],["Jus de citron",1,"c. à soupe",null],["Oignon",1,null,"haché"],["Paprika",0.5,"c. à thé",null],["Sel et poivre",1,"c. à thé",null]],"steps":["Précuire les cubes de pommes de terre 5 minutes à l’eau salée, égoutter.","Les faire rissoler au beurre avec l’oignon et le paprika 15 minutes, jusqu’à ce qu’ils soient dorés.","Cuire le bacon et les saucisses à la poêle.","Hollandaise : fouetter les jaunes avec le citron et 1 c. à soupe d’eau au bain-marie jusqu’à épaississement, puis incorporer le beurre fondu en filet ; saler.","Répartir les pommes de terre, le bacon et les saucisses dans des bols, ajouter le fromage en grains.","Napper de sauce hollandaise chaude et servir aussitôt."],"photo":{"file":"File:Poutine déjeuner.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Poutine_d%C3%A9jeuner.jpg/1280px-Poutine_d%C3%A9jeuner.jpg","page":"https://commons.wikimedia.org/wiki/File:Poutine_d%C3%A9jeuner.jpg","author":"Safyrr","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"poutine-action-de-grace","country":"CA","place":"ca-quebec","original":"Poutine de l'Action de grâce","title":"Poutine de l’Action de grâce (dinde, farce, sauce et canneberges)","en":"Thanksgiving poutine","es":"Poutine de Acción de Gracias","desc":"Les restes du repas de l’Action de grâce transformés en poutine : frites, fromage en grains, dinde effilochée, farce, sauce brune à la dinde et sauce aux canneberges.","cat":"Plat principal","diff":"easy","prep":15,"cook":30,"serv":4,"reference":"https://fr.wikipedia.org/wiki/Poutine","ing":[["Frites",1,"kg",null],["Fromage en grains",300,"g",null],["Dinde rôtie",300,"g","effilochée"],["Farce à la dinde",300,"g","réchauffée"],["Sauce brune à la dinde",400,"ml","bien chaude"],["Sauce aux canneberges",150,"ml",null],["Sauge fraîche",4,"feuilles","émincées, facultatif"]],"steps":["Cuire les frites jusqu’à ce qu’elles soient bien croustillantes.","Réchauffer la dinde et la farce au four ou à la poêle.","Porter la sauce brune à ébullition.","Dans de grands bols, superposer frites, fromage en grains, dinde et farce.","Napper de sauce brûlante pour faire fondre légèrement le fromage.","Garnir de sauce aux canneberges et de sauge, et servir aussitôt."],"photo":{"file":"File:Poutine Action de Grace.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Poutine_Action_de_Grace.jpg/1280px-Poutine_Action_de_Grace.jpg","page":"https://commons.wikimedia.org/wiki/File:Poutine_Action_de_Grace.jpg","author":"Safyrr","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0","source":"Wikimedia Commons"}},{"slug":"croustade-aux-pommes","country":"CA","place":"ca-quebec","original":"Croustade aux pommes","title":"Croustade aux pommes (pommes sous une croûte d’avoine et cassonade)","en":"Quebec apple crisp","es":"Crujiente de manzana quebequense","desc":"Pommes du Québec tranchées, parfumées à la cannelle, cuites sous une garniture croustillante de flocons d’avoine, de cassonade, de farine et de beurre : le dessert d’automne des vergers, servi tiède avec de la crème glacée à la vanille.","cat":"Dessert","diff":"easy","prep":20,"cook":45,"serv":8,"reference":"https://en.wikipedia.org/wiki/Apple_crisp","ing":[["Pommes (Cortland ou McIntosh)",8,null,"pelées et tranchées"],["Sucre",50,"g",null],["Cannelle",1.5,"c. à thé",null],["Jus de citron",1,"c. à soupe",null],["Flocons d’avoine",150,"g",null],["Cassonade",150,"g",null],["Farine",100,"g",null],["Beurre froid",125,"g","en dés"],["Sel",1,"pincée",null],["Crème glacée à la vanille",1,"l","pour servir"]],"steps":["Préchauffer le four à 180 °C.","Mélanger les pommes avec le sucre, 1 c. à thé de cannelle et le jus de citron, et les étaler dans un plat beurré.","Mélanger l’avoine, la cassonade, la farine, le reste de cannelle et le sel.","Ajouter le beurre et sabler du bout des doigts jusqu’à obtenir des grumeaux.","Répartir la garniture sur les pommes et cuire 40 à 45 minutes, jusqu’à ce que le dessus soit doré et que les pommes bouillonnent.","Servir tiède avec de la crème glacée à la vanille."],"photo":{"file":"File:Apple-crisp.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Apple-crisp.jpg/1280px-Apple-crisp.jpg","page":"https://commons.wikimedia.org/wiki/File:Apple-crisp.jpg","author":"Contributeur Wikimedia Commons (voir la page du fichier)","license":"CC BY-SA 3.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/3.0","source":"Wikimedia Commons"}},{"slug":"gateau-des-anges","country":"CA","place":"ca-quebec","original":"Gâteau des anges","title":"Gâteau des anges (gâteau très léger aux blancs d’œufs)","en":"Angel food cake","es":"Pastel de ángel","desc":"Gâteau aérien sans matière grasse fait de blancs d’œufs montés, de sucre et de farine à gâteau, cuit dans un moule à cheminée et refroidi à l’envers ; un classique des fêtes de famille au Québec, nappé d’un glaçage léger ou servi avec des fraises.","cat":"Dessert","diff":"medium","prep":30,"cook":40,"serv":12,"reference":"https://en.wikipedia.org/wiki/Angel_food_cake","ing":[["Blancs d’œufs",12,null,"à température ambiante"],["Sucre fin",300,"g",null],["Farine à gâteau tamisée",125,"g",null],["Crème de tartre",1.5,"c. à thé",null],["Vanille",1.5,"c. à thé",null],["Extrait d’amande",0.5,"c. à thé",null],["Sel",0.25,"c. à thé",null],["Sucre glace",150,"g","pour le glaçage"],["Lait ou jus de citron",2,"c. à soupe","pour le glaçage"]],"steps":["Préchauffer le four à 175 °C, sans graisser le moule à cheminée.","Tamiser la farine avec 150 g de sucre trois fois.","Monter les blancs avec la crème de tartre et le sel en neige souple, puis ajouter le reste du sucre en pluie jusqu’à des pics fermes et brillants ; ajouter vanille et amande.","Incorporer délicatement le mélange de farine en quatre fois, à la spatule.","Verser dans le moule, passer un couteau pour chasser les bulles et cuire 35 à 40 minutes.","Retourner le moule sur un goulot de bouteille et laisser refroidir complètement avant de démouler, puis napper d’un glaçage de sucre glace et de lait."],"photo":{"file":"File:Angel food cake 1.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Angel_food_cake_1.jpg/1280px-Angel_food_cake_1.jpg","page":"https://commons.wikimedia.org/wiki/File:Angel_food_cake_1.jpg","author":"Kimberly Vardeman","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0","source":"Wikimedia Commons"}}]$batch$::jsonb);
