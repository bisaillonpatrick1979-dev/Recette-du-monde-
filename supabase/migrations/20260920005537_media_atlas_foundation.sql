create extension if not exists pg_trgm;

do $$
begin
  if not exists (select 1 from pg_type where typnamespace='public'::regnamespace and typname='media_source_type') then
    create type public.media_source_type as enum ('external_licensed','generated','user_uploaded');
  end if;
  if not exists (select 1 from pg_type where typnamespace='public'::regnamespace and typname='media_status') then
    create type public.media_status as enum ('pending','ready','rejected','archived');
  end if;
  if not exists (select 1 from pg_type where typnamespace='public'::regnamespace and typname='job_status') then
    create type public.job_status as enum ('queued','processing','done','failed','cancelled');
  end if;
end $$;

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$ begin new.updated_at = now(); return new; end; $$;

create table if not exists public.place_aliases (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.culinary_places(id) on delete cascade,
  alias text not null,
  locale text not null default 'und',
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  unique(place_id, alias, locale)
);
create index if not exists place_aliases_place_idx on public.place_aliases(place_id);
create index if not exists place_aliases_alias_trgm_idx on public.place_aliases using gin(alias gin_trgm_ops);
alter table public.place_aliases enable row level security;
revoke all on public.place_aliases from anon, authenticated;
grant select on public.place_aliases to anon, authenticated;
grant all on public.place_aliases to service_role;
drop policy if exists "Place aliases are publicly readable" on public.place_aliases;
create policy "Place aliases are publicly readable" on public.place_aliases for select to anon, authenticated using (true);

create table if not exists public.place_specialties (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.culinary_places(id) on delete cascade,
  recipe_id uuid references public.recipes(id) on delete set null,
  name text not null,
  description text,
  origin_note text,
  is_signature boolean not null default false,
  sort_order integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists place_specialties_place_idx on public.place_specialties(place_id);
create index if not exists place_specialties_recipe_idx on public.place_specialties(recipe_id);
create index if not exists place_specialties_sort_idx on public.place_specialties(place_id, is_signature desc, sort_order, name);
drop trigger if exists trg_place_specialties_updated_at on public.place_specialties;
create trigger trg_place_specialties_updated_at before update on public.place_specialties for each row execute function public.set_updated_at();
alter table public.place_specialties enable row level security;
revoke all on public.place_specialties from anon, authenticated;
grant select on public.place_specialties to anon, authenticated;
grant all on public.place_specialties to service_role;
drop policy if exists "Place specialties are publicly readable" on public.place_specialties;
create policy "Place specialties are publicly readable" on public.place_specialties for select to anon, authenticated using (true);

create table if not exists public.recipe_images (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  source_type public.media_source_type not null,
  status public.media_status not null default 'pending',
  storage_path text,
  external_url text,
  thumbnail_url text,
  alt_text text,
  caption text,
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  source_name text,
  source_page_url text,
  photographer_name text,
  photographer_url text,
  license_name text,
  license_url text,
  attribution_text text,
  generated_prompt text,
  generated_model text,
  is_primary boolean not null default false,
  is_representative boolean not null default true,
  moderation_notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (storage_path is not null or external_url is not null)
);
create index if not exists recipe_images_recipe_idx on public.recipe_images(recipe_id);
create index if not exists recipe_images_status_idx on public.recipe_images(status);
create unique index if not exists recipe_images_one_primary_idx on public.recipe_images(recipe_id) where is_primary;
drop trigger if exists trg_recipe_images_updated_at on public.recipe_images;
create trigger trg_recipe_images_updated_at before update on public.recipe_images for each row execute function public.set_updated_at();
alter table public.recipe_images enable row level security;
revoke all on public.recipe_images from anon, authenticated;
grant select on public.recipe_images to anon, authenticated;
grant select, insert, update, delete on public.recipe_images to authenticated;
grant all on public.recipe_images to service_role;
drop policy if exists "Ready recipe images are readable" on public.recipe_images;
create policy "Ready recipe images are readable" on public.recipe_images for select to anon, authenticated
using (status = 'ready'::public.media_status and exists (
  select 1 from public.recipes r where r.id = recipe_images.recipe_id
  and (r.status = 'published'::public.recipe_status or r.author_id = (select auth.uid()))
));
drop policy if exists "Authors can add user recipe images" on public.recipe_images;
create policy "Authors can add user recipe images" on public.recipe_images for insert to authenticated
with check (source_type = 'user_uploaded'::public.media_source_type and created_by = (select auth.uid())
and exists (select 1 from public.recipes r where r.id = recipe_images.recipe_id and r.author_id = (select auth.uid())));
drop policy if exists "Authors can update own user recipe images" on public.recipe_images;
create policy "Authors can update own user recipe images" on public.recipe_images for update to authenticated
using (source_type = 'user_uploaded'::public.media_source_type and created_by = (select auth.uid())
and exists (select 1 from public.recipes r where r.id = recipe_images.recipe_id and r.author_id = (select auth.uid())))
with check (source_type = 'user_uploaded'::public.media_source_type and created_by = (select auth.uid())
and exists (select 1 from public.recipes r where r.id = recipe_images.recipe_id and r.author_id = (select auth.uid())));
drop policy if exists "Authors can delete own user recipe images" on public.recipe_images;
create policy "Authors can delete own user recipe images" on public.recipe_images for delete to authenticated
using (source_type = 'user_uploaded'::public.media_source_type and created_by = (select auth.uid())
and exists (select 1 from public.recipes r where r.id = recipe_images.recipe_id and r.author_id = (select auth.uid())));

create table if not exists public.place_images (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.culinary_places(id) on delete cascade,
  source_type public.media_source_type not null,
  status public.media_status not null default 'pending',
  storage_path text,
  external_url text,
  thumbnail_url text,
  alt_text text,
  caption text,
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  source_name text,
  source_page_url text,
  photographer_name text,
  photographer_url text,
  license_name text,
  license_url text,
  attribution_text text,
  generated_prompt text,
  generated_model text,
  is_primary boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (storage_path is not null or external_url is not null)
);
create index if not exists place_images_place_idx on public.place_images(place_id);
create unique index if not exists place_images_one_primary_idx on public.place_images(place_id) where is_primary;
drop trigger if exists trg_place_images_updated_at on public.place_images;
create trigger trg_place_images_updated_at before update on public.place_images for each row execute function public.set_updated_at();
alter table public.place_images enable row level security;
revoke all on public.place_images from anon, authenticated;
grant select on public.place_images to anon, authenticated;
grant all on public.place_images to service_role;
drop policy if exists "Ready place images are publicly readable" on public.place_images;
create policy "Ready place images are publicly readable" on public.place_images for select to anon, authenticated
using (status = 'ready'::public.media_status);

create table if not exists public.image_jobs (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in ('recipe','place')),
  recipe_id uuid references public.recipes(id) on delete cascade,
  place_id uuid references public.culinary_places(id) on delete cascade,
  job_kind text not null check (job_kind in ('find_external','generate_image')),
  query_text text,
  prompt_text text,
  provider text,
  status public.job_status not null default 'queued',
  result_recipe_image_id uuid references public.recipe_images(id) on delete set null,
  result_place_image_id uuid references public.place_images(id) on delete set null,
  error_message text,
  requested_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((entity_type='recipe' and recipe_id is not null and place_id is null) or
         (entity_type='place' and place_id is not null and recipe_id is null))
);
create index if not exists image_jobs_status_idx on public.image_jobs(status, created_at);
create index if not exists image_jobs_recipe_idx on public.image_jobs(recipe_id);
create index if not exists image_jobs_place_idx on public.image_jobs(place_id);
drop trigger if exists trg_image_jobs_updated_at on public.image_jobs;
create trigger trg_image_jobs_updated_at before update on public.image_jobs for each row execute function public.set_updated_at();
alter table public.image_jobs enable row level security;
revoke all on public.image_jobs from anon, authenticated;
grant select, insert on public.image_jobs to authenticated;
grant all on public.image_jobs to service_role;
drop policy if exists "Users can read own image jobs" on public.image_jobs;
create policy "Users can read own image jobs" on public.image_jobs for select to authenticated
using (requested_by = (select auth.uid()));
drop policy if exists "Authors can request recipe image jobs" on public.image_jobs;
create policy "Authors can request recipe image jobs" on public.image_jobs for insert to authenticated
with check (entity_type='recipe' and recipe_id is not null and place_id is null
and requested_by = (select auth.uid())
and exists (select 1 from public.recipes r where r.id = image_jobs.recipe_id and r.author_id = (select auth.uid())));

