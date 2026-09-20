
begin;

insert into public.culinary_places
(slug,name,country_code,place_type,parent_id,latitude,longitude,default_zoom,summary,is_active)
values
('tn','Tunisie','TN','country',null,33.8869,9.5375,5,'Cuisine tunisienne : harissa, tomates, œufs, couscous, poissons et plats méditerranéens épicés.',true),
('ir','Iran','IR','country',null,32.4279,53.6880,5,'Cuisine iranienne : herbes, riz, safran, légumineuses, fruits secs et ragoûts parfumés.',true),
('np','Népal','NP','country',null,28.3949,84.1240,6,'Cuisine népalaise : momo, dal bhat, currys, nouilles et influences himalayennes.',true),
('ro','Roumanie','RO','country',null,45.9432,24.9668,5,'Cuisine roumaine : chou farci, polenta, soupes, porc, crème et traditions balkaniques et carpatiques.',true),
('cl','Chili','CL','country',null,-35.6751,-71.5430,4,'Cuisine chilienne : maïs, bœuf, fruits de mer, pommes de terre et plats régionaux du nord au sud.',true),
('eg','Égypte','EG','country',null,26.8206,30.8025,5,'Cuisine égyptienne : riz, lentilles, fèves, pâtes, sauces tomate, pains et plats végétariens populaires.',true),
('kh','Cambodge','KH','country',null,12.5657,104.9910,5,'Cuisine cambodgienne : poisson, riz, kroeung, lait de coco, herbes, prahok et cuissons en feuilles.',true),
('mm','Myanmar','MM','country',null,21.9162,95.9560,5,'Cuisine birmane : nouilles de riz, poisson, bouillons, légumineuses, gingembre, ail et herbes.',true)
on conflict (slug) do update set
name=excluded.name,country_code=excluded.country_code,place_type=excluded.place_type,
latitude=excluded.latitude,longitude=excluded.longitude,default_zoom=excluded.default_zoom,
summary=excluded.summary,is_active=true,updated_at=now();

commit;

do $$
declare
  v_author uuid := 'ac515660-4852-4ebd-8cb5-3348d60e06e9';
  v_place uuid;
  v_recipe uuid;
