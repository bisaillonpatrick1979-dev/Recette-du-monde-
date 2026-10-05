-- Exporte un lot de recettes publiées qui n'ont pas encore de traduction de contenu
-- dans la langue cible. Sert au pipeline de traduction (data/translations/).
-- « exclure » permet d'écarter les recettes importées dans la même requête
-- (les écritures d'un CTE ne sont pas visibles ailleurs dans la même instruction).
create or replace function outils.lot_a_traduire(
  source text,
  cible text,
  n integer default 25,
  exclure uuid[] default '{}'
) returns json
language sql
stable
set search_path = public, outils
as $$
  with r as (
    select id, title, description
    from recipes
    where status = 'published'
      and source_language = source
      and not exists (
        select 1 from recipe_translations t
        where t.recipe_id = recipes.id and t.language_code = cible
      )
      and not (id = any(exclure))
    order by id
    limit n
  )
  select json_build_object(
    'restant', (
      select count(*) from recipes
      where status = 'published' and source_language = source
        and not exists (select 1 from recipe_translations t where t.recipe_id = recipes.id and t.language_code = cible)
    ) - coalesce(array_length(exclure, 1), 0),
    'lot', (
      select json_agg(json_build_object(
        'id', r.id,
        't', r.title,
        'd', r.description,
        'i', (select json_agg(case when i.note is null or i.note = '' then to_json(i.name)
                                   else json_build_array(i.name, i.note) end order by i.position)
              from recipe_ingredients i where i.recipe_id = r.id),
        's', (select json_agg(s.instruction order by s.position)
              from recipe_steps s where s.recipe_id = r.id)
      ) order by r.id)
      from r
    )
  );
$$;

revoke all on function outils.lot_a_traduire(text, text, integer, uuid[]) from public, anon, authenticated;
