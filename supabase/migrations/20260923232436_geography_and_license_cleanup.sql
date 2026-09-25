-- 1. Villes orphelines rattachées à leur pays
update public.culinary_places c set parent_id = p.id
from public.culinary_places p
where c.slug in ('id-padang','ec-guayaquil') and c.parent_id is null
  and p.place_type = 'country' and p.country_code = c.country_code;

-- 2. Fiches pays manquantes (pays ayant déjà des recettes)
insert into public.culinary_places (slug, name, country_code, place_type, latitude, longitude, default_zoom, summary, is_active)
values
 ('td','Tchad','TD','country',15.4542,18.7322,5,'Cuisine tchadienne : boules de mil et de sorgho, sauces aux gombos et à l''arachide, viandes grillées.',true),
 ('lr','Libéria','LR','country',6.4281,-9.4295,6,'Cuisine libérienne : riz, manioc, feuilles de patate douce, huile de palme et plats mijotés épicés.',true),
 ('ly','Libye','LY','country',26.3351,17.2283,4,'Cuisine libyenne : couscous, bazin, chorba, épices méditerranéennes et influences ottomanes.',true),
 ('gm','Gambie','GM','country',13.4432,-15.3101,7,'Cuisine gambienne : domoda à l''arachide, benachin, poissons du fleuve et de l''Atlantique.',true),
 ('tw','Taïwan','TW','country',23.6978,120.9605,6,'Cuisine taïwanaise : soupes de nouilles au bœuf, marchés de nuit, fruits de mer et thé.',true),
 ('il','Israël','IL','country',31.0461,34.8516,6,'Cuisine israélienne : mezzés, légumineuses, herbes fraîches et influences de toute la diaspora.',true)
on conflict (slug) do nothing;

-- 3. Recettes avec pays mais sans lieu : rattachement au pays
with targets as (
  select r.id recipe_id, p.id place_id
  from public.recipes r
  join public.culinary_places p on p.place_type = 'country' and p.country_code = r.country_code
  where r.primary_place_id is null and r.country_code is not null
)
update public.recipes r set primary_place_id = t.place_id
from targets t where r.id = t.recipe_id;

insert into public.recipe_locations (recipe_id, place_id, relation, is_primary)
select r.id, r.primary_place_id, 'origin', true
from public.recipes r
where r.primary_place_id is not null
  and not exists (select 1 from public.recipe_locations l where l.recipe_id = r.id);

-- 4. Normalisation des licences photo + URL manquantes
update public.recipe_images set license_name = case license_name
  when 'CC0' then 'CC0 1.0'
  when 'Domaine public' then 'Public domain'
  else license_name end
where license_name in ('CC0','Domaine public');

update public.recipe_images set license_url = case license_name
  when 'CC BY-SA 4.0' then 'https://creativecommons.org/licenses/by-sa/4.0/'
  when 'CC BY-SA 3.0' then 'https://creativecommons.org/licenses/by-sa/3.0/'
  when 'CC BY-SA 2.5' then 'https://creativecommons.org/licenses/by-sa/2.5/'
  when 'CC BY-SA 2.0' then 'https://creativecommons.org/licenses/by-sa/2.0/'
  when 'CC BY-SA 1.0' then 'https://creativecommons.org/licenses/by-sa/1.0/'
  when 'CC BY 4.0' then 'https://creativecommons.org/licenses/by/4.0/'
  when 'CC BY 3.0' then 'https://creativecommons.org/licenses/by/3.0/'
  when 'CC BY 2.5' then 'https://creativecommons.org/licenses/by/2.5/'
  when 'CC BY 2.0' then 'https://creativecommons.org/licenses/by/2.0/'
  when 'CC BY-SA 3.0 it' then 'https://creativecommons.org/licenses/by-sa/3.0/it/'
  when 'CC BY-SA 2.5 BR' then 'https://creativecommons.org/licenses/by-sa/2.5/br/'
  when 'CC BY-SA 3.0 Luxembourg' then 'https://creativecommons.org/licenses/by-sa/3.0/lu/'
  when 'CC0 1.0' then 'https://creativecommons.org/publicdomain/zero/1.0/'
  when 'Public domain' then 'https://creativecommons.org/publicdomain/mark/1.0/'
  else license_url end
where license_url is null;
