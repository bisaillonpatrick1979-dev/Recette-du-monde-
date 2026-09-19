create table if not exists public.culinary_places (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  country_code text not null check (char_length(country_code) between 2 and 3),
  place_type text not null check (place_type in ('country','region','island','city','locality')),
  parent_id uuid references public.culinary_places(id) on delete restrict,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  default_zoom double precision not null default 6 check (default_zoom between 1 and 18),
  summary text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists culinary_places_parent_id_idx on public.culinary_places(parent_id);
create index if not exists culinary_places_country_code_idx on public.culinary_places(country_code);
create index if not exists culinary_places_active_idx on public.culinary_places(is_active) where is_active;

alter table public.culinary_places enable row level security;

revoke all on table public.culinary_places from anon, authenticated;
grant select on table public.culinary_places to anon, authenticated;
grant all on table public.culinary_places to service_role;

drop policy if exists "Culinary places are publicly readable" on public.culinary_places;
create policy "Culinary places are publicly readable"
on public.culinary_places for select
to anon, authenticated
using (is_active = true);

create table if not exists public.recipe_locations (
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  place_id uuid not null references public.culinary_places(id) on delete restrict,
  relation text not null default 'origin' check (relation in ('origin','associated')),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (recipe_id, place_id)
);

create index if not exists recipe_locations_place_id_idx on public.recipe_locations(place_id);
create unique index if not exists recipe_locations_one_primary_idx
  on public.recipe_locations(recipe_id)
  where is_primary = true;

alter table public.recipe_locations enable row level security;

revoke all on table public.recipe_locations from anon, authenticated;
grant select on table public.recipe_locations to anon, authenticated;
grant select, insert, delete on table public.recipe_locations to authenticated;
grant all on table public.recipe_locations to service_role;

drop policy if exists "Visible recipe locations are readable" on public.recipe_locations;
create policy "Visible recipe locations are readable"
on public.recipe_locations for select
to anon, authenticated
using (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_locations.recipe_id
      and (r.status = 'published'::public.recipe_status or r.author_id = (select auth.uid()))
  )
);

drop policy if exists "Authors can add locations to own recipes" on public.recipe_locations;
create policy "Authors can add locations to own recipes"
on public.recipe_locations for insert
to authenticated
with check (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_locations.recipe_id
      and r.author_id = (select auth.uid())
  )
);

drop policy if exists "Authors can remove locations from own recipes" on public.recipe_locations;
create policy "Authors can remove locations from own recipes"
on public.recipe_locations for delete
to authenticated
using (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_locations.recipe_id
      and r.author_id = (select auth.uid())
  )
);

insert into public.culinary_places
  (slug, name, country_code, place_type, latitude, longitude, default_zoom, summary)
values
  ('cd', 'République démocratique du Congo', 'CD', 'country', -2.88, 23.65, 4.2, 'Explorer les cuisines de la République démocratique du Congo.'),
  ('id', 'Indonésie', 'ID', 'country', -2.55, 118.01, 4.0, 'Explorer les cuisines régionales de l’archipel indonésien.'),
  ('it', 'Italie', 'IT', 'country', 42.50, 12.50, 4.8, 'Explorer les traditions culinaires italiennes par région et ville.'),
  ('mx', 'Mexique', 'MX', 'country', 23.63, -102.55, 4.2, 'Explorer les cuisines régionales du Mexique.'),
  ('th', 'Thaïlande', 'TH', 'country', 15.87, 100.99, 5.0, 'Explorer les cuisines du nord, du centre et du sud de la Thaïlande.'),
  ('ma', 'Maroc', 'MA', 'country', 31.79, -7.09, 5.0, 'Explorer les traditions culinaires marocaines par région et ville.'),
  ('jp', 'Japon', 'JP', 'country', 36.20, 138.25, 4.5, 'Explorer les cuisines régionales du Japon.')
on conflict (slug) do update set
  name = excluded.name,
  country_code = excluded.country_code,
  place_type = excluded.place_type,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  default_zoom = excluded.default_zoom,
  summary = excluded.summary,
  is_active = true;

insert into public.culinary_places
  (slug, name, country_code, place_type, parent_id, latitude, longitude, default_zoom, summary)
