// Prépare une charge JSON de photos validées pour des recettes DÉJÀ publiées (sans réimporter les recettes).
//
//   node scripts/recipe-batches/build-photo-payload.mjs <nom> <slug> [slug ...]
//
// - slug d'un lot : l'identifiant de recette est md5('spoontrotter:recipe:' || slug)::uuid (comme import-function.sql);
// - « legacy-<uuid> » : ancienne recette sans slug, identifiée directement par son uuid.
// Les photos viennent de data/recipe-batches/photos.json (validées à l'œil, auteur et licence conservés).
// Sortie : data/recipe-batches/publies/<nom>.json, à charger côté base avec pg_temp.spoontrotter_photos (voir publies/README.md).
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = new URL("../../", import.meta.url).pathname;
const DATA_DIR = join(ROOT, "data/recipe-batches");
const [name, ...slugs] = process.argv.slice(2);
if (!name || !slugs.length) {
  console.error("Usage : node scripts/recipe-batches/build-photo-payload.mjs <nom> <slug> [slug ...]");
  process.exit(1);
}

const photos = JSON.parse(readFileSync(join(DATA_DIR, "photos.json"), "utf8"));
const toUuid = (hex) => `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20, 32)}`;
const recipeId = (slug) =>
  slug.startsWith("legacy-") ? slug.slice(7) : toUuid(createHash("md5").update(`spoontrotter:recipe:${slug}`).digest("hex"));

const errors = [];
const rows = slugs.map((slug) => {
  const p = photos[slug];
  if (!p) errors.push(`${slug} : aucune photo validée dans photos.json`);
  else if (!/^https:\/\/(upload\.wikimedia\.org|live\.staticflickr\.com)\//.test(p.url)) errors.push(`${slug} : hôte d’image non autorisé`);
  return { rid: recipeId(slug), slug, ...p };
});
if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}
const target = join(DATA_DIR, "publies", `${name}.json`);
writeFileSync(target, JSON.stringify(rows));
console.log(`${rows.length} photos → ${target.replace(ROOT, "")}`);
