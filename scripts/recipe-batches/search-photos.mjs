// Robot de recherche photo — cherche des photos libres candidates pour les recettes des lots.
//
//   node scripts/recipe-batches/search-photos.mjs <dossier-sortie> [lot.json ...]
//
// Sources (photos libres, usage commercial permis, auteur et licence conservés) :
//   1. Wikimedia Commons — recherche plein texte + catégories (« Category:Cassoulet »);
//   2. Openverse (Flickr) — seulement en complément quand Commons trouve peu de choses
//      (le débit anonyme d'Openverse est limité).
// Licences acceptées : CC0, domaine public, CC BY, CC BY-SA. Refusées : NC (non commercial) et ND.
//
// Requêtes supplémentaires par recette : data/recipe-batches/photo-queries.json
//   { "cassoulet-de-castelnaudary": ["Category:Cassoulet", "cassoulet Castelnaudary"] }
//
// Résultat dans <dossier-sortie> : candidates.json + thumbs/<slug>--<n>.jpg (miniatures à contrôler à l'œil).
// Rien n'est publié ici : une photo n'entre dans photos.json qu'après validation visuelle
// (règle stricte de data/editorial-batches/PIPELINE.md : la photo doit montrer CE plat).
// Conçu pour tourner dans GitHub Actions (.github/workflows/photo-search.yml).
import { readFileSync, writeFileSync, existsSync, readdirSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const ROOT = new URL("../../", import.meta.url).pathname;
const DATA_DIR = join(ROOT, "data/recipe-batches");
const [OUT, ...files] = process.argv.slice(2);
if (!OUT) {
  console.error("Usage : node scripts/recipe-batches/search-photos.mjs <dossier-sortie> [lot.json ...]");
  process.exit(1);
}
const THUMBS = join(OUT, "thumbs");
mkdirSync(THUMBS, { recursive: true });

const COMMONS = "https://commons.wikimedia.org/w/api.php";
const OPENVERSE = "https://api.openverse.org/v1/images/";
const USER_AGENT = "Spoontrotter/1.0 (https://github.com/bisaillonpatrick1979-dev/Recette-du-monde-)";
const MAX_COMMONS = 6;
const MAX_OPENVERSE = 4;
const STOPWORDS = new Set(["with", "and", "the", "avec", "aux", "des", "del", "con", "sauce", "style", "recipe", "food", "dish", "from"]);

// Licence libre ET compatible avec un usage commercial (pas de NC ni de ND).
function freeLicense(raw) {
  const l = (raw ?? "").toLowerCase().trim();
  if (!l || /\bnc\b|non-?commercial|\bnd\b|no-?deriv/.test(l)) return false;
  return /^(cc0|cc-?0|public domain|pd|pdm|cc by(-sa)?\b|cc-by(-sa)?\b|by(-sa)?$)/.test(l);
}

const normalize = (s) => (s ?? "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
const tokens = (s) =>
  normalize(s)
    .replace(/\(.*?\)/g, " ")
    .split(/[^a-z0-9]+/)
    .filter((t) => t.length >= 4 && !STOPWORDS.has(t));
const stripTags = (s) => (s ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let consecutiveFailures = 0;
async function getJson(url) {
  // Les deux API limitent le débit (429) : on respecte Retry-After, sinon on attend de plus en plus longtemps.
  for (let attempt = 0; attempt < 7; attempt += 1) {
    const res = await fetch(url, { headers: { "User-Agent": USER_AGENT, Accept: "application/json" } });
    if (res.status === 404) return null;
    const text = await res.text();
    if (res.ok) {
      try {
        const json = JSON.parse(text);
        consecutiveFailures = 0;
        return json;
      } catch {
        // Page HTML (anti-robot, maintenance…) au lieu de JSON : on note et on réessaie.
        console.warn(`Réponse non JSON (${res.status}) pour ${url.slice(0, 120)} : ${text.replace(/\s+/g, " ").slice(0, 400)}`);
      }
    } else {
      console.warn(`HTTP ${res.status} pour ${url.slice(0, 120)} : ${text.replace(/\s+/g, " ").slice(0, 200)}`);
    }
    consecutiveFailures += 1;
    if (consecutiveFailures >= 12) throw new Error("Trop d’échecs consécutifs : la source bloque probablement le robot.");
    const retryAfter = Number(res.headers.get("retry-after"));
    await sleep(retryAfter > 0 ? Math.min(retryAfter, 120) * 1000 : 4000 * 2 ** Math.min(attempt, 4));
  }
  console.warn(`Abandon : ${url}`);
  return null;
}

async function commons(params) {
  const data = await getJson(`${COMMONS}?${new URLSearchParams({ action: "query", format: "json", origin: "*", ...params })}`);
  return Object.values(data?.query?.pages ?? {});
}

const IMAGEINFO = { prop: "imageinfo", iiprop: "url|extmetadata|size|mime", iiurlwidth: "1280" };

async function commonsQuery(query) {
  if (/^category:/i.test(query)) {
    return commons({ generator: "categorymembers", gcmtitle: query, gcmtype: "file", gcmlimit: "20", ...IMAGEINFO });
  }
  return commons({ generator: "search", gsrsearch: `${query} filetype:bitmap`, gsrnamespace: "6", gsrlimit: "15", ...IMAGEINFO });
}

function commonsCandidate(page, fromCategory, wanted) {
  const info = page.imageinfo?.[0];
  if (!info || !/^image\/(jpeg|png|webp)$/.test(info.mime ?? "") || (info.width ?? 0) < 500) return null;
  const meta = info.extmetadata ?? {};
  const license = stripTags(meta.LicenseShortName?.value);
  if (!freeLicense(license)) return null;
  const description = stripTags(meta.ImageDescription?.value).slice(0, 300);
  if (!fromCategory) {
    const hay = normalize(`${page.title} ${description}`);
    if (![...wanted].some((t) => hay.includes(t))) return null;
  }
  // Même hôte que les photos déjà publiées (upload.wikimedia.org, autorisé par next.config.ts).
  const url = (info.thumburl ?? info.url).replace("https://thumb.wikimedia.org/", "https://upload.wikimedia.org/").replace(/\?.*$/, "");
  return {
    source: "Wikimedia Commons",
    file: page.title,
    url,
    preview: url.includes("/thumb/") ? url.replace(/\/1280px-/, "/500px-") : url,
    page: info.descriptionurl,
    author: stripTags(meta.Artist?.value).slice(0, 200),
    license,
    licenseUrl: stripTags(meta.LicenseUrl?.value) || null,
    description,
  };
}

let openverseCalls = 0;
async function openverse(query) {
  if (openverseCalls >= 180) return []; // garde-fou pour le quota anonyme quotidien
  openverseCalls += 1;
  const params = new URLSearchParams({ q: query, license: "by,by-sa,cc0,pdm", source: "flickr", page_size: "10", mature: "false" });
  const data = await getJson(`${OPENVERSE}?${params}`);
  await sleep(3500); // débit anonyme : ~20 requêtes par minute
  return (data?.results ?? [])
    .filter((r) => freeLicense(`${r.license === "cc0" || r.license === "pdm" ? r.license : `cc ${r.license}`}`))
    .filter((r) => (r.width ?? 1000) >= 500)
    .map((r) => ({
      source: "Flickr (via Openverse)",
      file: r.title ?? r.id,
      url: r.url,
      preview: r.url,
      page: r.foreign_landing_url,
      author: (r.creator ?? "").slice(0, 200),
      license: r.license === "cc0" ? "CC0" : r.license === "pdm" ? "Public domain" : `CC ${r.license.toUpperCase()} ${r.license_version ?? ""}`.trim(),
      licenseUrl: r.license_url ?? null,
      description: [r.title, ...(r.tags ?? []).slice(0, 8).map((t) => t.name)].filter(Boolean).join(" · ").slice(0, 300),
    }));
}

async function download(url, target) {
  for (let attempt = 0; attempt < 4; attempt += 1) {
    const res = await fetch(url, { headers: { "User-Agent": USER_AGENT } });
    if (res.ok) {
      writeFileSync(target, Buffer.from(await res.arrayBuffer()));
      return true;
    }
    if (res.status === 404) return false;
    await sleep(3000 * (attempt + 1));
  }
  return false;
}

const batchFiles = (files.length ? files : readdirSync(DATA_DIR).filter((f) => /^batch-.*\.json$/.test(f)).sort()).map((f) =>
  f.includes("/") ? f : join(DATA_DIR, f),
);
const photos = existsSync(join(DATA_DIR, "photos.json")) ? JSON.parse(readFileSync(join(DATA_DIR, "photos.json"), "utf8")) : {};
const queriesPath = join(DATA_DIR, "photo-queries.json");
const extraQueries = existsSync(queriesPath) ? JSON.parse(readFileSync(queriesPath, "utf8")) : {};
// « __ignorer__ » dans photo-queries.json : recette mise de côté (aucune photo libre exacte trouvée après plusieurs passes).
const recipes = batchFiles
  .flatMap((f) => JSON.parse(readFileSync(f, "utf8")))
  .filter((r) => !photos[r.slug] && !(extraQueries[r.slug] ?? []).includes("__ignorer__"));

const out = {};
let withCandidates = 0;
for (const [index, r] of recipes.entries()) {
  const name = r.original.replace(/\(.*?\)/g, "").trim();
  const en = r.en.replace(/\(.*?\)/g, "").trim();
  const wanted = new Set(tokens(name).length ? tokens(name) : tokens(en));
  const queries = [...new Set([...(extraQueries[r.slug] ?? []), name, en])];
  const seen = new Map();
  for (const query of queries) {
    if (seen.size >= MAX_COMMONS * 2) break;
    const fromCategory = /^category:/i.test(query);
    for (const page of await commonsQuery(query)) {
      const c = commonsCandidate(page, fromCategory, wanted);
      if (c && !seen.has(c.file)) seen.set(c.file, c);
    }
    await sleep(800);
  }
  const list = [...seen.values()].slice(0, MAX_COMMONS);
  // « openverse: true » (anciennes recettes déjà cherchées sur Commons) : on interroge aussi Flickr systématiquement.
  if (list.length < 2 || r.openverse) {
    for (const c of await openverse(`${name} ${r.country === "US" ? "" : en}`.trim())) {
      if (list.filter((x) => x.source !== "Wikimedia Commons").length >= MAX_OPENVERSE) break;
      const hay = normalize(c.description);
      if ([...wanted].some((t) => hay.includes(t))) list.push(c);
    }
  }
  for (const [i, c] of list.entries()) {
    c.thumb = `thumbs/${r.slug}--${i}.jpg`;
    if (!(await download(c.preview, join(OUT, c.thumb)))) c.thumb = null;
  }
  out[r.slug] = { title: r.title, original: r.original, en: r.en, country: r.country, candidates: list.filter((c) => c.thumb) };
  if (out[r.slug].candidates.length) withCandidates += 1;
  writeFileSync(join(OUT, "candidates.json"), JSON.stringify(out, null, 1));
  console.log(`[${index + 1}/${recipes.length}] ${r.slug} : ${out[r.slug].candidates.length} candidate(s)`);
}
console.log(`${withCandidates}/${recipes.length} recettes avec au moins une candidate · ${openverseCalls} requêtes Openverse`);