begin
  -- 53 Shakshuka
  v_recipe := '10000000-0000-4000-8000-000000000053';
  select id into v_place from public.culinary_places where slug='tn';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Shakshuka tunisienne (œufs pochés dans tomate, poivron et oignon)','shakshuka-tunisienne',
    'Œufs pochés directement dans une sauce de tomates, poivrons, oignons, ail et épices, finis avec coriandre fraîche.',
    'Œufs dans une sauce tomate-poivron épicée.',
    'fr','TN','Tunisie','Œufs et tomate','adapted','published','easy',15,25,4,now(),
    v_place,true,'Wikibooks Cookbook — Shakshuka I',
    'https://en.wikibooks.org/wiki/Cookbook:Shakshuka_I',
    'Version éditoriale adaptée; la photo documente tomate, oignon, œufs pochés et coriandre.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Œufs',6,'unité',null),(v_recipe,1,'Tomates concassées',800,'g',null),
    (v_recipe,2,'Poivron rouge',1,'unité','en dés'),(v_recipe,3,'Poivron vert',1,'unité','en dés'),
    (v_recipe,4,'Oignon',1,'gros','haché'),(v_recipe,5,'Ail',4,'gousse','hachées'),
    (v_recipe,6,'Paprika',1,'c. à thé',null),(v_recipe,7,'Cumin',1,'c. à thé',null),
    (v_recipe,8,'Harissa',1,'c. à soupe','ajuster au goût'),(v_recipe,9,'Huile d’olive',2,'c. à soupe',null),
    (v_recipe,10,'Coriandre fraîche',0.5,'tasse','pour finir'),(v_recipe,11,'Sel et poivre',1,'portion','au goût');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Faire revenir l’oignon et les poivrons dans l’huile jusqu’à tendreté.'),
    (v_recipe,1,'Ajouter ail, paprika, cumin et harissa puis cuire une minute.'),
    (v_recipe,2,'Ajouter les tomates et laisser réduire 12 à 15 minutes.'),
    (v_recipe,3,'Former six creux dans la sauce et y casser les œufs. Couvrir et cuire jusqu’à blancs pris et jaunes encore tendres.'),
    (v_recipe,4,'Parsemer de coriandre fraîche et servir dans la poêle.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/e/e3/Shakshuka_Dish.jpg',
    'Shakshuka avec tomates, oignon, œufs pochés et coriandre',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Shakshuka_Dish.jpg',
    'Junbinhuang','CC BY 4.0','https://creativecommons.org/licenses/by/4.0/',
    'Photo : Junbinhuang · Wikimedia Commons · CC BY 4.0',true,true,
    'Tomates, oignon, œufs pochés et coriandre visibles et inclus.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Shakshuka','Œufs pochés dans une sauce tomate-poivron épicée.','Tunisie',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Shakshuka_I');

  -- 54 Ghormeh sabzi
  v_recipe := '10000000-0000-4000-8000-000000000054';
  select id into v_place from public.culinary_places where slug='ir';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Ghormeh sabzi iranien (ragoût de bœuf, herbes, haricots et citron séché)','ghormeh-sabzi-iranien',
    'Ragoût iranien sombre et parfumé au bœuf, persil, coriandre, ciboulette, fenugrec, haricots rouges et citrons séchés.',
    'Bœuf mijoté avec beaucoup d’herbes et haricots rouges.',
    'fr','IR','Iran','Ragoût','adapted','published','medium',35,150,6,now(),
    v_place,true,'Wikibooks Cookbook — Ghormeh Sabzi',
    'https://en.wikibooks.org/wiki/Cookbook:Ghormeh_Sabzi_(Iranian_Herb_Stew)',
    'Version éditoriale adaptée de la recette libre.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Bœuf à ragoût',800,'g','en cubes'),(v_recipe,1,'Haricots rouges cuits',450,'g',null),
    (v_recipe,2,'Persil frais',2,'tasse','haché'),(v_recipe,3,'Coriandre fraîche',1,'tasse','hachée'),
    (v_recipe,4,'Ciboulette ou feuilles d’oignon vert',1,'tasse','hachées'),(v_recipe,5,'Fenugrec séché',2,'c. à soupe',null),
    (v_recipe,6,'Oignon',1,'gros','haché'),(v_recipe,7,'Citrons persans séchés',4,'unité','percés'),
    (v_recipe,8,'Curcuma',1,'c. à thé',null),(v_recipe,9,'Huile',4,'c. à soupe',null),
    (v_recipe,10,'Eau ou bouillon',1.2,'L',null),(v_recipe,11,'Sel et poivre',1,'portion','au goût');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Faire revenir l’oignon et le bœuf avec curcuma jusqu’à légère coloration.'),
    (v_recipe,1,'Faire revenir séparément les herbes hachées dans un peu d’huile jusqu’à ce qu’elles foncent et deviennent très parfumées.'),
    (v_recipe,2,'Ajouter les herbes au bœuf avec bouillon, haricots et citrons séchés.'),
    (v_recipe,3,'Mijoter doucement environ 2 heures, jusqu’à viande tendre et sauce épaisse.'),
    (v_recipe,4,'Ajuster sel et poivre et servir chaud.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/b/bd/Ghormeh_Sabzi.JPG',
    'Ghormeh sabzi iranien aux herbes, viande et haricots rouges',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Ghormeh_Sabzi.JPG',
    'Amin Majidi','CC0 1.0','https://creativecommons.org/publicdomain/zero/1.0/',
    'Photo : Amin Majidi · Wikimedia Commons · CC0',true,true,
    'Ragoût iranien aux herbes avec viande et haricots.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Ghormeh sabzi','Ragoût iranien de viande, herbes, haricots et citron séché.','Iran',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Ghormeh_Sabzi_(Iranian_Herb_Stew)');

  -- 55 Momo
  v_recipe := '10000000-0000-4000-8000-000000000055';
  select id into v_place from public.culinary_places where slug='np';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Momo népalais (raviolis vapeur à la viande et sauces épicées)','momo-nepalais',
    'Petits raviolis népalais vapeur farcis de viande, oignon, ail et coriandre, servis avec sauce sésame et sauce piment-gingembre.',
    'Raviolis vapeur de viande avec deux sauces népalaises.',
    'fr','NP','Népal','Raviolis vapeur','adapted','published','medium',60,20,6,now(),
    v_place,true,'Wikibooks Cookbook — Momo',
    'https://en.wikibooks.org/wiki/Cookbook:Momo',
    'Version éditoriale adaptée; sauces choisies pour correspondre à la photo prise au Népal.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Farine',500,'g',null),(v_recipe,1,'Eau',250,'ml','environ'),
    (v_recipe,2,'Bœuf ou porc haché',600,'g',null),(v_recipe,3,'Oignon',1,'unité','haché finement'),
    (v_recipe,4,'Ail',4,'gousse','hachées'),(v_recipe,5,'Gingembre',20,'g','râpé'),
    (v_recipe,6,'Coriandre fraîche',0.5,'tasse','hachée'),(v_recipe,7,'Cumin',1,'c. à thé',null),
    (v_recipe,8,'Graines de sésame',80,'g','pour sauce jaune'),(v_recipe,9,'Tomate',2,'unité','pour les sauces'),
    (v_recipe,10,'Piments rouges',3,'unité','pour sauce rouge'),(v_recipe,11,'Sel',1.5,'c. à thé','divisé');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Pétrir farine, eau et une partie du sel pour obtenir une pâte lisse. Reposer 30 minutes.'),
    (v_recipe,1,'Mélanger viande, oignon, ail, gingembre, coriandre, cumin et sel.'),
    (v_recipe,2,'Abaisser la pâte, découper des disques, farcir puis plisser les momo.'),
    (v_recipe,3,'Cuire à la vapeur 10 à 12 minutes jusqu’à pâte cuite et farce bien chaude.'),
    (v_recipe,4,'Mixer sésame et tomate pour une sauce; mixer tomate, piment et gingembre pour l’autre. Servir les deux avec les momo.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/a/a1/Momo_nepal.jpg',
    'Momo népalais avec sauce sésame jaune et sauce piment-gingembre rouge',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Momo_nepal.jpg',
    'Kushal Goyal','CC BY-SA 3.0','https://creativecommons.org/licenses/by-sa/3.0/',
    'Photo : Kushal Goyal · Wikimedia Commons · CC BY-SA 3.0',true,true,
    'Photo prise au Népal montrant momo et deux sauces.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Momo','Raviolis vapeur farcis servis avec sauces épicées.','Népal',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Momo');

  -- 56 Sarmale
  v_recipe := '10000000-0000-4000-8000-000000000056';
  select id into v_place from public.culinary_places where slug='ro';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Sarmale roumaines (rouleaux de chou farcis au porc et riz)','sarmale-roumaines',
    'Feuilles de chou farcies de porc haché, riz et oignon, mijotées dans tomate et chou fermenté, servies avec crème sure.',
    'Rouleaux de chou roumains au porc et riz.',
    'fr','RO','Roumanie','Chou farci','adapted','published','medium',50,150,8,now(),
    v_place,true,'Wikibooks Cookbook — Sarmale',
    'https://en.wikibooks.org/wiki/Cookbook:Sarmale',
    'Version éditoriale adaptée de la recette libre.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Feuilles de chou fermenté ou chou blanchi',24,'unité',null),
    (v_recipe,1,'Porc haché',800,'g',null),(v_recipe,2,'Riz',150,'g','rincé'),
    (v_recipe,3,'Oignons',2,'unité','hachés'),(v_recipe,4,'Paprika',1,'c. à soupe',null),
    (v_recipe,5,'Aneth',2,'c. à soupe','haché'),(v_recipe,6,'Sauce tomate',500,'ml',null),
    (v_recipe,7,'Chou fermenté haché',300,'g','pour le fond'),(v_recipe,8,'Crème sure',250,'g','pour servir'),
    (v_recipe,9,'Sel et poivre',1,'portion','au goût');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Faire revenir les oignons puis mélanger avec porc, riz, paprika, aneth, sel et poivre.'),
    (v_recipe,1,'Déposer une petite portion de farce dans chaque feuille et rouler serré.'),
    (v_recipe,2,'Tapisser une cocotte de chou haché puis ranger les sarmale en couches.'),
    (v_recipe,3,'Verser sauce tomate et assez d’eau pour presque couvrir. Mijoter très doucement 2 à 2 h 30.'),
    (v_recipe,4,'Servir avec crème sure.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/0/09/Sarmale_Romania.jpg',
    'Sarmale roumaines servies avec crème sure',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Sarmale_Romania.jpg',
    'Andrei','CC0 1.0','https://creativecommons.org/publicdomain/zero/1.0/',
    'Photo : Andrei · Wikimedia Commons · CC0',true,true,
    'Sarmale roumaines avec crème sure visible.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Sarmale','Rouleaux de chou farcis au porc et riz.','Roumanie',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Sarmale');

  -- 57 Pastel de choclo
  v_recipe := '10000000-0000-4000-8000-000000000057';
  select id into v_place from public.culinary_places where slug='cl';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Pastel de choclo chilien (gratin de maïs au bœuf, œuf, olives et raisins)','pastel-de-choclo-chilien',
    'Gratin chilien composé d’un pino de bœuf et oignon avec œuf dur, olives et raisins, recouvert de crème de maïs puis doré au four.',
    'Gratin de maïs chilien garni de bœuf.',
    'fr','CL','Chili','Gratin','adapted','published','medium',45,55,6,now(),
    v_place,true,'Wikimedia Commons — description culinaire détaillée',
    'https://commons.wikimedia.org/wiki/File:Pastel_de_Choclo_(Chilean_Traditional_Corn_Pie).jpg',
    'La description du photographe détaille les couches et ingrédients traditionnels utilisés ici.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Bœuf haché',600,'g',null),(v_recipe,1,'Oignons',2,'unité','hachés'),
    (v_recipe,2,'Raisins secs',60,'g',null),(v_recipe,3,'Olives noires',80,'g',null),
    (v_recipe,4,'Œufs durs',3,'unité','tranchés'),(v_recipe,5,'Maïs en grains',1.2,'kg','frais ou surgelé'),
    (v_recipe,6,'Lait',250,'ml',null),(v_recipe,7,'Jaunes d’œufs',2,'unité',null),
    (v_recipe,8,'Cannelle',1,'petit bâton','retiré avant montage'),(v_recipe,9,'Clous de girofle',2,'unité','retirés avant montage'),
    (v_recipe,10,'Sucre',2,'c. à soupe','pour caraméliser le dessus'),(v_recipe,11,'Sel et poivre',1,'portion','au goût');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Cuire le bœuf et les oignons jusqu’à tendreté. Assaisonner puis incorporer raisins.'),
    (v_recipe,1,'Mixer ou râper le maïs puis le cuire doucement avec lait, cannelle et girofle jusqu’à épaississement. Retirer les épices et incorporer les jaunes.'),
    (v_recipe,2,'Étaler le mélange de bœuf dans un plat, puis ajouter olives et tranches d’œuf dur.'),
    (v_recipe,3,'Couvrir entièrement de crème de maïs et saupoudrer de sucre.'),
    (v_recipe,4,'Cuire à 200 °C environ 30 minutes jusqu’à dessus bien doré et légèrement caramélisé.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/e/e0/Pastel_de_Choclo_%28Chilean_Traditional_Corn_Pie%29.jpg',
    'Pastel de choclo chilien doré au four',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Pastel_de_Choclo_(Chilean_Traditional_Corn_Pie).jpg',
    'Foofine','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : Foofine · Wikimedia Commons · CC BY-SA 4.0',true,true,
    'Photo du pastel de choclo; la description du fichier documente précisément sa composition.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Pastel de choclo','Gratin chilien de maïs recouvrant un mélange de bœuf et garnitures.','Chili',true,1,'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Pastel_de_Choclo_(Chilean_Traditional_Corn_Pie).jpg');

  -- 58 Koshari
  v_recipe := '10000000-0000-4000-8000-000000000058';
  select id into v_place from public.culinary_places where slug='eg';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Koshari égyptien (riz, lentilles, pâtes, pois chiches et sauce tomate)','koshari-egyptien',
    'Plat végétarien égyptien de riz, lentilles et pâtes, couvert de sauce tomate épicée, pois chiches et oignons frits.',
    'Riz, lentilles et pâtes avec tomate et oignons croustillants.',
    'fr','EG','Égypte','Riz et légumineuses','adapted','published','medium',30,50,6,now(),
    v_place,true,'Wikibooks Cookbook — Koshari',
    'https://en.wikibooks.org/wiki/Cookbook:Koshari_(Egyptian_Rice_with_Pasta_and_Lentils)',
    'Recette libre adaptée; pois chiches ajoutés car documentés sur la photo égyptienne retenue.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Riz',300,'g',null),(v_recipe,1,'Lentilles brunes',300,'g',null),
    (v_recipe,2,'Macaroni ou petites pâtes',300,'g',null),(v_recipe,3,'Spaghetti cassés',150,'g',null),
    (v_recipe,4,'Pois chiches cuits',300,'g',null),(v_recipe,5,'Tomates concassées',800,'g',null),
    (v_recipe,6,'Concentré de tomate',2,'c. à soupe',null),(v_recipe,7,'Oignons',3,'unité','émincés'),
    (v_recipe,8,'Ail',5,'gousse','hachées'),(v_recipe,9,'Cumin',1,'c. à thé',null),
    (v_recipe,10,'Vinaigre',3,'c. à soupe',null),(v_recipe,11,'Piment',1,'c. à thé','au goût'),
    (v_recipe,12,'Huile',120,'ml','pour sauce et oignons'),(v_recipe,13,'Sel et poivre',1,'portion','au goût');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Cuire séparément riz, lentilles et pâtes puis réserver.'),
    (v_recipe,1,'Frire les oignons jusqu’à très croustillants et bien dorés.'),
    (v_recipe,2,'Cuire ail, tomates, concentré, cumin, vinaigre et piment pour obtenir une sauce épaisse.'),
    (v_recipe,3,'Monter le plat en couches de riz, lentilles et pâtes.'),
    (v_recipe,4,'Ajouter sauce tomate, pois chiches et beaucoup d’oignons frits.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/c/cd/Egyptian_Koshari.jpg',
    'Koshari égyptien avec riz, lentilles, pâtes, pois chiches, tomate et oignons',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Egyptian_Koshari.jpg',
    'Basma','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : Basma · Wikimedia Commons · CC BY-SA 4.0',true,true,
    'La description du fichier énumère riz, lentilles, pâtes, oignons, pois chiches et sauce tomate.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Koshari','Mélange égyptien de riz, lentilles, pâtes, sauce tomate et oignons frits.','Égypte',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Koshari_(Egyptian_Rice_with_Pasta_and_Lentils)');

  -- 59 Fish amok
  v_recipe := '10000000-0000-4000-8000-000000000059';
  select id into v_place from public.culinary_places where slug='kh';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Fish amok cambodgien (poisson vapeur au coco et kroeung)','fish-amok-cambodgien',
    'Poisson cambodgien mélangé à une pâte kroeung, lait de coco et œuf puis cuit doucement dans des feuilles de bananier.',
    'Poisson vapeur cambodgien au coco dans une feuille.',
    'fr','KH','Cambodge','Poisson vapeur','adapted','published','medium',35,30,4,now(),
    v_place,true,'Ministère du Tourisme du Cambodge',
    'https://tourismcambodia.org/public/index.php/official-activities/new-beginnings-a-gourmet-guide-to-cambodia',
    'La source officielle décrit amok comme poisson et œuf parfumés au kroeung et cuits à la vapeur dans une feuille.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Poisson blanc ferme',700,'g','en morceaux'),(v_recipe,1,'Lait de coco',400,'ml',null),
    (v_recipe,2,'Œufs',2,'unité',null),(v_recipe,3,'Citronnelle',2,'tige','partie tendre hachée'),
    (v_recipe,4,'Galanga',25,'g','haché'),(v_recipe,5,'Curcuma',15,'g','frais ou 1 c. à thé moulu'),
    (v_recipe,6,'Ail',3,'gousse',null),(v_recipe,7,'Échalotes',3,'unité',null),
    (v_recipe,8,'Feuilles de combava',4,'unité','finement émincées'),(v_recipe,9,'Prahok ou sauce poisson',1,'c. à soupe',null),
    (v_recipe,10,'Piment rouge',1,'unité','émincé'),(v_recipe,11,'Feuilles de bananier',4,'grande','pour former les coupes'),
    (v_recipe,12,'Sel',0.5,'c. à thé','au besoin');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Piler citronnelle, galanga, curcuma, ail, échalotes et une partie des feuilles de combava pour former le kroeung.'),
    (v_recipe,1,'Mélanger le kroeung avec lait de coco, œufs et prahok ou sauce poisson.'),
    (v_recipe,2,'Ajouter le poisson et mélanger délicatement.'),
    (v_recipe,3,'Former des coupelles avec les feuilles de bananier et y répartir le mélange.'),
    (v_recipe,4,'Cuire à la vapeur 20 à 25 minutes jusqu’à prise. Finir avec lait de coco, piment et combava.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/5/54/Amok_Cambodian_curry.jpg',
    'Fish amok cambodgien cuit dans une feuille avec lait de coco',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Amok_Cambodian_curry.jpg',
    'Mat Connolley','CC BY-SA 3.0','https://creativecommons.org/licenses/by-sa/3.0/',
    'Photo : Mat Connolley · Wikimedia Commons · CC BY-SA 3.0',true,true,
    'Amok cambodgien vapeur dans feuille, garni de coco et fines herbes/piment.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Fish amok','Poisson au kroeung, œuf et coco cuit à la vapeur dans une feuille.','Cambodge',true,1,'Ministère du Tourisme du Cambodge','https://tourismcambodia.org/public/index.php/official-activities/new-beginnings-a-gourmet-guide-to-cambodia');

  -- 60 Mohinga
  v_recipe := '10000000-0000-4000-8000-000000000060';
  select id into v_place from public.culinary_places where slug='mm';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Mohinga birmane (soupe de nouilles de riz au poisson et pois chiche)','mohinga-birmane',
    'Soupe traditionnelle de Myanmar à base de poisson-chat, vermicelles de riz, gingembre, ail, citronnelle, sauce poisson et farine de pois chiche.',
    'Soupe de nouilles de riz au poisson, emblématique du Myanmar.',
    'fr','MM','Myanmar','Soupe de nouilles','adapted','published','medium',30,55,6,now(),
    v_place,true,'Wikimedia Commons — documentation du Mohinga',
    'https://commons.wikimedia.org/wiki/File:Myanmar%E2%80%99s_Traditional_Food_-_Mohinga.jpg',
    'La photo documente vermicelles de riz, poisson-chat, sauce poisson, pâte de poisson, gingembre, ail et farine de pois chiche.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Filets de poisson-chat ou poisson blanc',700,'g',null),(v_recipe,1,'Vermicelles de riz',500,'g',null),
    (v_recipe,2,'Farine de pois chiche',70,'g',null),(v_recipe,3,'Oignons',2,'unité','hachés'),
    (v_recipe,4,'Ail',5,'gousse','hachées'),(v_recipe,5,'Gingembre',30,'g','haché'),
    (v_recipe,6,'Citronnelle',2,'tige','écrasées'),(v_recipe,7,'Sauce poisson',3,'c. à soupe',null),
    (v_recipe,8,'Pâte de poisson',1,'c. à soupe','facultatif mais traditionnel'),(v_recipe,9,'Curcuma',1,'c. à thé',null),
    (v_recipe,10,'Bouillon ou eau',2,'L',null),(v_recipe,11,'Coriandre fraîche',0.5,'tasse','pour servir'),
    (v_recipe,12,'Piment frit ou huile pimentée',3,'c. à soupe','pour servir'),(v_recipe,13,'Sel',1,'c. à thé','ajuster');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Pocher le poisson dans le bouillon puis l’émietter grossièrement.'),
    (v_recipe,1,'Faire revenir oignon, ail, gingembre, citronnelle et curcuma jusqu’à parfumés.'),
    (v_recipe,2,'Ajouter bouillon, poisson, sauce poisson et pâte de poisson. Mijoter 20 minutes.'),
    (v_recipe,3,'Délayer la farine de pois chiche dans un peu d’eau froide puis l’ajouter pour épaissir légèrement la soupe.'),
    (v_recipe,4,'Cuire les vermicelles de riz, les répartir dans les bols et verser la soupe de poisson. Garnir de coriandre et piment.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/4/40/Myanmar%E2%80%99s_Traditional_Food_-_Mohinga.jpg',
    'Mohinga birmane, soupe de vermicelles de riz au poisson',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Myanmar%E2%80%99s_Traditional_Food_-_Mohinga.jpg',
    'Soonduggyhuppy','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : Soonduggyhuppy · Wikimedia Commons · CC BY-SA 4.0',true,true,
    'Photo prise au Myanmar; vermicelles de riz et bouillon de poisson documentés.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Mohinga','Soupe birmane de vermicelles de riz dans un bouillon de poisson.','Myanmar',true,1,'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Myanmar%E2%80%99s_Traditional_Food_-_Mohinga.jpg');

end $$;

notify pgrst, 'reload schema';