values
  ('cd-kinshasa', 'Kinshasa', 'CD', 'city', (select id from public.culinary_places where slug='cd'), -4.325, 15.3222, 8, 'Explorer les recettes et traditions documentées autour de Kinshasa.'),
  ('cd-sud-kivu', 'Sud-Kivu', 'CD', 'region', (select id from public.culinary_places where slug='cd'), -2.496, 28.8608, 7, 'Distinguer les traditions culinaires de l’est de la RDC.'),
  ('cd-haut-katanga', 'Haut-Katanga', 'CD', 'region', (select id from public.culinary_places where slug='cd'), -11.6647, 27.4794, 7, 'Explorer séparément les recettes du sud-est congolais.'),
  ('id-bali', 'Bali', 'ID', 'island', (select id from public.culinary_places where slug='id'), -8.4095, 115.1889, 8, 'Explorer la cuisine balinaise comme tradition régionale distincte.'),
  ('it-campania', 'Campanie', 'IT', 'region', (select id from public.culinary_places where slug='it'), 40.85, 14.27, 7, 'Explorer les traditions culinaires de Campanie.'),
  ('mx-oaxaca-state', 'Oaxaca', 'MX', 'region', (select id from public.culinary_places where slug='mx'), 17.05, -96.70, 7, 'Explorer les traditions culinaires de l’État de Oaxaca.'),
  ('th-chiang-mai-region', 'Chiang Mai', 'TH', 'region', (select id from public.culinary_places where slug='th'), 18.79, 98.98, 7, 'Explorer la cuisine du nord de la Thaïlande.'),
  ('ma-fes-meknes', 'Fès-Meknès', 'MA', 'region', (select id from public.culinary_places where slug='ma'), 34.03, -5.00, 7, 'Explorer les traditions culinaires de Fès-Meknès.'),
  ('jp-hokkaido', 'Hokkaidō', 'JP', 'region', (select id from public.culinary_places where slug='jp'), 43.22, 142.86, 6.5, 'Explorer les spécialités culinaires de Hokkaidō.')
on conflict (slug) do update set
  name = excluded.name, country_code = excluded.country_code, place_type = excluded.place_type,
  parent_id = excluded.parent_id, latitude = excluded.latitude, longitude = excluded.longitude,
  default_zoom = excluded.default_zoom, summary = excluded.summary, is_active = true;

insert into public.culinary_places
  (slug, name, country_code, place_type, parent_id, latitude, longitude, default_zoom, summary)
values
  ('cd-bukavu', 'Bukavu', 'CD', 'city', (select id from public.culinary_places where slug='cd-sud-kivu'), -2.5083, 28.8608, 10, 'Explorer les recettes liées à Bukavu et au Sud-Kivu.'),
  ('id-ubud', 'Ubud', 'ID', 'city', (select id from public.culinary_places where slug='id-bali'), -8.5069, 115.2625, 12, 'Découvrir des recettes et créateurs locaux autour d’Ubud.'),
  ('it-naples', 'Naples', 'IT', 'city', (select id from public.culinary_places where slug='it-campania'), 40.8518, 14.2681, 10, 'Explorer la cuisine napolitaine sans la mélanger à toute la cuisine italienne.'),
  ('mx-oaxaca-city', 'Oaxaca de Juárez', 'MX', 'city', (select id from public.culinary_places where slug='mx-oaxaca-state'), 17.0732, -96.7266, 10, 'Explorer les recettes et marchés culinaires de Oaxaca de Juárez.'),
  ('th-chiang-mai-city', 'Chiang Mai', 'TH', 'city', (select id from public.culinary_places where slug='th-chiang-mai-region'), 18.7883, 98.9853, 10, 'Découvrir les spécialités de la ville de Chiang Mai.'),
  ('ma-fez', 'Fès', 'MA', 'city', (select id from public.culinary_places where slug='ma-fes-meknes'), 34.0181, -5.0078, 10, 'Explorer la cuisine fassie au niveau de la ville.'),
  ('jp-sapporo', 'Sapporo', 'JP', 'city', (select id from public.culinary_places where slug='jp-hokkaido'), 43.0618, 141.3545, 10, 'Découvrir les spécialités de Sapporo.')
on conflict (slug) do update set
  name = excluded.name, country_code = excluded.country_code, place_type = excluded.place_type,
  parent_id = excluded.parent_id, latitude = excluded.latitude, longitude = excluded.longitude,
  default_zoom = excluded.default_zoom, summary = excluded.summary, is_active = true;

notify pgrst, 'reload schema';
