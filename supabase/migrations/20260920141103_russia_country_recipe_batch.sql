begin;

insert into public.culinary_places
  (slug,name,country_code,place_type,parent_id,latitude,longitude,default_zoom,summary,is_active)
values
  ('ru','Russie','RU','country',null,61.5240,105.3188,3.2,
   'Cuisine russe : soupes, pâtes farcies, crêpes, céréales, poissons, viandes et traditions régionales très diverses.',
   true)
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
  select id into v_place from public.culinary_places where slug='ru';

  v_recipe := '10000000-0000-4000-8000-000000000039';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Pelmeni russes aux champignons et crème sure','pelmeni-russes-champignons-creme-sure',
    'Petits raviolis russes farcis de viande, bouillis puis servis avec champignons sautés, crème sure et aneth.',
    'Dumplings russes farcis de viande, avec champignons, crème sure et aneth.',
    'fr','RU','Russie','Pâtes farcies','adapted','published','medium',55,25,6,now(),
    v_place,true,'Wikibooks Cookbook — Cuisine of Russia',
    'https://en.wikibooks.org/wiki/Cookbook:Cuisine_of_Russia',
    'Pelmeni est référencé dans la cuisine russe par Wikibooks. La formulation est éditoriale. La photo montre pelmeni, champignons, crème sure et aneth.'
  ) on conflict (id) do update set
    title=excluded.title,slug=excluded.slug,description=excluded.description,excerpt=excluded.excerpt,
    country_code=excluded.country_code,region=excluded.region,category=excluded.category,
    authenticity=excluded.authenticity,status=excluded.status,difficulty=excluded.difficulty,
    prep_minutes=excluded.prep_minutes,cook_minutes=excluded.cook_minutes,servings=excluded.servings,
    primary_place_id=excluded.primary_place_id,is_editorial=excluded.is_editorial,
    source_name=excluded.source_name,source_url=excluded.source_url,source_notes=excluded.source_notes,updated_at=now();

  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Farine tout usage',500,'g',null),
    (v_recipe,1,'Œufs',2,'unité',null),
    (v_recipe,2,'Eau',180,'ml','environ, pour la pâte'),
    (v_recipe,3,'Sel',1.5,'c. à thé','divisé'),
    (v_recipe,4,'Bœuf haché',300,'g',null),
    (v_recipe,5,'Porc haché',300,'g',null),
    (v_recipe,6,'Oignon',1,'unité','très finement haché'),
    (v_recipe,7,'Poivre noir',0.75,'c. à thé',null),
    (v_recipe,8,'Champignons',300,'g','tranchés'),
    (v_recipe,9,'Beurre',30,'g','pour les champignons'),
    (v_recipe,10,'Crème sure',250,'g','pour servir'),
    (v_recipe,11,'Aneth frais',0.25,'tasse','haché pour servir');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Mélanger farine, œufs, eau et une partie du sel pour former une pâte ferme et lisse. Couvrir et laisser reposer 30 minutes.'),
    (v_recipe,1,'Mélanger bœuf, porc, oignon, poivre et le reste du sel.'),
    (v_recipe,2,'Abaisser la pâte finement, découper de petits disques, déposer un peu de farce au centre puis refermer soigneusement en forme de pelmeni.'),
    (v_recipe,3,'Cuire les pelmeni dans une grande casserole d’eau salée frémissante. Après leur remontée à la surface, poursuivre environ 4 à 5 minutes.'),
    (v_recipe,4,'Pendant ce temps, faire sauter les champignons au beurre jusqu’à coloration.'),
    (v_recipe,5,'Servir les pelmeni chauds avec champignons sautés, crème sure et aneth frais, comme sur la photo de référence.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,photographer_url,license_name,license_url,attribution_text,
    is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/1/1f/Pelmeni_in_Russia.jpg',
    'Pelmeni russes servis avec champignons, crème sure et aneth',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Pelmeni_in_Russia.jpg',
    'Jorge Cancela','https://www.flickr.com/people/jorgecancela/',
    'CC BY 2.0','https://creativecommons.org/licenses/by/2.0/',
    'Photo : Jorge Cancela · Wikimedia Commons · CC BY 2.0',
    true,true,'Pelmeni, champignons, crème sure et aneth visibles et inclus.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Pelmeni','Petits raviolis russes farcis de viande et bouillis.','Russie',true,1,'Wikibooks Cookbook','https://en.wikibooks.org/wiki/Cookbook:Cuisine_of_Russia');

  v_recipe := '10000000-0000-4000-8000-000000000040';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Bœuf Stroganoff russe avec nouilles','boeuf-stroganoff-russe-nouilles',
    'Bœuf tendre mijoté avec oignon, champignons, bouillon, moutarde et crème sure, servi sur nouilles aux œufs et fini au persil.',
    'Bœuf crémeux aux champignons servi sur nouilles aux œufs.',
    'fr','RU','Russie','Bœuf en sauce','adapted','published','medium',25,80,6,now(),
    v_place,true,'Wikibooks Cookbook — Traditional Beef Stroganoff',
    'https://en.wikibooks.org/wiki/Cookbook:Traditional_Beef_Stroganoff',
    'Version éditoriale basée sur la recette libre Wikibooks. Nouilles aux œufs et persil correspondent à la photo ouverte choisie.'
  ) on conflict (id) do update set
    title=excluded.title,slug=excluded.slug,description=excluded.description,excerpt=excluded.excerpt,
    country_code=excluded.country_code,region=excluded.region,category=excluded.category,
    authenticity=excluded.authenticity,status=excluded.status,difficulty=excluded.difficulty,
    prep_minutes=excluded.prep_minutes,cook_minutes=excluded.cook_minutes,servings=excluded.servings,
    primary_place_id=excluded.primary_place_id,is_editorial=excluded.is_editorial,
    source_name=excluded.source_name,source_url=excluded.source_url,source_notes=excluded.source_notes,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Bœuf à braiser en fines lanières',900,'g',null),
    (v_recipe,1,'Beurre',110,'g','divisé'),
    (v_recipe,2,'Oignon',1,'unité','émincé'),
    (v_recipe,3,'Farine',60,'ml','environ 4 c. à soupe'),
    (v_recipe,4,'Bouillon de bœuf',300,'ml',null),
    (v_recipe,5,'Moutarde préparée',1,'c. à thé',null),
    (v_recipe,6,'Champignons',250,'g','tranchés'),
    (v_recipe,7,'Crème sure',160,'ml',null),
    (v_recipe,8,'Vin blanc',160,'ml',null),
    (v_recipe,9,'Nouilles aux œufs',400,'g','cuites pour servir'),
    (v_recipe,10,'Persil frais',0.25,'tasse','haché'),
    (v_recipe,11,'Sel',1,'c. à thé','ajuster'),
    (v_recipe,12,'Poivre noir',0.75,'c. à thé',null);
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Assaisonner les lanières de bœuf. Les saisir rapidement dans une partie du beurre puis les réserver.'),
    (v_recipe,1,'Faire revenir l’oignon et les champignons dans la même poêle jusqu’à tendreté.'),
    (v_recipe,2,'Ajouter la farine, mélanger, puis incorporer graduellement le bouillon et la moutarde.'),
    (v_recipe,3,'Remettre le bœuf et laisser mijoter doucement jusqu’à tendreté, environ 45 à 60 minutes selon la coupe.'),
    (v_recipe,4,'Ajouter la crème sure et le vin blanc à feu doux sans faire bouillir fortement. Ajuster sel et poivre.'),
    (v_recipe,5,'Servir sur les nouilles aux œufs chaudes et parsemer de persil.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,photographer_url,license_name,license_url,attribution_text,
    is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/4/4b/Beef_Stroganoff-04.jpg',
    'Bœuf Stroganoff servi sur nouilles aux œufs avec persil',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Beef_Stroganoff-04.jpg',
    'V 2','https://www.flickr.com/photos/7960728@N04',
    'CC BY 2.0','https://creativecommons.org/licenses/by/2.0/',
    'Photo : V 2 · Wikimedia Commons · CC BY 2.0',
    true,true,'Bœuf Stroganoff, champignons, crème sure, nouilles aux œufs et persil visibles/documentés.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Bœuf Stroganoff','Bœuf en sauce crémeuse à la crème sure et aux champignons.','Russie',true,2,'Wikibooks Cookbook','https://en.wikibooks.org/wiki/Cookbook:Traditional_Beef_Stroganoff');

  v_recipe := '10000000-0000-4000-8000-000000000041';
  insert into public.recipes (
    id,author_id,title,slug,description,excerpt,source_language,country_code,region,category,
    authenticity,status,difficulty,prep_minutes,cook_minutes,servings,published_at,
    primary_place_id,is_editorial,source_name,source_url,source_notes
  ) values (
    v_recipe,v_author,'Blini russes aux fraises','blini-russes-fraises',
    'Crêpes russes levées et fines, servies roulées avec une sauce aux fraises, fraises fraîches, sucre glace et menthe.',
    'Blini russes avec fraises et garniture légère.',
    'fr','RU','Russie','Crêpes','adapted','published','medium',25,35,6,now(),
    v_place,true,'Wikibooks Cookbook — Bliny',
    'https://en.wikibooks.org/wiki/Cookbook:Bliny',
    'Version éditoriale adaptée de la recette libre Wikibooks. La garniture fraises, sucre glace et menthe correspond à la photo ouverte retenue.'
  ) on conflict (id) do update set
    title=excluded.title,slug=excluded.slug,description=excluded.description,excerpt=excluded.excerpt,
    country_code=excluded.country_code,region=excluded.region,category=excluded.category,
    authenticity=excluded.authenticity,status=excluded.status,difficulty=excluded.difficulty,
    prep_minutes=excluded.prep_minutes,cook_minutes=excluded.cook_minutes,servings=excluded.servings,
    primary_place_id=excluded.primary_place_id,is_editorial=excluded.is_editorial,
    source_name=excluded.source_name,source_url=excluded.source_url,source_notes=excluded.source_notes,updated_at=now();
  delete from public.recipe_ingredients where recipe_id=v_recipe;
  insert into public.recipe_ingredients(recipe_id,position,name,quantity,unit,note) values
    (v_recipe,0,'Lait',950,'ml','tiède'),
    (v_recipe,1,'Sucre',20,'g','pour la pâte'),
    (v_recipe,2,'Sel',1,'c. à soupe','réduire légèrement au goût'),
    (v_recipe,3,'Beurre fondu',25,'g',null),
    (v_recipe,4,'Levure fraîche',28,'g','ou environ 9 g de levure sèche'),
    (v_recipe,5,'Œuf',1,'unité','séparer blanc et jaune'),
    (v_recipe,6,'Farine de blé',590,'g',null),
    (v_recipe,7,'Huile',25,'ml','pour la cuisson'),
    (v_recipe,8,'Fraises',300,'g','divisées entre sauce et garniture'),
    (v_recipe,9,'Sucre',40,'g','pour la sauce aux fraises'),
    (v_recipe,10,'Sucre glace',2,'c. à soupe','pour finir'),
    (v_recipe,11,'Menthe fraîche',8,'feuille','pour garnir');
  delete from public.recipe_steps where recipe_id=v_recipe;
  insert into public.recipe_steps(recipe_id,position,instruction) values
    (v_recipe,0,'Dissoudre la levure dans une partie du lait tiède avec un peu de sucre. Ajouter le jaune d’œuf, le beurre fondu et une partie de la farine.'),
    (v_recipe,1,'Laisser lever jusqu’à ce que la pâte gonfle, puis incorporer le reste du lait, de la farine et du sucre.'),
    (v_recipe,2,'Battre le blanc d’œuf en mousse souple et l’incorporer délicatement. Laisser reposer encore environ 30 minutes.'),
    (v_recipe,3,'Cuire de fines crêpes dans une poêle légèrement huilée, une à une, jusqu’à coloration des deux côtés.'),
    (v_recipe,4,'Mixer environ 200 g de fraises avec le sucre pour obtenir une sauce. Trancher le reste des fraises.'),
    (v_recipe,5,'Rouler ou plier les blini, napper de sauce aux fraises, ajouter fraises fraîches, sucre glace et menthe comme sur la photo.');
  delete from public.recipe_locations where recipe_id=v_recipe;
  insert into public.recipe_locations(recipe_id,place_id,relation,is_primary) values(v_recipe,v_place,'origin',true);
  delete from public.recipe_images where recipe_id=v_recipe and source_type='external_licensed';
  insert into public.recipe_images (
    recipe_id,source_type,status,external_url,alt_text,source_name,source_page_url,
    photographer_name,photographer_url,license_name,license_url,attribution_text,
    is_primary,is_representative,moderation_notes
  ) values (
    v_recipe,'external_licensed','ready',
    'https://upload.wikimedia.org/wikipedia/commons/d/da/Russian_blini.jpg',
    'Blini russes servis avec fraises, sucre glace et menthe',
    'Wikimedia Commons','https://commons.wikimedia.org/wiki/File:Russian_blini.jpg',
    'Ninaras','https://commons.wikimedia.org/wiki/User:Ninaras',
    'CC BY 4.0','https://creativecommons.org/licenses/by/4.0/',
    'Photo : Ninaras · Wikimedia Commons · CC BY 4.0',
    true,true,'Blini russes aux fraises avec garnitures visibles intégrées.'
  );
  delete from public.place_specialties where recipe_id=v_recipe;
  insert into public.place_specialties(place_id,recipe_id,name,description,origin_note,is_signature,sort_order,source_name,source_url)
  values(v_place,v_recipe,'Blini','Crêpes russes levées, servies sucrées ou salées.','Russie',true,3,'Wikibooks Cookbook','https://en.wikibooks.org/wiki/Cookbook:Bliny');

end $$;

notify pgrst, 'reload schema';
