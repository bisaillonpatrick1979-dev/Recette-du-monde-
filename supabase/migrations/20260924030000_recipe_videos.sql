-- Vidéos de recettes : les membres peuvent ajouter une vidéo (lien YouTube / Vimeo
-- ou fichier téléversé) sur n'importe quelle recette publiée.
-- À appliquer avec : supabase db push (ou via le tableau de bord Supabase).

create table if not exists public.recipe_videos (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('youtube', 'vimeo', 'upload')),
  external_id text,
  storage_path text,
  caption text check (caption is null or char_length(caption) <= 280),
  created_at timestamptz not null default now(),
  check (
    (provider in ('youtube', 'vimeo') and external_id is not null and storage_path is null)
    or (provider = 'upload' and storage_path is not null and external_id is null)
  ),
  check (external_id is null or external_id ~ '^[A-Za-z0-9_-]{5,32}$')
);

create index if not exists recipe_videos_recipe_idx on public.recipe_videos(recipe_id, created_at desc);
create index if not exists recipe_videos_user_idx on public.recipe_videos(user_id);

alter table public.recipe_videos enable row level security;

revoke all on table public.recipe_videos from anon, authenticated;
grant select on table public.recipe_videos to anon, authenticated;
grant insert, delete on table public.recipe_videos to authenticated;
grant all on table public.recipe_videos to service_role;

drop policy if exists recipe_videos_read_published on public.recipe_videos;
create policy recipe_videos_read_published on public.recipe_videos
for select to anon, authenticated using (
  exists (select 1 from public.recipes r where r.id = recipe_id and r.status = 'published')
  or user_id = (select auth.uid())
);

drop policy if exists recipe_videos_member_insert on public.recipe_videos;
create policy recipe_videos_member_insert on public.recipe_videos
for insert to authenticated with check (
  (select auth.uid()) = user_id
  and exists (select 1 from public.recipes r where r.id = recipe_id and r.status = 'published')
  and (storage_path is null or split_part(storage_path, '/', 1) = (select auth.uid())::text)
);

drop policy if exists recipe_videos_owner_delete on public.recipe_videos;
create policy recipe_videos_owner_delete on public.recipe_videos
for delete to authenticated using ((select auth.uid()) = user_id);

-- Stockage des vidéos téléversées (100 Mo max, formats web)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('recipe-videos', 'recipe-videos', true, 104857600, array['video/mp4', 'video/webm', 'video/quicktime'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Members upload videos in their folder" on storage.objects;
create policy "Members upload videos in their folder" on storage.objects
for insert to authenticated with check (
  bucket_id = 'recipe-videos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Members delete their videos" on storage.objects;
create policy "Members delete their videos" on storage.objects
for delete to authenticated using (
  bucket_id = 'recipe-videos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
