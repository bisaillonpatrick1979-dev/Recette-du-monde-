alter table public.recipes
  add column if not exists original_title text;

create table if not exists public.recipe_title_translations (
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  language_code text not null,
  title text not null,
  translated_at timestamptz not null default now(),
  model text,
  primary key (recipe_id, language_code)
);

alter table public.recipe_title_translations enable row level security;

drop policy if exists recipe_title_translations_public_read on public.recipe_title_translations;
create policy recipe_title_translations_public_read
on public.recipe_title_translations
for select
using (
  exists (
    select 1
    from public.recipes r
    where r.id = recipe_title_translations.recipe_id
      and (
        r.status = 'published'::recipe_status
        or r.author_id = (select auth.uid())
      )
  )
);

create index if not exists recipe_title_translations_language_idx
  on public.recipe_title_translations(language_code);
