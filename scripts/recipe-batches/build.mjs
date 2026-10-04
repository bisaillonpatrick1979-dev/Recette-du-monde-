// Génère une migration SQL à partir des lots de recettes éditoriales (data/recipe-batches/batch-*.json).
//
//   node scripts/recipe-batches/build.mjs <nom-de-migration> [--avec-photo] [lot.json ...]
//
// --avec-photo : ne publie que les recettes dont la photo a été validée dans photos.json;
// les autres restent dans les lots en attendant une photo exacte.
//
// Chaque recette suit data/editorial-batches/PIPELINE.md : pays ISO, lieu précis seulement
// s'il est documenté, titres FR / EN / ES, ingrédients chiffrés, étapes, et photo seulement
// si elle a été vérifiée (data/recipe-batches/photos.json, produit par resolve-photos.mjs).
// La migration embarque les données en JSON et les charge avec une fonction temporaire :
// l'identifiant de chaque recette dérive de son slug, donc la relancer met à jour sans dupliquer.
import { readFileSync, writeFileSync, existsSync, readdirSync } from "node:fs";
import { join } from "node:path";

const ROOT = new URL("../../", import.meta.url).pathname;
const DATA_DIR = join(ROOT, "data/recipe-batches");
const DIFFICULTIES = new Set(["easy", "medium", "hard"]);
const PLACE_TYPES = new Set(["region", "city", "island", "locality"]);
const REQUIRED = ["slug", "country", "original", "title", "en", "es", "desc", "cat", "diff", "prep", "cook", "serv", "ing", "steps"];

const args = process.argv.slice(2);
const requirePhoto = args.includes("--avec-photo");
const [name, ...files] = args.filter((a) => a !== "--avec-photo");
if (!name) {
  console.error("Usage : node scripts/recipe-batches/build.mjs <nom-de-migration> [lot.json ...]");
  process.exit(1);
}

const batchFiles = (files.length ? files : readdirSync(DATA_DIR).filter((f) => /^batch-.*\.json$/.test(f)).sort()).map((f) =>
  f.includes("/") ? f : join(DATA_DIR, f),
);
// Photos validées : photos.json + fichiers par lot (photos-lots-*.json), fusionnés.
const photos = Object.assign(
  {},
  ...readdirSync(DATA_DIR)
    .filter((f) => f === "photos.json" || /^photos-lots-.*\.json$/.test(f))
    .sort()
    .map((f) => JSON.parse(readFileSync(join(DATA_DIR, f), "utf8"))),
);
const countries = JSON.parse(readFileSync(join(DATA_DIR, "countries.json"), "utf8"));

const errors = [];
const recipes = [];
const places = new Map();
const slugs = new Set();
const skipped = [];

for (const file of batchFiles) {
  for (const r of JSON.parse(readFileSync(file, "utf8"))) {
    const where = `${file.split("/").pop()} › ${r.slug}`;
    for (const key of REQUIRED) if (r[key] === undefined || r[key] === null || r[key] === "") errors.push(`${where} : champ « ${key} » manquant`);
    if (slugs.has(r.slug)) errors.push(`${where} : slug en double`);
    slugs.add(r.slug);
    if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(r.slug ?? "")) errors.push(`${where} : slug invalide`);
    if (!countries[r.country]) errors.push(`${where} : pays ${r.country} inconnu (countries.json)`);
    if (!DIFFICULTIES.has(r.diff)) errors.push(`${where} : difficulté invalide`);
    if (!(Number(r.serv) > 0)) errors.push(`${where} : portions nulles`);
    if (!Array.isArray(r.ing) || r.ing.length < 3) errors.push(`${where} : moins de 3 ingrédients`);
    if (!Array.isArray(r.steps) || r.steps.length < 3) errors.push(`${where} : moins de 3 étapes`);
    for (const ing of r.ing ?? []) {
      if (!Array.isArray(ing) || !ing[0] || (ing[1] !== null && ing[1] !== undefined && !Number.isFinite(ing[1]))) {
        errors.push(`${where} : ingrédient mal formé ${JSON.stringify(ing)}`);
      }
    }
    if (r.place && typeof r.place === "object") {
      const p = r.place;
      if (!PLACE_TYPES.has(p.type)) errors.push(`${where} : type de lieu invalide`);
      if (!(Math.abs(p.lat) <= 90 && Math.abs(p.lng) <= 180)) errors.push(`${where} : coordonnées invalides`);
      const prev = places.get(p.slug);
      if (prev && (prev.name !== p.name || prev.country !== r.country)) errors.push(`${where} : lieu ${p.slug} défini deux fois différemment`);
      places.set(p.slug, { ...p, country: r.country });
    }
    if (requirePhoto && !photos[r.slug]) {
      skipped.push(r.slug);
      continue;
    }
    recipes.push({ ...r, photo: photos[r.slug] ?? null });
  }
}

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}

// Un lieu défini dans ce lot puis référencé par son slug : on embarque sa définition complète,
// pour que la référence fonctionne même si la recette qui le définit attend encore sa photo.
for (const r of recipes) {
  if (typeof r.place === "string" && places.has(r.place)) {
    const { country, ...def } = places.get(r.place);
    r.place = def;
  }
}

const loader = readFileSync(join(ROOT, "scripts/recipe-batches/import-function.sql"), "utf8").trim();
const payload = JSON.stringify(recipes);
if (payload.includes("$batch$")) throw new Error("Le délimiteur $batch$ apparaît dans les données.");

const sql = [
  `-- Lot éditorial Spoontrotter généré par scripts/recipe-batches/build.mjs : ${recipes.length} recettes, ${places.size} nouveaux lieux.`,
  "-- Recettes rédigées pour l'application (adaptations éditoriales) à partir des compositions traditionnelles documentées.",
  "-- Données source : data/recipe-batches/. Photos : Wikimedia Commons, vérifiées une à une (auteur et licence conservés).",
  loader,
  `select pg_temp.spoontrotter_import($batch$${payload}$batch$::jsonb);`,
  "",
].join("\n");

const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
const target = join(ROOT, "supabase/migrations", `${stamp}_${name}.sql`);
writeFileSync(target, sql);
const withPhoto = recipes.filter((r) => r.photo).length;
if (skipped.length) console.log(`En attente de photo (non publiées) : ${skipped.join(", ")}`);
console.log(`${recipes.length} recettes (${withPhoto} avec photo vérifiée), ${places.size} nouveaux lieux, ${(sql.length / 1024).toFixed(0)} Ko → ${target.replace(ROOT, "")}`);
