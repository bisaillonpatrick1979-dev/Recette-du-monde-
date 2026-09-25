// Génère une migration qui publie uniquement les photos validées (data/recipe-batches/photos.json)
// pour des recettes déjà en base, sans réimporter les lots.
//
//   node scripts/recipe-batches/photos-migration.mjs <nom-de-migration>
//
// photos.json associe une clé de recette à un candidat retenu de photo-candidates.json
// ({ file, url, page, author, license, licenseUrl }) après contrôle visuel : la photo doit montrer
// ce plat précis (data/editorial-batches/PIPELINE.md). La clé est le slug d'une recette des lots
// ou l'id d'une recette ancienne (legacy-missing-photos.json). Relancer la migration remplace la
// photo Commons précédente de la recette sans dupliquer ; une photo publiée par un membre reste en place.
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = new URL("../../", import.meta.url).pathname;
const DATA_DIR = join(ROOT, "data/recipe-batches");
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/;

const [name] = process.argv.slice(2);
if (!name) {
  console.error("Usage : node scripts/recipe-batches/photos-migration.mjs <nom-de-migration>");
  process.exit(1);
}

const photos = JSON.parse(readFileSync(join(DATA_DIR, "photos.json"), "utf8"));
const errors = [];
const rows = [];
for (const [key, ph] of Object.entries(photos)) {
  if (!UUID.test(key) && !SLUG.test(key)) errors.push(`${key} : clé invalide (slug ou id attendu)`);
  for (const field of ["url", "page", "license"]) if (!ph?.[field]) errors.push(`${key} : champ « ${field} » manquant`);
  if (ph?.url && !/^https:\/\/upload\.wikimedia\.org\//.test(ph.url)) errors.push(`${key} : l'URL doit venir de upload.wikimedia.org`);
  rows.push({ key, url: ph.url, page: ph.page, author: ph.author ?? "", license: ph.license, licenseUrl: ph.licenseUrl ?? "" });
}
if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}

const payload = JSON.stringify(rows);
if (payload.includes("$photos$")) throw new Error("Le délimiteur $photos$ apparaît dans les données.");

const sql = `-- Photos Wikimedia Commons vérifiées une à une pour des recettes déjà publiées (${rows.length} recettes).
-- Généré par scripts/recipe-batches/photos-migration.mjs depuis data/recipe-batches/photos.json.
create temporary table spoontrotter_photos on commit drop as
select r.id as recipe_id, r.title, e->>'url' as url, e->>'page' as page, nullif(e->>'author', '') as author,
       e->>'license' as license, nullif(e->>'licenseUrl', '') as license_url
from jsonb_array_elements($photos$${payload}$photos$::jsonb) as e
join public.recipes r on r.id::text = e->>'key' or r.slug = e->>'key';

delete from public.recipe_images i
using spoontrotter_photos t
where i.recipe_id = t.recipe_id and i.source_type = 'external_licensed';

insert into public.recipe_images (recipe_id, source_type, status, external_url, alt_text, source_name, source_page_url,
  photographer_name, license_name, license_url, attribution_text, is_primary, is_representative, moderation_notes)
select t.recipe_id, 'external_licensed', 'ready', t.url, t.title, 'Wikimedia Commons', t.page,
  t.author, t.license, t.license_url,
  'Photo : ' || coalesce(t.author, 'auteur inconnu') || ' · ' || t.license || ' · Wikimedia Commons',
  not exists (select 1 from public.recipe_images p where p.recipe_id = t.recipe_id and p.is_primary),
  true, 'Photo Wikimedia Commons vérifiée : le fichier représente ce plat.'
from spoontrotter_photos t;
`;

const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
const target = join(ROOT, "supabase/migrations", `${stamp}_${name}.sql`);
writeFileSync(target, sql);
console.log(`${rows.length} photos → ${target.replace(ROOT, "")}`);
