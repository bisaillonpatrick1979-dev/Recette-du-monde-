
begin;

insert into public.culinary_places (slug,name,country_code,place_type,parent_id,latitude,longitude,default_zoom,summary,is_active)
values
('hu','Hongrie','HU','country',null,47.1625,19.5033,5,'Cuisine hongroise : paprika, soupes, ragoûts, viandes, pains et pâtisseries.',true),
('se','Suède','SE','country',null,60.1282,18.6435,5,'Cuisine suédoise : poissons, boulettes, pommes de terre, pains, baies et cuisine nordique.',true),
('ch','Suisse','CH','country',null,46.8182,8.2275,6,'Cuisine suisse : pommes de terre, fromages, charcuteries et traditions alpines régionales.',true),
('my','Malaisie','MY','country',null,4.2105,101.9758,5,'Cuisine malaisienne : riz, coco, sambal, currys, nouilles et influences malaises, chinoises et indiennes.',true),
('ec','Équateur','EC','country',null,-1.8312,-78.1834,5,'Cuisine équatorienne : poissons, fruits de mer, manioc, maïs, pommes de terre et cuisines régionales.',true),
('za','Afrique du Sud','ZA','country',null,-30.5595,22.9375,5,'Cuisine sud-africaine : influences africaines, cap-malaises, européennes et indiennes.',true)
on conflict (slug) do update set
name=excluded.name,country_code=excluded.country_code,place_type=excluded.place_type,
latitude=excluded.latitude,longitude=excluded.longitude,default_zoom=excluded.default_zoom,
summary=excluded.summary,is_active=true,updated_at=now();

