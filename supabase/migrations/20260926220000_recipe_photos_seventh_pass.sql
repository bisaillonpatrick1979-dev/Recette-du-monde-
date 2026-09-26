-- Photos Wikimedia Commons vérifiées une à une (le fichier représente ce plat), auteur et licence conservés.
-- Septième passe (recherche plein texte dans les descriptions Commons) : 3 photos.
-- N'ajoute une photo qu'aux recettes publiées qui n'en ont pas encore : relancer ne duplique rien.
insert into public.recipe_images (recipe_id, source_type, status, external_url, alt_text, source_name, source_page_url,
  photographer_name, license_name, license_url, attribution_text, is_primary, is_representative, moderation_notes)
select r.id, 'external_licensed', 'ready', e->>'url', r.title, 'Wikimedia Commons', e->>'page',
  nullif(e->>'author', ''), e->>'license', nullif(e->>'licenseUrl', ''),
  'Photo : ' || coalesce(nullif(e->>'author', ''), 'auteur inconnu') || ' · ' || (e->>'license') || ' · Wikimedia Commons',
  true, true, 'Photo Wikimedia Commons vérifiée : le fichier représente ce plat.'
from jsonb_array_elements($photos$[{"slug":"kleija-qassim","file":"File:Kleeja in Unayzah Misukaf -1.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/6/63/Kleeja_in_Unayzah_Misukaf_-1.jpg","page":"https://commons.wikimedia.org/wiki/File:Kleeja_in_Unayzah_Misukaf_-1.jpg","author":"Slayym","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0"},{"slug":"sumagiyya-gaza","file":"File:Sumaghiyyeh.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/9/9c/Sumaghiyyeh.jpg","page":"https://commons.wikimedia.org/wiki/File:Sumaghiyyeh.jpg","author":"Peteravivangel","license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0"},{"slug":"hilachas-guatemaltecas","file":"File:Hilacha.jpg","url":"https://upload.wikimedia.org/wikipedia/commons/4/42/Hilacha.jpg","page":"https://commons.wikimedia.org/wiki/File:Hilacha.jpg","author":"Joshua Heller","license":"CC BY 2.0","licenseUrl":"https://creativecommons.org/licenses/by/2.0"}]$photos$::jsonb) as e
join public.recipes r on (e ? 'id' and r.id = (e->>'id')::uuid) or (e ? 'slug' and r.slug = e->>'slug')
where r.status = 'published'
  and not exists (select 1 from public.recipe_images i where i.recipe_id = r.id and i.status = 'ready');
