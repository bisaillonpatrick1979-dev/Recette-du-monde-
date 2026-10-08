-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : 8 recettes, 1 nouveaux lieux.
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
select pg_temp.spoontrotter_import($batch$[{"slug":"soupe-aux-pois-quebec","country":"CA","original":"Soupe aux pois","title":"Soupe aux pois jaunes québécoise (au jarret de porc)","en":"Québec yellow pea soup with ham hock","es":"Sopa de guisantes amarillos quebequense","desc":"Soupe épaisse de pois jaunes entiers mijotés avec un jarret de porc fumé, carottes et oignon, héritage des coureurs des bois.","cat":"Soupe","diff":"easy","prep":15,"cook":180,"serv":8,"place":"ca-quebec","ing":[["Pois jaunes entiers secs",500,"g","trempés 12 heures"],["Jarret de porc fumé",1,null,null],["Oignon",1,null,"haché"],["Carottes",2,null,"en dés"],["Céleri",1,"branches","en dés"],["Laurier",2,"feuilles",null],["Sarriette",1,"c. à thé",null],["Eau",3,"l",null],["Sel et poivre",1,"c. à thé",null]],"steps":["Égoutter les pois et les mettre dans une grande marmite avec l’eau et le jarret.","Porter à ébullition et écumer.","Ajouter légumes, laurier et sarriette.","Mijoter 3 heures à couvert jusqu’à ce que les pois se défassent.","Effilocher la viande du jarret et la remettre dans la soupe.","Rectifier l’assaisonnement et servir avec du pain de ménage."],"photo":{"file":"File:Quebecois Pea Soup.png","url":"https://upload.wikimedia.org/wikipedia/commons/c/c8/Quebecois_Pea_Soup.png","page":"https://commons.wikimedia.org/wiki/File:Quebecois_Pea_Soup.png","author":"Cnrowley","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0"}},{"slug":"tourtiere-du-lac-saint-jean","country":"CA","original":"Tourtière du Lac-Saint-Jean","title":"Tourtière du Lac-Saint-Jean (cipâte de viandes et pommes de terre en cubes)","en":"Lac-Saint-Jean tourtière (deep-dish meat and potato pie)","es":"Tourtière del Lago San Juan (pastel profundo de carnes y patatas)","desc":"Grand pâté profond de cubes de bœuf, porc et gibier ou poulet marinés, avec pommes de terre en dés, cuit très lentement au four.","cat":"Plat principal","diff":"medium","prep":45,"cook":420,"serv":10,"place":{"slug":"ca-saguenay-lac-saint-jean","name":"Saguenay–Lac-Saint-Jean","type":"region","lat":48.6,"lng":-71.8,"summary":"Région du Québec : tourtière, tarte aux bleuets et gourganes."},"ing":[["Pâte brisée",1,"kg","pour fond et couvercle"],["Bœuf en cubes",500,"g",null],["Porc en cubes",500,"g",null],["Cubes de gibier ou de poulet",500,"g",null],["Pommes de terre",1,"kg","en petits cubes"],["Oignons",2,null,"hachés"],["Bouillon de bœuf",750,"ml",null],["Sarriette",1,"c. à thé",null],["Sel",2,"c. à thé",null],["Poivre",1,"c. à thé",null]],"steps":["Mariner les viandes une nuit avec les oignons, sel, poivre et sarriette.","Foncer une grande cocotte profonde avec les deux tiers de la pâte.","Mélanger les viandes marinées et les pommes de terre et en remplir la cocotte.","Couvrir d’une abaisse, faire une cheminée et verser le bouillon par l’ouverture.","Cuire 1 heure à 200 °C, puis 6 heures à 120 °C à couvert en ajoutant du bouillon au besoin.","Servir avec du ketchup aux fruits."],"photo":{"file":"File:Tourtiere Fin.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/1/13/Tourtiere_Fin.jpg","page":"https://commons.wikimedia.org/wiki/File:Tourtiere_Fin.jpg","author":"Dominic Genest","license":"Public domain","licenseUrl":null}},{"slug":"pets-de-soeur","country":"CA","place":"ca-quebec","original":"Pets de sœur","title":"Pets de sœur (roulés de pâte à la cassonade et au beurre)","en":"Pets de sœur (Québec brown sugar pastry pinwheels)","es":"Pets de sœur (rollitos de masa con azúcar morena de Quebec)","desc":"Retailles de pâte à tarte abaissées, couvertes de beurre et de cassonade, roulées puis tranchées et cuites dans un sirop qui caramélise : la petite douceur que les grands-mères québécoises faisaient avec les restes de pâte.","cat":"Dessert","diff":"easy","prep":20,"cook":25,"serv":6,"reference":"https://fr.wikipedia.org/wiki/Pet-de-sœur","ing":[["Pâte brisée (ou retailles de pâte à tarte)",300,"g",null],["Beurre",60,"g","ramolli"],["Cassonade",150,"g",null],["Cannelle moulue",1,"c. à thé","facultatif"],["Crème 35 %",125,"ml",null],["Sirop d’érable",2,"c. à soupe","facultatif"]],"steps":["Préchauffer le four à 190 °C et beurrer un moule carré ou rond.","Abaisser la pâte en un rectangle d’environ 3 mm d’épaisseur.","Tartiner de beurre ramolli, puis couvrir de cassonade et d’un peu de cannelle, en laissant une bande libre sur un long côté.","Rouler serré à partir du long côté garni et souder la bande libre en la mouillant légèrement.","Couper en tranches de 2 cm et les poser à plat dans le moule, sans trop les serrer.","Verser la crème (et le sirop d’érable) autour des roulés, puis cuire 25 minutes jusqu’à ce que la pâte soit dorée et le sirop caramélisé.","Laisser tiédir quelques minutes avant de démouler : le caramel épaissit en refroidissant."],"photo":{"file":"File:PetDeSoeur.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/e/e3/PetDeSoeur.jpg","page":"https://commons.wikimedia.org/wiki/File:PetDeSoeur.jpg","author":"Twin1995","license":"CC BY-SA 3.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/3.0"}},{"slug":"betteraves-marinees-quebec","country":"CA","place":"ca-quebec","original":"Betteraves marinées","title":"Betteraves marinées québécoises (conserve maison au vinaigre)","en":"Québec pickled beets","es":"Remolachas encurtidas de Quebec","desc":"Betteraves cuites, tranchées et mises en pots dans un vinaigre sucré aux épices à marinade : la conserve d’automne des familles québécoises, servie avec la tourtière, le pâté chinois ou les fèves au lard.","cat":"Accompagnement","diff":"easy","prep":30,"cook":60,"serv":12,"reference":"https://fr.wikipedia.org/wiki/Cuisine_québécoise","ing":[["Petites betteraves",2,"kg","brossées, tiges coupées à 2 cm"],["Vinaigre blanc",500,"ml",null],["Eau",250,"ml",null],["Sucre",250,"g",null],["Sel",1,"c. à thé",null],["Épices à marinade",1,"c. à soupe","dans un nouet de coton"],["Oignon",1,null,"en fines rondelles, facultatif"]],"steps":["Cuire les betteraves entières dans l’eau bouillante 35 à 50 minutes, jusqu’à ce qu’un couteau les traverse facilement.","Les refroidir à l’eau froide, retirer la peau en la frottant, puis les trancher ou les couper en quartiers.","Porter à ébullition le vinaigre, l’eau, le sucre, le sel et le nouet d’épices; laisser frémir 5 minutes.","Répartir les betteraves (et l’oignon) dans des pots stérilisés chauds.","Retirer le nouet et verser le liquide bouillant jusqu’à 1 cm du bord.","Fermer et traiter 30 minutes à l’eau bouillante, ou garder au réfrigérateur jusqu’à un mois. Attendre une semaine avant de servir."],"photo":{"file":"File:Betteraves marinées.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/1/13/Betteraves_marin%C3%A9es.jpg","page":"https://commons.wikimedia.org/wiki/File:Betteraves_marin%C3%A9es.jpg","author":"Safyrr","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0"}},{"slug":"pizza-ghetti","country":"CA","place":"ca-quebec","original":"Pizza-ghetti","title":"Pizza-ghetti (pointe de pizza garnie et spaghetti sauce à la viande)","en":"Pizza-ghetti (Québec pizza and spaghetti combo)","es":"Pizza-ghetti (pizza y espaguetis al estilo de Quebec)","desc":"Le classique des pizzerias et casse-croûte du Québec : une pointe de pizza « garnie » (pepperoni, poivron, champignons) servie dans la même assiette qu’une portion de spaghetti à la sauce à la viande.","cat":"Plat principal","diff":"medium","prep":40,"cook":60,"serv":4,"reference":"https://fr.wikipedia.org/wiki/Cuisine_québécoise","ing":[["Pâte à pizza",500,"g",null],["Sauce tomate à pizza",125,"ml",null],["Pepperoni tranché",100,"g",null],["Poivron vert",1,null,"en lanières"],["Champignons blancs",150,"g","tranchés"],["Mozzarella râpée",250,"g",null],["Spaghetti",300,"g",null],["Bœuf haché",400,"g",null],["Oignon",1,null,"haché"],["Tomates broyées",796,"ml","1 boîte"],["Origan séché",1,"c. à thé",null],["Sel et poivre",1,"c. à thé",null]],"steps":["Sauce à la viande : dorer le bœuf haché et l’oignon, ajouter les tomates broyées, l’origan, sel et poivre, puis mijoter 45 minutes à feu doux.","Préchauffer le four à 230 °C. Abaisser la pâte sur une plaque huilée.","Étaler la sauce à pizza, ajouter pepperoni, poivron et champignons, puis couvrir de mozzarella.","Cuire la pizza 12 à 15 minutes, jusqu’à ce que le fromage soit doré et la croûte croustillante.","Pendant ce temps, cuire les spaghetti al dente dans l’eau salée et les égoutter.","Servir dans chaque assiette une pointe de pizza à côté d’une portion de spaghetti nappée de sauce à la viande."],"photo":{"file":"File:Pizza and spaghetti.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/b/b2/Pizza_and_spaghetti.jpg","page":"https://commons.wikimedia.org/wiki/File:Pizza_and_spaghetti.jpg","author":"Patrick Donovan","license":"CC BY 3.0","licenseUrl":"https://creativecommons.org/licenses/by/3.0"}},{"slug":"wilensky-special-montreal","country":"CA","place":"ca-montreal","original":"Wilensky Special","title":"Wilensky Special de Montréal (sandwich pressé au salami et à la mortadelle)","en":"Montreal Wilensky Special (pressed salami and bologna sandwich)","es":"Wilensky Special de Montreal (sándwich prensado de salami y mortadela)","desc":"Sandwich grillé et pressé servi depuis 1932 au comptoir Wilensky’s du Mile End : petit pain kaiser, salami de bœuf, mortadelle de bœuf et moutarde, toujours avec la moutarde et jamais coupé.","cat":"Street food","diff":"easy","prep":5,"cook":5,"serv":2,"reference":"https://en.wikipedia.org/wiki/Wilensky%27s","ing":[["Petits pains kaiser",2,null,null],["Salami de bœuf tranché",4,"tranches",null],["Mortadelle (bologne) de bœuf",2,"tranches",null],["Moutarde jaune",2,"c. à thé",null],["Fromage cheddar",2,"tranches","facultatif"],["Cornichons à l’aneth",2,null,"pour servir"]],"steps":["Ouvrir les pains et tartiner l’intérieur de moutarde.","Superposer le salami puis la mortadelle sur la base (et le cheddar si désiré).","Refermer et cuire sur une plaque ou un presse-sandwich chaud 2 à 3 minutes par côté, en pressant fermement.","Le sandwich est prêt quand le pain est doré et croustillant et la charcuterie bien chaude.","Servir entier, sans le couper, avec un cornichon à l’aneth."],"photo":{"file":"File:Wilensky's - 1.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/5/53/Wilensky%27s_-_1.jpg","page":"https://commons.wikimedia.org/wiki/File:Wilensky%27s_-_1.jpg","author":"Anna Frodesiak","license":"CC BY-SA 3.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/3.0"}},{"slug":"carres-aux-dattes","country":"CA","original":"Carrés aux dattes","title":"Carrés aux dattes (date squares à l’avoine)","en":"Canadian date squares","es":"Cuadrados de dátiles canadienses","desc":"Deux couches croustillantes d’avoine, de farine et de cassonade autour d’une purée de dattes cuites : un incontournable des boîtes à lunch et des boulangeries canadiennes, appelé matrimonial cake dans l’Ouest.","cat":"Dessert","diff":"easy","prep":20,"cook":35,"serv":16,"reference":"https://en.wikipedia.org/wiki/Date_square","ing":[["Dattes dénoyautées",375,"g","hachées"],["Eau",250,"ml",null],["Jus de citron",1,"c. à soupe",null],["Flocons d’avoine",200,"g",null],["Farine tout usage",150,"g",null],["Cassonade",150,"g",null],["Beurre",175,"g","fondu"],["Bicarbonate de soude",0.5,"c. à thé",null],["Sel",1,"pincée",null]],"steps":["Cuire les dattes avec l’eau à feu moyen 8 à 10 minutes en remuant, jusqu’à obtenir une purée épaisse; ajouter le jus de citron et laisser tiédir.","Préchauffer le four à 180 °C et beurrer un moule carré de 20 cm.","Mélanger l’avoine, la farine, la cassonade, le bicarbonate et le sel, puis incorporer le beurre fondu jusqu’à obtenir un mélange grumeleux.","Presser un peu plus de la moitié du mélange au fond du moule.","Étaler la purée de dattes, puis parsemer le reste du mélange d’avoine en pressant légèrement.","Cuire 30 à 35 minutes jusqu’à ce que le dessus soit doré. Laisser refroidir complètement avant de couper en carrés."],"photo":{"file":"File:Date Squares.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/c/c6/Date_Squares.jpg","page":"https://commons.wikimedia.org/wiki/File:Date_Squares.jpg","author":"Marchije","license":"CC0","licenseUrl":"http://creativecommons.org/publicdomain/zero/1.0/deed.en"}},{"slug":"sucre-a-la-creme","country":"CA","place":"ca-quebec","original":"Sucre à la crème","title":"Sucre à la crème québécois (fondant à la cassonade et à la crème)","en":"Québec sucre à la crème (brown sugar cream fudge)","es":"Sucre à la crème de Quebec (dulce de azúcar morena y nata)","desc":"Confiserie fondante de cassonade, de crème et de beurre, cuite jusqu’au stade de la boule molle puis battue avant de figer : la gâterie des Fêtes et des ventes de charité au Québec.","cat":"Dessert","diff":"medium","prep":10,"cook":20,"serv":24,"reference":"https://fr.wikipedia.org/wiki/Sucre_à_la_crème","ing":[["Cassonade",400,"g",null],["Crème 35 %",250,"ml",null],["Beurre",30,"g",null],["Vanille",1,"c. à thé",null],["Sel",1,"pincée",null]],"steps":["Beurrer un moule carré de 20 cm et le tapisser de papier parchemin.","Dans une casserole à fond épais, porter la cassonade, la crème et le beurre à ébullition en remuant jusqu’à dissolution du sucre.","Cuire à feu moyen sans remuer jusqu’à 113–115 °C au thermomètre (une goutte forme une boule molle dans l’eau froide), environ 10 à 15 minutes.","Retirer du feu, ajouter la vanille et le sel, et laisser tiédir 10 minutes sans remuer.","Battre à la cuillère de bois ou au batteur jusqu’à ce que le mélange perde son brillant et commence à épaissir.","Verser aussitôt dans le moule, lisser, laisser figer puis couper en carrés."],"photo":{"file":"File:Sucre a la creme.JPG","url":"https://upload.wikimedia.org/wikipedia/commons/8/8a/Sucre_a_la_creme.JPG","page":"https://commons.wikimedia.org/wiki/File:Sucre_a_la_creme.JPG","author":"Jeangagnon","license":"CC BY-SA 3.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/3.0"}}]$batch$::jsonb);
