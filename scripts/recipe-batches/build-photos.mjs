// Génère une migration qui publie uniquement les photos vérifiées des recettes des lots.
//
//   node scripts/recipe-batches/build-photos.mjs <nom-de-migration>
//
// Lit data/recipe-batches/photos.json (photos Commons validées une à une, voir find-photos.mjs)
// et remplace la photo externe de chaque recette concernée, sans réimporter les recettes.
// L'identifiant de recette dérive du slug comme dans import-function.sql : relancer ne duplique rien.
import { readFileSync, writeFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

const ROOT = new URL("../../", import.meta.url).pathname;
const DATA_DIR = join(ROOT, "data/recipe-batches");
const [name] = process.argv.slice(2);
if (!name) {
  console.error("Usage : node scripts/recipe-batches/build-photos.mjs <nom-de-migration>");
  process.exit(1);
}

const photos = JSON.parse(readFileSync(join(DATA_DIR, "photos.json"), "utf8"));
const recipes = new Map(
  readdirSync(DATA_DIR)
    .filter((f) => /^batch-.*\.json$/.test(f))
    .flatMap((f) => JSON.parse(readFileSync(join(DATA_DIR, f), "utf8")))
    .map((r) => [r.slug, r]),
);

const errors = [];
const rows = [];
for (const [slug, p] of Object.entries(photos)) {
  const r = recipes.get(slug);
  if (!r) errors.push(`${slug} : recette absente des lots`);
  for (const key of ["url", "page", "license"]) if (!p[key]) errors.push(`${slug} : champ « ${key} » manquant`);
  if (p.url && !p.url.startsWith("https://upload.wikimedia.org/")) errors.push(`${slug} : URL hors upload.wikimedia.org`);
  if (r) rows.push({ slug, title: r.title, ...p });
}
if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}

const payload = JSON.stringify(rows);
if (payload.includes("$photos$")) throw new Error("Le délimiteur $photos$ apparaît dans les données.");

const sql = `-- Photos Spoontrotter générées par scripts/recipe-batches/build-photos.mjs : ${rows.length} recettes des lots.
-- Photos Wikimedia Commons vérifiées une à une (le fichier représente ce plat), auteur et licence conservés.
create temporary table spoontrotter_photos as
select r.id as rid, e
from jsonb_array_elements($photos$${payload}$photos$::jsonb) as e
join public.recipes r on r.id = md5('spoontrotter:recipe:' || (e->>'slug'))::uuid;

delete from public.recipe_images i using spoontrotter_photos p where i.recipe_id = p.rid and i.source_type = 'external_licensed';

insert into public.recipe_images (recipe_id, source_type, status, external_url, alt_text, source_name, source_page_url,
  photographer_name, license_name, license_url, attribution_text, is_primary, is_representative, moderation_notes)
select rid, 'external_licensed', 'ready', e->>'url', e->>'title', 'Wikimedia Commons', e->>'page',
  nullif(e->>'author', ''), e->>'license', nullif(e->>'licenseUrl', ''),
  'Photo : ' || coalesce(nullif(e->>'author', ''), 'auteur inconnu') || ' · ' || (e->>'license') || ' · Wikimedia Commons',
  true, true, 'Photo Wikimedia Commons vérifiée : le fichier représente ce plat.'
from spoontrotter_photos;

update public.recipes r set source_url = p.e->>'page', updated_at = now() from spoontrotter_photos p where r.id = p.rid;

drop table spoontrotter_photos;
`;

const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
const target = join(ROOT, "supabase/migrations", `${stamp}_${name}.sql`);
writeFileSync(target, sql);
console.log(`${rows.length} photos → ${target.replace(ROOT, "")}`);
