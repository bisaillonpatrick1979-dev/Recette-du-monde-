drop function if exists public.create_recipe_with_content(
  text, text, text, text, text, text,
  public.recipe_authenticity, public.recipe_difficulty,
  integer, integer, numeric, public.recipe_status, jsonb, jsonb
);

create function public.create_recipe_with_content(
  p_title text,
  p_description text default null,
  p_source_language text default 'en',
  p_country_code text default null,
  p_region text default null,
  p_category text default null,
  p_authenticity public.recipe_authenticity default 'adapted',
  p_difficulty public.recipe_difficulty default null,
  p_prep_minutes integer default null,
  p_cook_minutes integer default null,
  p_servings numeric default null,
  p_status public.recipe_status default 'draft',
  p_ingredients jsonb default '[]'::jsonb,
  p_steps jsonb default '[]'::jsonb,
  p_place_id uuid default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_recipe_id uuid;
  v_country_code text := p_country_code;
  v_region text := p_region;
  v_place_name text;
  v_place_type text;
begin
  v_user_id := (select auth.uid());

  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_place_id is not null then
    select cp.country_code, cp.name, cp.place_type
      into v_country_code, v_place_name, v_place_type
    from public.culinary_places cp
    where cp.id = p_place_id
      and cp.is_active = true;

    if not found then
      raise exception 'Unknown or inactive culinary place';
    end if;

    if v_place_type = 'country' then
      v_region := null;
    else
      v_region := v_place_name;
    end if;
  end if;

  insert into public.recipes (
    author_id, title, description, source_language, country_code, region,
    category, authenticity, difficulty, prep_minutes, cook_minutes,
    servings, status, published_at
  )
  values (
    v_user_id, p_title, p_description, p_source_language, v_country_code, v_region,
    p_category, p_authenticity, p_difficulty, p_prep_minutes, p_cook_minutes,
    p_servings, p_status,
    case when p_status = 'published' then now() else null end
  )
  returning id into v_recipe_id;

  insert into public.recipe_ingredients (recipe_id, position, name, quantity, unit, note)
  select
    v_recipe_id,
    (entry.ordinality - 1)::integer,
    entry.item->>'name',
    nullif(entry.item->>'quantity', '')::numeric,
    nullif(entry.item->>'unit', ''),
    nullif(entry.item->>'note', '')
  from jsonb_array_elements(p_ingredients) with ordinality as entry(item, ordinality)
  where coalesce(trim(entry.item->>'name'), '') <> '';

  insert into public.recipe_steps (recipe_id, position, instruction, timer_seconds)
  select
    v_recipe_id,
    (entry.ordinality - 1)::integer,
    entry.item->>'instruction',
    nullif(entry.item->>'timer_seconds', '')::integer
  from jsonb_array_elements(p_steps) with ordinality as entry(item, ordinality)
  where coalesce(trim(entry.item->>'instruction'), '') <> '';

  if p_place_id is not null then
    insert into public.recipe_locations (recipe_id, place_id, relation, is_primary)
    values (v_recipe_id, p_place_id, 'origin', true);
  end if;

  return v_recipe_id;
end;
$$;

revoke all on function public.create_recipe_with_content(
  text, text, text, text, text, text,
  public.recipe_authenticity, public.recipe_difficulty,
  integer, integer, numeric, public.recipe_status, jsonb, jsonb, uuid
) from public, anon;

grant execute on function public.create_recipe_with_content(
  text, text, text, text, text, text,
  public.recipe_authenticity, public.recipe_difficulty,
  integer, integer, numeric, public.recipe_status, jsonb, jsonb, uuid
) to authenticated;
