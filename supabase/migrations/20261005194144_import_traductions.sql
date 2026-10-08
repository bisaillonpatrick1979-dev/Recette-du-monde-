-- Outil d'import des traductions de recettes (description, ingrédients, étapes).
-- Schéma « outils » non exposé par l'API : seule l'équipe (rôle postgres) peut l'appeler.
--
-- Usage, en deux temps (pg_net est asynchrone) :
--   select net.http_get('https://raw.githubusercontent.com/<dépôt>/<commit>/data/translations/fr/wb-001.json');
--   select * from outils.importer_traductions(<id de la requête>, '<md5 du fichier>', 'fr', 'claude-traduction-2026-10-05');
--
-- Format du fichier : [{ "id": uuid, "d": description, "i": [[nom, note], ...], "s": [étape, ...] }]
-- Une traduction n'est importée que si elle a autant d'ingrédients que la recette d'origine
-- (les quantités et unités sont reprises de l'original, ligne par ligne).
create schema if not exists outils;
revoke all on schema outils from public, anon, authenticated;

create or replace function outils.importer_traductions(requete bigint, md5_attendu text, langue text, modele text)
returns table (recette uuid, statut text)
language plpgsql
set search_path = public, net
as $fn$
declare
  contenu text;
  lot jsonb;
begin
  select r.content into contenu from net._http_response r where r.id = requete and r.status_code = 200;
  if contenu is null then
    raise exception 'Réponse % absente ou en erreur', requete;
  end if;
  if md5(contenu) <> md5_attendu then
    raise exception 'Empreinte différente : % au lieu de %', md5(contenu), md5_attendu;
  end if;
  lot := contenu::jsonb;

  return query
  with b as (
    select (e->>'id')::uuid as id, e->>'d' as d, e->'i' as i, e->'s' as s
    from jsonb_array_elements(lot) e
  ),
  verifie as (
    select b.*,
      (select count(*) from recipe_ingredients x where x.recipe_id = b.id) as nb_ingredients,
      exists (select 1 from recipes r where r.id = b.id) as existe
    from b
  ),
  importe as (
    insert into recipe_translations (recipe_id, language_code, title, description, ingredients, steps, translated_at, model)
    select v.id, langue,
      (select t.title from recipe_title_translations t where t.recipe_id = v.id and t.language_code = langue),
      v.d,
      (select jsonb_agg(jsonb_build_object('name', ing->>0, 'note', ing->>1) order by o)
         from jsonb_array_elements(v.i) with ordinality as z(ing, o)),
      v.s, now(), modele
    from verifie v
    where v.existe and jsonb_array_length(v.i) = v.nb_ingredients
    on conflict (recipe_id, language_code) do update set
      title = excluded.title, description = excluded.description, ingredients = excluded.ingredients,
      steps = excluded.steps, translated_at = excluded.translated_at, model = excluded.model
    returning recipe_id
  )
  select v.id,
    case
      when not v.existe then 'recette introuvable'
      when jsonb_array_length(v.i) <> v.nb_ingredients
        then format('ingrédients : %s au lieu de %s', jsonb_array_length(v.i), v.nb_ingredients)
      else 'importée'
    end
  -- (Postgres exécute toujours l'INSERT de la CTE « importe », même sans y faire référence.)
  from verifie v;
end;
$fn$;

revoke all on function outils.importer_traductions(bigint, text, text, text) from public, anon, authenticated;