insert into public.culinary_places (slug,name,country_code,place_type,parent_id,latitude,longitude,default_zoom,summary,is_active)
values
('se-stockholm','Stockholm','SE','city',(select id from public.culinary_places where slug='se'),59.3293,18.0686,10,'Stockholm est associée aux classiques suédois comme les köttbullar.',true),
('ch-bern','Canton de Berne','CH','region',(select id from public.culinary_places where slug='ch'),46.9480,7.4474,7,'Région historique du rösti, plat de pommes de terre devenu emblématique en Suisse.',true),
('id-west-sumatra','Sumatra occidental','ID','region',(select id from public.culinary_places where slug='id'),-0.7399,100.8000,6,'Région minangkabau connue pour la cuisine de Padang et le rendang.',true),
('id-padang','Padang','ID','city',(select id from public.culinary_places where slug='id-west-sumatra'),-0.9471,100.4172,10,'Padang est fortement associée au rendang et à la cuisine minangkabau.',true),
('ec-guayas','Guayas','EC','region',(select id from public.culinary_places where slug='ec'),-1.9575,-79.9193,7,'Province côtière associée notamment à l’encebollado.',true),
('ec-guayaquil','Guayaquil','EC','city',(select id from public.culinary_places where slug='ec-guayas'),-2.1709,-79.9224,10,'Guayaquil est l’un des grands centres de l’encebollado équatorien.',true)
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
  -- 46 Gulyas
  v_recipe := '10000000-0000-4000-8000-000000000046';
  select id into v_place from public.culinary_places where slug='hu';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Gulyás hongrois (soupe de bœuf au paprika et pommes de terre)','gulyas-hongrois',
    'Soupe-ragoût hongroise au bœuf, paprika doux, oignons, poivrons, tomate, ail et pommes de terre.',
    'Bœuf hongrois mijoté au paprika avec légumes et pommes de terre.',
    'fr','HU','Hongrie','Soupe-ragoût','adapted','published','medium',25,120,6,now(),
    v_place,true,'Wikibooks Cookbook — Goulash',
    'https://en.wikibooks.org/wiki/Cookbook:Goulash',
    'Recette éditoriale adaptée de la recette libre Wikibooks.'
  ) on conflict (id) do update set title=excluded.title,slug=excluded.slug,description=excluded.description,excerpt=excluded.excerpt,
    country_code=excluded.country_code,region=excluded.region,category=excluded.category,status=excluded.status,
    difficulty=excluded.difficulty,prep_minutes=excluded.prep_minutes,cook_minutes=excluded.cook_minutes,
    servings=excluded.servings,primary_place_id=excluded.primary_place_id,source_name=excluded.source_name,
    source_url=excluded.source_url,source_notes=excluded.source_notes,updated_at=now();

  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Bœuf à ragoût',900,'g','en cubes'),
    (v_recipe,1,'Oignons',3,'unité','hachés'),
    (v_recipe,2,'Poivrons rouges',2,'unité','hachés'),
    (v_recipe,3,'Tomate',2,'unité','hachées'),
    (v_recipe,4,'Paprika doux hongrois',2,'c. à soupe',null),
    (v_recipe,5,'Ail',6,'gousse','hachées'),
    (v_recipe,6,'Pommes de terre',700,'g','en cubes'),
    (v_recipe,7,'Feuille de laurier',1,'unité',null),
    (v_recipe,8,'Huile',2,'c. à soupe',null),
    (v_recipe,9,'Eau ou bouillon',1.5,'L',null),
    (v_recipe,10,'Sel',2,'c. à thé','ajuster'),
    (v_recipe,11,'Poivre noir',0.5,'c. à thé',null);
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Faire revenir les oignons dans l’huile jusqu’à tendreté.'),
    (v_recipe,1,'Ajouter le bœuf et le faire colorer légèrement. Ajouter paprika, ail, poivrons et tomate.'),
    (v_recipe,2,'Ajouter le laurier et le bouillon. Couvrir et laisser mijoter environ 90 minutes.'),
    (v_recipe,3,'Ajouter les pommes de terre et poursuivre 20 à 25 minutes jusqu’à tendreté.'),
    (v_recipe,4,'Ajuster sel et poivre et servir très chaud.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/0/01/Guly%C3%A1s_soup.jpg',
    'Gulyás hongrois, soupe de bœuf au paprika',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Guly%C3%A1s_soup.jpg',
    'Top Budapest','CC BY 2.0','https://creativecommons.org/licenses/by/2.0/',
    'Photo : Top Budapest · Wikimedia Commons · CC BY 2.0',
    true,true,'Photo de goulash hongrois en marmite.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Gulyás','Soupe-ragoût hongroise de bœuf au paprika.','Hongrie',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Goulash');

  -- 47 Swedish meatballs
  v_recipe := '10000000-0000-4000-8000-000000000047';
  select id into v_place from public.culinary_places where slug='se-stockholm';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Köttbullar suédois (boulettes de bœuf et porc, purée et airelles)','kottbullar-suedois',
    'Boulettes suédoises de bœuf et porc avec sauce crémeuse, purée de pommes de terre et airelles.',
    'Boulettes suédoises avec purée, sauce et airelles.',
    'fr','SE','Stockholm','Boulettes','adapted','published','medium',25,35,4,now(),
    v_place,true,'Wikibooks Cookbook — Swedish Meatballs I',
    'https://en.wikibooks.org/wiki/Cookbook:Swedish_Meatballs_I',
    'Recette libre adaptée avec accompagnements correspondant à la photo de Stockholm.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();

  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Bœuf haché',250,'g',null),(v_recipe,1,'Porc haché',250,'g',null),
    (v_recipe,2,'Chapelure',50,'ml',null),(v_recipe,3,'Lait',150,'ml',null),
    (v_recipe,4,'Œuf',1,'unité',null),(v_recipe,5,'Petit oignon',1,'unité','haché finement'),
    (v_recipe,6,'Beurre',45,'g','divisé'),(v_recipe,7,'Farine',20,'g',null),
    (v_recipe,8,'Bouillon de bœuf',250,'ml',null),(v_recipe,9,'Crème',150,'ml',null),
    (v_recipe,10,'Pommes de terre',800,'g','pour la purée'),(v_recipe,11,'Lait',150,'ml','pour la purée'),
    (v_recipe,12,'Confiture d’airelles',180,'g','pour servir'),(v_recipe,13,'Sel et poivre',1,'portion','au goût');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Faire gonfler la chapelure dans le lait puis mélanger avec les viandes, l’œuf, l’oignon, sel et poivre.'),
    (v_recipe,1,'Former de petites boulettes et les dorer au beurre jusqu’à cuisson complète.'),
    (v_recipe,2,'Préparer une sauce avec les sucs, farine, bouillon et crème.'),
    (v_recipe,3,'Cuire les pommes de terre puis les réduire en purée avec beurre et lait.'),
    (v_recipe,4,'Servir les boulettes avec purée, sauce crémeuse et airelles.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,photographer_name,
    license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/5/54/Swedish_meatballs_in_Gamla_stan%2C_Stockholm.jpg',
    'Köttbullar suédois avec purée et airelles','Wikimedia Commons',
    'https://commons.wikimedia.org/wiki/File:Swedish_meatballs_in_Gamla_stan,_Stockholm.jpg',
    'JIP','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : JIP · Wikimedia Commons · CC BY-SA 4.0',true,true,
    'Photo prise à Stockholm montrant boulettes, purée et airelles.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Köttbullar','Boulettes suédoises servies avec purée, sauce et airelles.','Stockholm',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Swedish_Meatballs_I');

  -- 48 Rosti
  v_recipe := '10000000-0000-4000-8000-000000000048';
  select id into v_place from public.culinary_places where slug='ch-bern';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Älpler-Rösti suisse (pommes de terre, bacon et œuf)','alpler-rosti-suisse',
    'Rösti bernois croustillant de pommes de terre servi avec bacon et œuf au plat.',
    'Galette suisse de pommes de terre avec bacon et œuf.',
    'fr','CH','Canton de Berne','Pommes de terre','adapted','published','easy',20,30,4,now(),
    v_place,true,'Wikibooks Cookbook — Rosti',
    'https://en.wikibooks.org/wiki/Cookbook:Rosti_(Swiss_Potato_Patties)',
    'Variation alpine basée sur le rösti suisse et la photo de référence.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Pommes de terre',900,'g','râpées grossièrement'),
    (v_recipe,1,'Bacon',250,'g','en tranches'),
    (v_recipe,2,'Œufs',4,'unité',null),
    (v_recipe,3,'Huile ou beurre',3,'c. à soupe',null),
    (v_recipe,4,'Sel',1,'c. à thé',null),(v_recipe,5,'Poivre noir',0.5,'c. à thé',null);
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Râper les pommes de terre et presser l’excès d’humidité.'),
    (v_recipe,1,'Former une grande galette dans une poêle graissée et cuire jusqu’à dorure des deux côtés.'),
    (v_recipe,2,'Faire griller le bacon séparément.'),
    (v_recipe,3,'Cuire les œufs au plat.'),
    (v_recipe,4,'Servir le rösti avec bacon et œuf au plat.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,photographer_name,
    license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/3/34/%C3%84lpler-R%C3%B6sti.jpg',
    'Älpler-Rösti suisse avec bacon et œuf','Wikimedia Commons',
    'https://commons.wikimedia.org/wiki/File:%C3%84lpler-R%C3%B6sti.jpg',
    'Strohhaecker2018','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : Strohhaecker2018 · Wikimedia Commons · CC BY-SA 4.0',true,true,
    'Photo prise dans le canton de Berne montrant rösti, bacon et œuf.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Rösti','Galette suisse croustillante de pommes de terre.','Canton de Berne',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Rosti_(Swiss_Potato_Patties)');

  -- 49 Nasi lemak
  v_recipe := '10000000-0000-4000-8000-000000000049';
  select id into v_place from public.culinary_places where slug='my';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Nasi lemak malaisien (riz coco, sambal, œuf, anchois et poulet)','nasi-lemak-malaisien',
    'Riz parfumé au lait de coco avec sambal, œuf, anchois frits, arachides, concombre et poulet épicé.',
    'Plat national malaisien autour du riz au lait de coco.',
    'fr','MY','Malaisie','Riz','adapted','published','medium',35,55,6,now(),
    v_place,true,'Tourism Malaysia',
    'https://www.malaysia.travel/explore/rezept-das-beste-nasi-lemak',
    'Base officielle Tourism Malaysia avec accompagnement de poulet pour correspondre à la photo.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Riz jasmin',500,'g',null),(v_recipe,1,'Lait de coco',400,'ml',null),
    (v_recipe,2,'Eau',750,'ml',null),(v_recipe,3,'Gingembre',20,'g','en tranches'),
    (v_recipe,4,'Citronnelle',1,'tige',null),(v_recipe,5,'Œufs',6,'unité','durs'),
    (v_recipe,6,'Anchois séchés',120,'g','frits'),(v_recipe,7,'Arachides',120,'g','grillées'),
    (v_recipe,8,'Concombre',1,'unité','tranché'),(v_recipe,9,'Sambal',250,'g',null),
    (v_recipe,10,'Cuisses de poulet',6,'unité','cuites dans une partie du sambal'),
    (v_recipe,11,'Sel',1.5,'c. à thé',null);
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Cuire le riz avec lait de coco, eau, gingembre, citronnelle et sel.'),
    (v_recipe,1,'Faire cuire les œufs durs puis les couper en deux.'),
    (v_recipe,2,'Frire les anchois et griller les arachides.'),
    (v_recipe,3,'Cuire le poulet doucement dans une partie du sambal jusqu’à cuisson complète.'),
    (v_recipe,4,'Servir le riz avec sambal, poulet, œuf, anchois, arachides et concombre.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,photographer_name,
    license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/3/34/Nasi_lemak.jpg',
    'Nasi lemak malaisien avec riz coco, sambal, poulet, œuf, anchois, arachides et concombre',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Nasi_lemak.jpg',
    'LensaMalaysia contributors','CC BY 2.5','https://creativecommons.org/licenses/by/2.5/',
    'Photo : LensaMalaysia · Wikimedia Commons · CC BY 2.5',true,true,
    'Photo montrant riz, sambal, poulet, œuf, anchois, arachides et concombre.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Nasi lemak','Riz au lait de coco servi avec sambal et accompagnements.','Malaisie',true,1,'Tourism Malaysia','https://www.malaysia.travel/explore/rezept-das-beste-nasi-lemak');

  -- 50 Rendang
  v_recipe := '10000000-0000-4000-8000-000000000050';
  select id into v_place from public.culinary_places where slug='id-padang';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Rendang de Padang (bœuf mijoté au lait de coco et épices)','rendang-padang',
    'Bœuf lentement mijoté au lait de coco avec galanga, gingembre, curcuma, piments et citronnelle.',
    'Rendang minangkabau de bœuf longuement réduit au coco et aux épices.',
    'fr','ID','Padang, Sumatra occidental','Bœuf mijoté','adapted','published','hard',30,180,8,now(),
    v_place,true,'Wikibooks Cookbook — Rendang',
    'https://en.wikibooks.org/wiki/Cookbook:Rendang_(Indonesian_Beef_and_Coconut_Stew)',
    'Recette libre Wikibooks adaptée.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Bœuf en gros cubes',1,'kg',null),(v_recipe,1,'Lait de coco',1.5,'L',null),
    (v_recipe,2,'Échalotes',4,'unité',null),(v_recipe,3,'Ail',3,'gousse',null),
    (v_recipe,4,'Gingembre',25,'g',null),(v_recipe,5,'Curcuma frais',15,'g',null),
    (v_recipe,6,'Galanga',60,'g',null),(v_recipe,7,'Piments rouges',6,'unité',null),
    (v_recipe,8,'Citronnelle',1,'tige',null),(v_recipe,9,'Feuilles de combava',4,'unité',null),
    (v_recipe,10,'Sucre de palme',1,'c. à soupe',null),(v_recipe,11,'Sel',1,'c. à thé',null);
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Mixer échalotes, ail, gingembre, curcuma, galanga, piments, sucre et sel.'),
    (v_recipe,1,'Enrober le bœuf de cette pâte et laisser reposer au moins 30 minutes.'),
    (v_recipe,2,'Chauffer le lait de coco avec citronnelle et feuilles de combava.'),
    (v_recipe,3,'Ajouter le bœuf puis mijoter très doucement en remuant régulièrement.'),
    (v_recipe,4,'Poursuivre jusqu’à réduction presque complète et viande très tendre, environ 2 h 30 à 3 h.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,photographer_name,
    license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/d/da/Rendang-padang.jpg',
    'Rendang de Padang, bœuf mijoté au lait de coco et épices',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Rendang-padang.jpg',
    'Icfam90','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : Icfam90 · Wikimedia Commons · CC BY-SA 4.0',true,true,'Photo de rendang de Padang.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Rendang','Bœuf minangkabau longuement mijoté au lait de coco et aux épices.','Padang',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Rendang_(Indonesian_Beef_and_Coconut_Stew)');

  -- 51 Encebollado
  v_recipe := '10000000-0000-4000-8000-000000000051';
  select id into v_place from public.culinary_places where slug='ec-guayaquil';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Encebollado de Guayaquil (soupe de thon, manioc et oignon rouge)','encebollado-guayaquil',
    'Soupe côtière équatorienne à l’albacore, manioc, oignon rouge et coriandre, servie avec citron, piment et chips de plantain.',
    'Soupe de poisson emblématique de Guayas.',
    'fr','EC','Guayaquil, Guayas','Soupe de poisson','adapted','published','medium',30,75,6,now(),
    v_place,true,'Ecuador Travel',
    'https://ecuador.travel/en/what-to-eat/',
    'Ecuador Travel identifie albacore, manioc, oignon et coriandre et situe le plat dans la province du Guayas.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Thon albacore frais',900,'g',null),(v_recipe,1,'Manioc',700,'g','pelé en morceaux'),
    (v_recipe,2,'Oignons rouges',2,'unité','émincés'),(v_recipe,3,'Tomates',3,'unité','hachées'),
    (v_recipe,4,'Coriandre fraîche',1,'tasse','hachée'),(v_recipe,5,'Cumin',1,'c. à thé',null),
    (v_recipe,6,'Eau',2.2,'L',null),(v_recipe,7,'Jus de citron vert',80,'ml',null),
    (v_recipe,8,'Piment',1,'unité','au goût'),(v_recipe,9,'Chips de plantain',180,'g','pour servir'),
    (v_recipe,10,'Sel',1.5,'c. à thé',null);
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Cuire le manioc dans l’eau salée jusqu’à tendreté.'),
    (v_recipe,1,'Ajouter tomate, cumin et une partie de l’oignon puis laisser mijoter.'),
    (v_recipe,2,'Ajouter le thon et cuire doucement jusqu’à ce qu’il soit juste cuit, puis l’émietter grossièrement.'),
    (v_recipe,3,'Remettre le poisson dans la soupe avec coriandre.'),
    (v_recipe,4,'Servir avec oignon rouge, citron, piment et chips de plantain.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,photographer_name,
    license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/f/f3/Encebollado_Ecuatoriano.png.jpg',
    'Encebollado équatorien avec thon, manioc, oignon, coriandre et chips de plantain',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Encebollado_Ecuatoriano.png.jpg',
    'Vapelaez2212','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : Vapelaez2212 · Wikimedia Commons · CC BY-SA 4.0',true,true,
    'Photo d’encebollado avec chips de plantain à côté.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Encebollado','Soupe de thon albacore, manioc, oignon et coriandre.','Guayaquil / Guayas',true,1,'Ecuador Travel','https://ecuador.travel/en/what-to-eat/');

  -- 52 Bobotie
  v_recipe := '10000000-0000-4000-8000-000000000052';
  select id into v_place from public.culinary_places where slug='za';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Bobotie sud-africain (bœuf épicé gratiné, riz et banane)','bobotie-sud-africain',
    'Bœuf haché épicé au curry avec raisins et pomme, gratiné sous une crème aux œufs, servi avec riz, banane, chutney, coco et coriandre.',
    'Gratin sud-africain de viande épicée avec accompagnements sucrés-salés.',
    'fr','ZA','Afrique du Sud','Gratin de viande','adapted','published','medium',35,55,6,now(),
    v_place,true,'Wikibooks Cookbook — Bobotie',
    'https://en.wikibooks.org/wiki/Cookbook:Bobotie',
    'Recette adaptée de Wikibooks, accompagnements alignés sur la photo ouverte.'
  ) on conflict (id) do update set title=excluded.title,description=excluded.description,excerpt=excluded.excerpt,
    primary_place_id=excluded.primary_place_id,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Bœuf haché',700,'g',null),(v_recipe,1,'Oignon',1,'unité','haché'),
    (v_recipe,2,'Pain',2,'tranche','trempé dans le lait'),(v_recipe,3,'Lait',375,'ml','divisé'),
    (v_recipe,4,'Œufs',2,'unité',null),(v_recipe,5,'Curry en poudre',1,'c. à soupe',null),
    (v_recipe,6,'Curcuma',1,'c. à thé',null),(v_recipe,7,'Raisins secs',60,'g',null),
    (v_recipe,8,'Pomme',1,'unité','en petits dés'),(v_recipe,9,'Chutney de mangue',120,'g','plus pour servir'),
    (v_recipe,10,'Riz blanc',400,'g','cru'),(v_recipe,11,'Bananes',3,'unité','tranchées et poêlées'),
    (v_recipe,12,'Noix de coco râpée',60,'g',null),(v_recipe,13,'Coriandre fraîche',0.5,'tasse',null),
    (v_recipe,14,'Sel et poivre',1,'portion','au goût');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Faire revenir l’oignon puis le bœuf. Ajouter curry, curcuma, raisins, pomme et chutney.'),
    (v_recipe,1,'Incorporer le pain trempé puis transférer dans un plat à gratin.'),
    (v_recipe,2,'Battre les œufs avec le reste du lait et verser sur la viande.'),
    (v_recipe,3,'Cuire à 180 °C environ 35 à 40 minutes jusqu’à prise et dorure.'),
    (v_recipe,4,'Servir avec riz blanc, banane poêlée, chutney de mangue, coco et coriandre.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,photographer_name,
    license_name,license_url,attribution_text,is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/4/46/Bobotie_South_Africa.jpg',
    'Bobotie sud-africain avec riz, banane, chutney, coco et coriandre',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Bobotie_South_Africa.jpg',
    'Olivier Lemoine','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/',
    'Photo : Olivier Lemoine · Wikimedia Commons · CC BY-SA 4.0',true,true,
    'La description du photographe énumère viande, raisins, pomme, curcuma, banane, chutney, coco, riz et coriandre.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Bobotie','Gratin sud-africain de viande épicée sous une couche aux œufs.','Afrique du Sud',true,1,'Wikibooks','https://en.wikibooks.org/wiki/Cookbook:Bobotie');

end $$;

notify pgrst, 'reload schema';
