
begin;

insert into public.culinary_places (slug,name,country_code,place_type,parent_id,latitude,longitude,default_zoom,summary,is_active)
values
('de','Allemagne','DE','country',null,51.1657,10.4515,4,'Cuisine allemande : saucisses, pains, pommes de terre, choux, pâtisseries et traditions régionales.',true),
('co','Colombie','CO','country',null,4.5709,-74.2973,5,'Cuisine colombienne : soupes, maïs, pommes de terre, riz, viandes, fruits tropicaux et fortes identités régionales.',true),
('cu','Cuba','CU','country',null,21.5218,-77.7812,5,'Cuisine cubaine issue de traditions espagnoles, africaines et caribéennes : porc, bœuf, riz, haricots, plantain et manioc.',true),
('lb','Liban','LB','country',null,33.8547,35.8623,6,'Cuisine libanaise : herbes fraîches, huile d’olive, citron, céréales, légumes, grillades et mezzés.',true)
on conflict (slug) do update set
name=excluded.name,country_code=excluded.country_code,place_type=excluded.place_type,
latitude=excluded.latitude,longitude=excluded.longitude,default_zoom=excluded.default_zoom,
summary=excluded.summary,is_active=true,updated_at=now();

insert into public.culinary_places (slug,name,country_code,place_type,parent_id,latitude,longitude,default_zoom,summary,is_active)
values
('de-berlin','Berlin','DE','city',(select id from public.culinary_places where slug='de'),52.5200,13.4050,10,'Berlin est notamment associée à la Currywurst, snack de saucisse et sauce curry-tomate.',true),
('co-bogota','Bogotá','CO','city',(select id from public.culinary_places where slug='co'),4.7110,-74.0721,10,'Bogotá est associée à l’ajiaco santafereño, soupe de poulet, maïs, pommes de terre et guascas.',true),
('lb-beirut','Beyrouth','LB','city',(select id from public.culinary_places where slug='lb'),33.8938,35.5018,10,'Beyrouth concentre de nombreuses traditions libanaises de mezzés, salades d’herbes, grillades et pâtisseries.',true)
on conflict (slug) do update set
name=excluded.name,country_code=excluded.country_code,place_type=excluded.place_type,parent_id=excluded.parent_id,
latitude=excluded.latitude,longitude=excluded.longitude,default_zoom=excluded.default_zoom,
summary=excluded.summary,is_active=true,updated_at=now();

commit;

do $$
declare
  v_author uuid := 'ac515660-4852-4ebd-8cb5-3348d60e06e9';
  v_place uuid;
  v_recipe uuid;
