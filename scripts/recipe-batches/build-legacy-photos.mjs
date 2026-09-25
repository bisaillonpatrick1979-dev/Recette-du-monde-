// Génère une migration qui publie les photos vérifiées des recettes plus anciennes (hors lots, sans slug).
//
//   node scripts/recipe-batches/build-legacy-photos.mjs <nom-de-migration>
//
// Lit data/recipe-batches/photos-legacy.json (identifiant de recette → photo Commons validée à l'œil)
// et n'ajoute une photo qu'aux recettes publiées qui n'en ont pas encore : relancer ne duplique rien.
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = new URL("../../", import.meta.url).pathname;
const DATA_DIR = join(ROOT, "data/recipe-batches");
const [name] = process.argv.slice(2);
if (!name) {
  console.error("Usage : node scripts/recipe-batches/build-legacy-photos.mjs <nom-de-migration>");
  process.exit(1);
}

const photos = JSON.parse(readFileSync(join(DATA_DIR, "photos-legacy.json"), "utf8"));
const errors = [];
const rows = [];
for (const [id, p] of Object.entries(photos)) {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(id)) errors.push(`${id} : identifiant invalide`);
  for (const key of ["url", "page", "license"]) if (!p[key]) errors.push(`${id} : champ « ${key} » manquant`);
  if (p.url && !p.url.startsWith("https://upload.wikimedia.org/")) errors.push(`${id} : URL hors upload.wikimedia.org`);
  rows.push({ id, ...p });
}
if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}

const payload = JSON.stringify(rows);
if (payload.includes("$photos$")) throw new Error("Le délimiteur $photos$ apparaît dans les données.");

const sql = `-- Photos générées par scripts/recipe-batches/build-legacy-photos.mjs : ${rows.length} recettes plus anciennes.
-- Photos Wikimedia Commons vérifiées une à une (le fichier représente ce plat), auteur et licence conservés.
insert into public.recipe_images (recipe_id, source_type, status, external_url, alt_text, source_name, source_page_url,
  photographer_name, license_name, license_url, attribution_text, is_primary, is_representative, moderation_notes)
select r.id, 'external_licensed', 'ready', e->>'url', r.title, 'Wikimedia Commons', e->>'page',
  nullif(e->>'author', ''), e->>'license', nullif(e->>'licenseUrl', ''),
  'Photo : ' || coalesce(nullif(e->>'author', ''), 'auteur inconnu') || ' · ' || (e->>'license') || ' · Wikimedia Commons',
  true, true, 'Photo Wikimedia Commons vérifiée : le fichier représente ce plat.'
from jsonb_array_elements($photos$${payload}$photos$::jsonb) as e
join public.recipes r on r.id = (e->>'id')::uuid
where r.status = 'published'
  and not exists (select 1 from public.recipe_images i where i.recipe_id = r.id and i.status = 'ready');
`;

const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
const target = join(ROOT, "supabase/migrations", `${stamp}_${name}.sql`);
writeFileSync(target, sql);
console.log(`${rows.length} photos → ${target.replace(ROOT, "")}`);
