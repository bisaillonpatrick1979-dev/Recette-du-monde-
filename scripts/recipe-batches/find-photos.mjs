// Cherche des photos candidates sur Wikimedia Commons pour les recettes des lots.
//
//   node scripts/recipe-batches/find-photos.mjs [dossier-vignettes]
//
// Pour chaque recette sans photo validée, interroge Commons avec le nom du plat et garde
// jusqu'à 3 fichiers sous licence libre dont le nom contient un mot du nom du plat.
// Résultat : data/recipe-batches/photo-candidates.json (+ vignettes à contrôler à l'œil).
// Une photo n'est publiée qu'après validation manuelle dans photos.json : elle doit montrer
// ce plat précis (règle stricte de data/editorial-batches/PIPELINE.md).
import { readFileSync, writeFileSync, existsSync, readdirSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const ROOT = new URL("../../", import.meta.url).pathname;
const DATA_DIR = join(ROOT, "data/recipe-batches");
const THUMBS = process.argv[2] ?? null;
const API = "https://commons.wikimedia.org/w/api.php";
const USER_AGENT = "Spoontrotter/1.0 (https://github.com/bisaillonpatrick1979-dev/Recette-du-monde-)";
const FREE_LICENSE = /^(cc0|public domain|pd|cc by(-sa)? [0-9.]+|cc by(-sa)?)/i;
const STOPWORDS = new Set(["with", "and", "the", "avec", "aux", "des", "del", "con", "sauce", "style", "recipe", "food", "dish"]);

const photos = existsSync(join(DATA_DIR, "photos.json")) ? JSON.parse(readFileSync(join(DATA_DIR, "photos.json"), "utf8")) : {};
const candidatesPath = join(DATA_DIR, "photo-candidates.json");
const candidates = existsSync(candidatesPath) ? JSON.parse(readFileSync(candidatesPath, "utf8")) : {};

const normalize = (s) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
const tokens = (s) =>
  normalize(s)
    .replace(/\(.*?\)/g, " ")
    .split(/[^a-z0-9]+/)
    .filter((t) => t.length >= 4 && !STOPWORDS.has(t));
const stripTags = (s) => (s ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();

async function api(params) {
  const url = `${API}?${new URLSearchParams({ format: "json", origin: "*", ...params })}`;
  // Commons limite le débit (429) : on respecte Retry-After, sinon on attend de plus en plus longtemps.
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const res = await fetch(url, { headers: { "User-Agent": USER_AGENT } });
    if (res.ok) return res.json();
    const retryAfter = Number(res.headers.get("retry-after"));
    await new Promise((r) => setTimeout(r, retryAfter > 0 ? retryAfter * 1000 : 5000 * 2 ** Math.min(attempt, 4)));
  }
  throw new Error(`Commons a refusé la requête : ${url}`);
}

async function search(query) {
  const data = await api({
    action: "query",
    generator: "search",
    gsrsearch: `${query} filetype:bitmap`,
    gsrnamespace: "6",
    gsrlimit: "12",
    prop: "imageinfo",
    iiprop: "url|extmetadata|size",
    iiurlwidth: "1280",
  });
  return Object.values(data.query?.pages ?? {});
}

const recipes = readdirSync(DATA_DIR)
  .filter((f) => /^batch-.*\.json$/.test(f))
  .sort()
  .flatMap((f) => JSON.parse(readFileSync(join(DATA_DIR, f), "utf8")));

if (THUMBS) mkdirSync(THUMBS, { recursive: true });
let found = 0;
for (const r of recipes) {
  if (photos[r.slug] || candidates[r.slug]) continue;
  const name = r.original.replace(/\(.*?\)/g, "").trim();
  const wanted = new Set([...tokens(name), ...tokens(r.en).filter((t) => tokens(name).length === 0)]);
  const seen = new Map();
  for (const query of [...new Set([name, r.en.replace(/\(.*?\)/g, "").trim()])]) {
    for (const page of await search(query)) {
      const info = page.imageinfo?.[0];
      const meta = info?.extmetadata ?? {};
      const license = stripTags(meta.LicenseShortName?.value);
      const fileWords = new Set(tokens(page.title));
      const matches = [...wanted].some((t) => fileWords.has(t) || normalize(page.title).includes(t));
      if (!info || !matches || !FREE_LICENSE.test(license) || info.width < 500) continue;
      seen.set(page.title, {
        file: page.title,
        url: info.thumburl ?? info.url,
        page: info.descriptionurl,
        author: stripTags(meta.Artist?.value).slice(0, 200),
        license,
        licenseUrl: stripTags(meta.LicenseUrl?.value) || null,
        description: stripTags(meta.ImageDescription?.value).slice(0, 300),
      });
    }
  }
  const list = [...seen.values()].slice(0, 3);
  candidates[r.slug] = list;
  if (list.length) found += 1;
  if (THUMBS) {
    for (const [i, c] of list.entries()) {
      const res = await fetch(c.url.replace(/\/1280px-/, "/480px-"), { headers: { "User-Agent": USER_AGENT } });
      if (res.ok) writeFileSync(join(THUMBS, `${r.slug}--${i}.jpg`), Buffer.from(await res.arrayBuffer()));
    }
  }
  writeFileSync(candidatesPath, JSON.stringify(candidates, null, 1));
  await new Promise((res) => setTimeout(res, 1500));
}
console.log(`${found} recettes avec au moins une photo candidate → ${candidatesPath.replace(ROOT, "")}`);
