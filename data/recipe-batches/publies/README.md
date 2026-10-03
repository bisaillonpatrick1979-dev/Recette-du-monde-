# Lots publiés

Chaque fichier JSON est la charge exacte d'une migration `supabase/migrations/*_<nom>.sql`
(recettes avec photo validée à l'œil seulement, générées par `build.mjs --avec-photo`).

La base Supabase peut les lire directement depuis GitHub (extension `pg_net`), à une révision figée :

```sql
select net.http_get('https://raw.githubusercontent.com/bisaillonpatrick1979-dev/recette-du-monde-/<commit>/data/recipe-batches/publies/<nom>.json');
-- puis, avec l'identifiant renvoyé :
select pg_temp.spoontrotter_import((select content::jsonb from net._http_response where id = <id>));
```

L'import est idempotent : l'identifiant de chaque recette dérive de son slug.