begin
  -- 42 Currywurst Berlin
  v_recipe := '10000000-0000-4000-8000-000000000042';
  select id into v_place from public.culinary_places where slug='de-berlin';

  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Currywurst de Berlin avec frites','currywurst-berlin-frites',
    'Saucisse allemande poêlée puis tranchée, nappée de sauce tomate épicée au curry, servie avec frites et mayonnaise.',
    'Le snack berlinois classique : saucisse, sauce curry-tomate, frites et mayonnaise.',
    'fr','DE','Berlin','Cuisine de rue','adapted','published','easy',20,30,4,now(),
    v_place,true,'visitBerlin',
    'https://www.visitberlin.de/en/berlins-currywurst',
    'visitBerlin décrit une saucisse allemande cuite puis frite, servie tranchée avec sauce tomate épicée au curry et frites. La mayonnaise est ajoutée parce qu’elle est clairement visible sur la photo ouverte choisie.'
  ) on conflict (id) do update set
    title=excluded.title,slug=excluded.slug,description=excluded.description,excerpt=excluded.excerpt,
    country_code=excluded.country_code,region=excluded.region,category=excluded.category,
    authenticity=excluded.authenticity,status=excluded.status,difficulty=excluded.difficulty,
    prep_minutes=excluded.prep_minutes,cook_minutes=excluded.cook_minutes,servings=excluded.servings,
    primary_place_id=excluded.primary_place_id,is_editorial=excluded.is_editorial,
    source_name=excluded.source_name,source_url=excluded.source_url,source_notes=excluded.source_notes,updated_at=now();

  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Saucisses allemandes type Bratwurst ou Bockwurst',4,'unité',null),
    (v_recipe,1,'Pommes de terre',900,'g','coupées en frites'),
    (v_recipe,2,'Huile de friture',1.5,'L',null),
    (v_recipe,3,'Ketchup',250,'ml',null),
    (v_recipe,4,'Concentré de tomate',1,'c. à soupe',null),
    (v_recipe,5,'Curry en poudre',2,'c. à soupe','plus un peu pour saupoudrer'),
    (v_recipe,6,'Paprika doux',1,'c. à thé',null),
    (v_recipe,7,'Vinaigre de cidre',1,'c. à soupe',null),
    (v_recipe,8,'Sucre brun',1,'c. à thé',null),
    (v_recipe,9,'Mayonnaise',120,'ml','pour servir avec les frites'),
    (v_recipe,10,'Sel',1,'c. à thé','pour les frites');

  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Mélanger ketchup, concentré de tomate, curry, paprika, vinaigre et sucre. Chauffer doucement 10 minutes pour former une sauce lisse.'),
    (v_recipe,1,'Rincer et sécher les frites. Les frire jusqu’à cuisson, les égoutter, puis les frire une seconde fois plus chaud pour les rendre croustillantes. Saler.'),
    (v_recipe,2,'Cuire ou réchauffer les saucisses selon leur type, puis les faire dorer à la poêle.'),
    (v_recipe,3,'Couper les saucisses en rondelles épaisses.'),
    (v_recipe,4,'Napper généreusement de sauce curry-tomate et saupoudrer d’un peu de curry.'),
    (v_recipe,5,'Servir avec les frites et une portion de mayonnaise, conformément à la photo de référence.');

  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,photographer_url,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/3/3c/Berlin_Currywurst.jpg',
    'Currywurst berlinoise avec frites et mayonnaise',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Berlin_Currywurst.jpg',
    'Berlinuno','https://commons.wikimedia.org/wiki/User:Berlinuno',
    'CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : Berlinuno · Wikimedia Commons · CC BY-SA 4.0',
    true,true,'La photo représente Currywurst de Berlin avec frites et mayonnaise; tous ces éléments figurent dans la recette.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Currywurst','Saucisse tranchée avec sauce tomate au curry et frites, snack emblématique de Berlin.','Berlin',true,1,'visitBerlin','https://www.visitberlin.de/en/berlins-currywurst');

  -- 43 Ajiaco Bogota
  v_recipe := '10000000-0000-4000-8000-000000000043';
  select id into v_place from public.culinary_places where slug='co-bogota';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Ajiaco santafereño de Bogotá','ajiaco-santafereno-bogota',
    'Soupe bogotanaise de poulet, maïs, trois types de pommes de terre, guascas et aromates, servie avec riz, avocat, câpres et crème.',
    'Soupe de Bogotá au poulet, maïs, pommes de terre et guascas.',
    'fr','CO','Bogotá','Soupe','adapted','published','medium',35,90,6,now(),
    v_place,true,'Bogotá.gov.co',
    'https://bogota.gov.co/mi-ciudad/cultura-recreacion-y-deporte/receta-para-preparar-el-mejor-ajiaco-de-bogota-todos-los-secretos',
    'La préparation suit les ingrédients et l’ordre de cuisson donnés par la gagnante d’un concours d’ajiaco à Bogotá. Riz, avocat, câpres et crème sont inclus car ils apparaissent sur la photo de référence.'
  ) on conflict (id) do update set
    title=excluded.title,slug=excluded.slug,description=excluded.description,excerpt=excluded.excerpt,
    country_code=excluded.country_code,region=excluded.region,category=excluded.category,
    authenticity=excluded.authenticity,status=excluded.status,difficulty=excluded.difficulty,
    prep_minutes=excluded.prep_minutes,cook_minutes=excluded.cook_minutes,servings=excluded.servings,
    primary_place_id=excluded.primary_place_id,is_editorial=excluded.is_editorial,
    source_name=excluded.source_name,source_url=excluded.source_url,source_notes=excluded.source_notes,updated_at=now();

  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Poitrines ou cuisses de poulet',1.1,'kg',null),
    (v_recipe,1,'Épis de maïs',3,'unité','coupés en tronçons'),
    (v_recipe,2,'Pommes de terre criolla',500,'g',null),
    (v_recipe,3,'Pommes de terre pastusa',500,'g',null),
    (v_recipe,4,'Pommes de terre sabanera',500,'g',null),
    (v_recipe,5,'Arracacha',250,'g','facultatif selon la version'),
    (v_recipe,6,'Guascas séchées ou fraîches',3,'c. à soupe',null),
    (v_recipe,7,'Céleri',1,'branche','hachée'),
    (v_recipe,8,'Coriandre fraîche',0.5,'tasse','hachée'),
    (v_recipe,9,'Oignons verts',4,'unité','hachés'),
    (v_recipe,10,'Ail',3,'gousse','hachées'),
    (v_recipe,11,'Eau',3,'L','environ'),
    (v_recipe,12,'Sel',2,'c. à thé','ajuster'),
    (v_recipe,13,'Riz blanc',300,'g','cru, pour servir'),
    (v_recipe,14,'Avocats',2,'unité','en quartiers'),
    (v_recipe,15,'Câpres',80,'g','pour servir'),
    (v_recipe,16,'Crème épaisse ou crème de table',200,'ml','pour servir');

  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Mettre le poulet dans l’eau avec ail, coriandre, oignons verts, céleri et sel. Cuire jusqu’à ce que le poulet soit tendre, puis le retirer et l’effilocher.'),
    (v_recipe,1,'Ajouter l’arracacha si utilisée et laisser bouillir environ 10 minutes.'),
    (v_recipe,2,'Ajouter les pommes de terre sabanera et le maïs, puis poursuivre la cuisson.'),
    (v_recipe,3,'Ajouter ensuite les pommes de terre pastusa, puis les criolla en dernier afin qu’une partie se défasse et épaississe naturellement la soupe.'),
    (v_recipe,4,'Ajouter les guascas et cuire encore environ 10 minutes. Remettre le poulet effiloché dans la soupe.'),
    (v_recipe,5,'Cuire le riz blanc séparément. Servir l’ajiaco avec riz, avocat, câpres et crème à côté comme sur la photo de référence.');

  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,photographer_url,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/0/08/Ajiaco_bogotano.jpg',
    'Ajiaco bogotano avec poulet, pommes de terre, maïs, riz, avocat, câpres et crème',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Ajiaco_bogotano.jpg',
    'Armando Ávila Carreto','https://commons.wikimedia.org/wiki/User:Armando_Avila_Carreto',
    'CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : Armando Ávila Carreto · Wikimedia Commons · CC BY-SA 4.0',
    true,true,'La description du fichier énumère poulet, trois pommes de terre, maïs, câpres, crème, avocat et riz; tous sont inclus.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Ajiaco santafereño','Soupe de poulet, maïs, pommes de terre et guascas typique de Bogotá.','Bogotá',true,1,'Bogotá.gov.co','https://bogota.gov.co/mi-ciudad/cultura-recreacion-y-deporte/receta-para-preparar-el-mejor-ajiaco-de-bogota-todos-los-secretos');

  -- 44 Cuban ropa vieja complete plate
  v_recipe := '10000000-0000-4000-8000-000000000044';
  select id into v_place from public.culinary_places where slug='cu';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Assiette cubaine de ropa vieja','ropa-vieja-cuba-assiette-complete',
    'Bœuf effiloché mijoté à la tomate avec poivrons et oignons, servi avec riz jaune, haricots noirs, plantain frit et manioc frit.',
    'Ropa vieja cubaine avec riz, haricots noirs, plantain et manioc.',
    'fr','CU','Cuba','Bœuf mijoté','adapted','published','hard',40,140,6,now(),
    v_place,true,'Wikibooks Cookbook — Ropa Vieja',
    'https://en.wikibooks.org/wiki/Cookbook:Ropa_Vieja_(Caribbean_Shredded_Beef)',
    'La ropa vieja suit une recette cubaine libre Wikibooks. Les accompagnements sont ceux de la photo du dîner cubain et concordent avec les accompagnements décrits par CubaTravel.'
  ) on conflict (id) do update set
    title=excluded.title,slug=excluded.slug,description=excluded.description,excerpt=excluded.excerpt,
    country_code=excluded.country_code,region=excluded.region,category=excluded.category,
    authenticity=excluded.authenticity,status=excluded.status,difficulty=excluded.difficulty,
    prep_minutes=excluded.prep_minutes,cook_minutes=excluded.cook_minutes,servings=excluded.servings,
    primary_place_id=excluded.primary_place_id,is_editorial=excluded.is_editorial,
    source_name=excluded.source_name,source_url=excluded.source_url,source_notes=excluded.source_notes,updated_at=now();

  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Bavette ou flanc de bœuf',1.2,'kg',null),
    (v_recipe,1,'Huile d’olive',80,'ml',null),
    (v_recipe,2,'Oignon',1,'gros','émincé'),
    (v_recipe,3,'Poivron vert',1,'unité','en lanières'),
    (v_recipe,4,'Poivron rouge',1,'unité','en lanières'),
    (v_recipe,5,'Ail',4,'gousse','hachées'),
    (v_recipe,6,'Sauce tomate',350,'ml',null),
    (v_recipe,7,'Bouillon de bœuf',300,'ml',null),
    (v_recipe,8,'Vin rouge de cuisson',200,'ml',null),
    (v_recipe,9,'Cumin moulu',1,'c. à thé',null),
    (v_recipe,10,'Feuille de laurier',1,'unité',null),
    (v_recipe,11,'Sel',2,'c. à thé','divisé'),
    (v_recipe,12,'Riz long grain',450,'g','pour le riz jaune'),
    (v_recipe,13,'Curcuma ou rocou',1,'c. à thé','pour colorer le riz'),
    (v_recipe,14,'Haricots noirs cuits',600,'g',null),
    (v_recipe,15,'Plantains mûrs',3,'unité','en tranches'),
    (v_recipe,16,'Manioc',700,'g','pelé et coupé en bâtons'),
    (v_recipe,17,'Huile de friture',1.5,'L','pour plantain et manioc');

  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Braiser le bœuf dans de l’eau ou du bouillon jusqu’à ce qu’il soit tendre, puis conserver environ 300 ml de liquide et effilocher la viande.'),
    (v_recipe,1,'Faire revenir oignon, ail et poivrons dans l’huile d’olive. Ajouter le bœuf, sauce tomate, bouillon réservé, vin, cumin, laurier et sel. Mijoter 25 à 30 minutes.'),
    (v_recipe,2,'Cuire le riz avec eau, sel et curcuma ou rocou pour obtenir le riz jaune visible sur la photo.'),
    (v_recipe,3,'Réchauffer les haricots noirs séparément jusqu’à ce qu’ils soient bien chauds.'),
    (v_recipe,4,'Frire les tranches de plantain jusqu’à caramélisation. Précuire le manioc à l’eau jusqu’à presque tendre, sécher puis frire jusqu’à croustillant.'),
    (v_recipe,5,'Dresser l’assiette avec ropa vieja, riz jaune, haricots noirs, plantain frit et manioc frit, conformément à la photo de référence.');

  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,photographer_url,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/b/b1/Cubanfood.jpg',
    'Assiette cubaine avec ropa vieja, riz jaune, haricots noirs, plantain et manioc frit',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Cubanfood.jpg',
    'Marc Averette',null,
    'Public domain',null,
    'Photo : Marc Averette · domaine public · Wikimedia Commons',
    true,true,'La description Wikimedia identifie ropa vieja, haricots noirs, riz, plantains et yucca frit; tous figurent dans la recette.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Ropa vieja','Bœuf effiloché en sauce tomate, grand classique de la cuisine cubaine.','Cuba',true,1,'Wikibooks Cookbook','https://en.wikibooks.org/wiki/Cookbook:Ropa_Vieja_(Caribbean_Shredded_Beef)');

  -- 45 Traditional tabbouleh Beirut
  v_recipe := '10000000-0000-4000-8000-000000000045';
  select id into v_place from public.culinary_places where slug='lb-beirut';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Tabbouleh traditionnel de Beyrouth','tabbouleh-traditionnel-beyrouth',
    'Salade libanaise très herbacée de persil, tomate, menthe, boulgour, oignons, citron et huile d’olive.',
    'Persil, tomate, menthe et un peu de boulgour, photographiés à Beyrouth.',
    'fr','LB','Beyrouth','Salade','adapted','published','easy',30,0,6,now(),
    v_place,true,'Wikibooks Cookbook — Tabbouleh',
    'https://en.wikibooks.org/wiki/Cookbook:Tabbouleh_IV',
    'La recette reprend une formule libre Wikibooks. La photo de référence a été prise à Downtown Beirut pendant le National Tabbouleh Day 2010.'
  ) on conflict (id) do update set
    title=excluded.title,slug=excluded.slug,description=excluded.description,excerpt=excluded.excerpt,
    country_code=excluded.country_code,region=excluded.region,category=excluded.category,
    authenticity=excluded.authenticity,status=excluded.status,difficulty=excluded.difficulty,
    prep_minutes=excluded.prep_minutes,cook_minutes=excluded.cook_minutes,servings=excluded.servings,
    primary_place_id=excluded.primary_place_id,is_editorial=excluded.is_editorial,
    source_name=excluded.source_name,source_url=excluded.source_url,source_notes=excluded.source_notes,updated_at=now();

  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Persil plat frais',4,'tasse','haché très finement'),
    (v_recipe,1,'Menthe fraîche',1,'tasse','hachée'),
    (v_recipe,2,'Tomates mûres',4,'unité','en petits dés'),
    (v_recipe,3,'Boulgour fin',120,'ml','environ 1/2 tasse'),
    (v_recipe,4,'Oignons verts',6,'unité','hachés'),
    (v_recipe,5,'Petit oignon',1,'unité','finement haché'),
    (v_recipe,6,'Jus de citron frais',120,'ml',null),
    (v_recipe,7,'Huile d’olive extra vierge',100,'ml',null),
    (v_recipe,8,'Sel',1,'c. à thé','ajuster'),
    (v_recipe,9,'Poivre noir',0.5,'c. à thé',null);

  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Faire tremper brièvement le boulgour fin dans de l’eau fraîche, puis l’égoutter et le presser soigneusement.'),
    (v_recipe,1,'Hacher très finement le persil et la menthe sans les réduire en purée.'),
    (v_recipe,2,'Mélanger persil, menthe, tomates, oignons verts, oignon et boulgour.'),
    (v_recipe,3,'Fouetter le jus de citron avec l’huile d’olive, le sel et le poivre.'),
    (v_recipe,4,'Verser la vinaigrette sur la salade et mélanger délicatement.'),
    (v_recipe,5,'Laisser reposer 20 à 30 minutes au frais avant de servir afin que les saveurs se mélangent.');

  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,photographer_url,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/a/a0/Traditional_Tabbouleh.JPG',
    'Tabbouleh traditionnel photographié à Beyrouth',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Traditional_Tabbouleh.JPG',
    'Artusername','https://commons.wikimedia.org/wiki/User:Artusername',
    'CC BY-SA 3.0','https://creativecommons.org/licenses/by-sa/3.0/',
    'Photo : Artusername · Wikimedia Commons · CC BY-SA 3.0',
    true,true,'Photo prise à Downtown Beirut pendant le National Tabbouleh Day 2010; les ingrédients principaux visibles sont persil et tomate, cohérents avec la recette.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Tabbouleh','Salade libanaise très herbacée à base de persil, tomate, menthe, boulgour, citron et huile d’olive.','Beyrouth',true,1,'Wikibooks Cookbook','https://en.wikibooks.org/wiki/Cookbook:Tabbouleh_IV');

end $$;

notify pgrst, 'reload schema';
