-- Photo Wikimedia Commons vérifiée (le fichier représente ce plat), auteur et licence conservés.
-- Cinquième passe (données structurées Commons « depicts » P180) : 1 photo sur les 148 recettes restantes.
-- N'ajoute la photo que si la recette publiée n'en a pas encore : relancer ne duplique rien.
insert into public.recipe_images (recipe_id, source_type, status, external_url, alt_text, source_name, source_page_url,
  photographer_name, license_name, license_url, attribution_text, is_primary, is_representative, moderation_notes)
select r.id, 'external_licensed', 'ready', 'https://upload.wikimedia.org/wikipedia/commons/d/d1/Potato_salad_001.jpg', r.title,
  'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Potato_salad_001.jpg', 'Ocdp', 'CC0',
  'http://creativecommons.org/publicdomain/zero/1.0/deed.en', 'Photo : Ocdp · CC0 · Wikimedia Commons',
  true, true, 'Photo Wikimedia Commons vérifiée : le fichier représente ce plat.'
from public.recipes r
where r.id = 'ae882ee2-bfbb-4b29-94fd-c6360eb189d7' and r.status = 'published'
  and not exists (select 1 from public.recipe_images i where i.recipe_id = r.id and i.status = 'ready');
