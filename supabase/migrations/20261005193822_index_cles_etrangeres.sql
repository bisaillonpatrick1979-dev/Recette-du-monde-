-- Index des clés étrangères signalées par l'assistant de performance Supabase.
-- Sans index, chaque suppression ou mise à jour d'un profil ou d'une image parcourt toute la table liée.
create index if not exists image_jobs_requested_by_idx on public.image_jobs (requested_by);
create index if not exists image_jobs_result_place_image_id_idx on public.image_jobs (result_place_image_id);
create index if not exists image_jobs_result_recipe_image_id_idx on public.image_jobs (result_recipe_image_id);
create index if not exists place_images_created_by_idx on public.place_images (created_by);
create index if not exists place_specialties_created_by_idx on public.place_specialties (created_by);
create index if not exists recipe_images_created_by_idx on public.recipe_images (created_by);
create index if not exists recipes_cover_image_id_idx on public.recipes (cover_image_id);
create index if not exists recipes_hero_image_id_idx on public.recipes (hero_image_id);