alter table public.recipes
  add column if not exists slug text,
  add column if not exists excerpt text,
  add column if not exists primary_place_id uuid references public.culinary_places(id) on delete set null,
  add column if not exists cover_image_id uuid,
  add column if not exists hero_image_id uuid,
  add column if not exists search_text text;
create unique index if not exists recipes_slug_unique_idx on public.recipes(slug) where slug is not null;
create index if not exists recipes_primary_place_idx on public.recipes(primary_place_id);
create index if not exists recipes_search_text_trgm_idx on public.recipes using gin(search_text gin_trgm_ops);

do $$
begin
  if not exists (select 1 from pg_constraint where conname='recipes_cover_image_fk') then
    alter table public.recipes add constraint recipes_cover_image_fk foreign key (cover_image_id) references public.recipe_images(id) on delete set null;
  end if;
  if not exists (select 1 from pg_constraint where conname='recipes_hero_image_fk') then
    alter table public.recipes add constraint recipes_hero_image_fk foreign key (hero_image_id) references public.recipe_images(id) on delete set null;
  end if;
end $$;

create or replace function public.refresh_recipe_search_text()
returns trigger language plpgsql set search_path = ''
as $$ begin
  new.search_text := trim(coalesce(new.title,'') || ' ' || coalesce(new.description,'') || ' ' ||
    coalesce(new.category,'') || ' ' || coalesce(new.country_code,'') || ' ' || coalesce(new.region,''));
  return new;
end; $$;
drop trigger if exists trg_recipes_search_text on public.recipes;
create trigger trg_recipes_search_text before insert or update of title, description, category, country_code, region
on public.recipes for each row execute function public.refresh_recipe_search_text();
update public.recipes set search_text = trim(coalesce(title,'') || ' ' || coalesce(description,'') || ' ' ||
  coalesce(category,'') || ' ' || coalesce(country_code,'') || ' ' || coalesce(region,''))
where search_text is null;

create or replace function public.get_place_descendants(root_place uuid)
returns table(id uuid) language sql stable security invoker set search_path = ''
as $$ with recursive tree as (
  select cp.id from public.culinary_places cp where cp.id = root_place
  union all
  select child.id from public.culinary_places child join tree t on child.parent_id = t.id where child.is_active = true
) select tree.id from tree; $$;
revoke all on function public.get_place_descendants(uuid) from public;
grant execute on function public.get_place_descendants(uuid) to anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('place-images','place-images',true,10485760,array['image/jpeg','image/png','image/webp','image/avif']::text[])
on conflict (id) do update set public=excluded.public, file_size_limit=excluded.file_size_limit, allowed_mime_types=excluded.allowed_mime_types;

notify pgrst, 'reload schema';