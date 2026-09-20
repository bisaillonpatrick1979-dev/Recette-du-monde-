alter table public.recipes
  add column if not exists is_editorial boolean not null default false,
  add column if not exists source_name text,
  add column if not exists source_url text,
  add column if not exists source_notes text;

alter table public.place_specialties
  add column if not exists source_name text,
  add column if not exists source_url text;

notify pgrst, 'reload schema';