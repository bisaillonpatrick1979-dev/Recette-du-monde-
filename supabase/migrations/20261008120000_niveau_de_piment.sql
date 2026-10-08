-- Niveau de piment des recettes (0 = pas piquant, 1 = léger, 2 = relevé, 3 = très piquant).
-- Estimé automatiquement d'après les ingrédients (spice_level_source = 'auto'),
-- ou choisi par l'auteur à la publication (spice_level_source = 'author') : le choix de l'auteur n'est jamais écrasé.

alter table public.recipes
  add column if not exists spice_level smallint not null default 0,
  add column if not exists spice_level_source text not null default 'auto';

do $$ begin
  alter table public.recipes add constraint recipes_spice_level_range check (spice_level between 0 and 3);
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.recipes add constraint recipes_spice_level_source_check check (spice_level_source in ('auto', 'author'));
exception when duplicate_object then null; end $$;

create schema if not exists private;

-- Note d'un ingrédient : 3 = piment fort (scotch bonnet, habanero, piri-piri…), 2 = piment courant, 1 = note légère, 0 = rien.
-- Exclusions : piment de la Jamaïque (épice douce), poivron, piment doux, paprika doux, anchois, poivre noir.
create or replace function private.ingredient_spice_points(p_text text)
returns integer
language sql
immutable
set search_path to ''
as $fn$
  select case
    when t ~ '(piment de la jama|allspice|pimienta de jamaica|piment doux|sweet chil|poivron|bell pepper|pimiento morr|paprika doux)' then 0
    when t ~ '(scotch bonnet|habanero|piri.?piri|peri.?peri|piment oiseau|bird.?s eye|\mnaga\M|carolina reaper|locoto|rocoto|wiri|madame jeanette|aj[ií] limo|ghost pepper|cabe rawit|prik kee noo|mitmita)' then 3
    when t ~ '(piment de cheiro|paprika fort|hot paprika|piment d.espelette|poivre du sichuan|sichuan pepper|curry fort)' then 1
    when t ~ '(piment|chili|\mchile\M|chilli|guindilla|jalape|serrano|harissa|sambal|gochujang|gochugaru|cayenne|doubanjiang|sriracha|berbere|chipotle|\maj[ií]\M|pepper sauce|hot sauce|sauce pimentée|\mpili|kochu|nam prik|guajillo|\mancho\M|pasilla|árbol|piquín|pequin|tabasco|zhug|shatta|\mmala\M|\mớt\M|cabai|\mcabe\M|lombok|pul biber|\misot\M|\murfa\M|aleppo pepper|chili flakes|red pepper flakes|crushed red pepper)' then
      case when t ~ '(facultatif|optional|opcional)' then 1 else 2 end
    else 0
  end
  from (select lower(coalesce(p_text, '')) as t) s;
$fn$;

create or replace function private.estimate_spice_level(p_recipe uuid)
returns smallint
language sql
stable
set search_path to ''
as $fn$
  with pts as (
    select private.ingredient_spice_points(i.name || ' ' || coalesce(i.note, '')) as p
    from public.recipe_ingredients i where i.recipe_id = p_recipe
  )
  select (case
    when coalesce(max(p), 0) = 3 then 3
    when coalesce(sum(p), 0) >= 4 then 3
    when coalesce(sum(p), 0) >= 2 then 2
    when coalesce(sum(p), 0) = 1 then 1
    else 0 end)::smallint
  from pts;
$fn$;

-- Recalcul automatique quand les ingrédients changent (sauf si l'auteur a choisi le niveau).
create or replace function private.refresh_recipe_spice_level()
returns trigger
language plpgsql
security definer
set search_path to ''
as $fn$
declare
  v_recipe uuid := coalesce(new.recipe_id, old.recipe_id);
begin
  update public.recipes r
    set spice_level = private.estimate_spice_level(v_recipe)
    where r.id = v_recipe and r.spice_level_source = 'auto';
  return null;
end;
$fn$;

create trigger trg_recipe_ingredients_spice
  after insert or update or delete on public.recipe_ingredients
  for each row execute function private.refresh_recipe_spice_level();

-- Estimation initiale pour toutes les recettes existantes.
update public.recipes r
  set spice_level = private.estimate_spice_level(r.id)
  where r.spice_level_source = 'auto';
