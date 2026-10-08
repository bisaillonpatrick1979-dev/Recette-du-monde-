// Robot d'audit photo — télécharge une miniature de la photo principale de chaque recette publiée,
// pour un contrôle visuel complet (« la photo montre-t-elle bien ce plat ? »).
//
//   node scripts/recipe-batches/audit-photos.mjs <dossier-sortie>
//
// Variables : SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY (clé publique, lecture des recettes publiées seulement).
// Résultat : index.json (recette, pays, titre, URL de la photo) + thumbs/<n>.jpg.
// Rien n'est modifié dans l'application : les corrections se font après revue visuelle.
// Conçu pour tourner dans GitHub Actions (.github/workflows/photo-audit.yml).
import { writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const [OUT] = process.argv.slice(2);
const { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } = process.env;
if (!OUT || !SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY) {
  console.error("Usage : SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… node scripts/recipe-batches/audit-photos.mjs <dossier-sortie>");
  process.exit(1);
}
const THUMBS = join(OUT, "thumbs");
mkdirSync(THUMBS, { recursive: true });

const USER_AGENT = "Spoontrotter/1.0 (https://github.com/bisaillonpatrick1979-dev/Recette-du-monde-)";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function loadRecipes() {
  const select =
    "id,slug,title,original_title,country_code,region,created_at," +
    "recipe_images!recipe_images_recipe_id_fkey(id,external_url,storage_path,status,is_primary,source_page_url,photographer_name)";
  const all = [];
  for (let from = 0; ; from += 1000) {
    const since = process.env.AUDIT_SINCE ? `&created_at=gte.${encodeURIComponent(process.env.AUDIT_SINCE)}` : "";
    const url = `${SUPABASE_URL}/rest/v1/recipes?select=${encodeURIComponent(select)}&status=eq.published${since}&order=created_at.asc,id.asc`;
    const res = await fetch(url, {
      headers: { apikey: SUPABASE_PUBLISHABLE_KEY, Authorization: `Bearer ${SUPABASE_PUBLISHABLE_KEY}`, Range: `${from}-${from + 999}` },
    });
    if (!res.ok) throw new Error(`Supabase ${res.status} : ${await res.text()}`);
    const page = await res.json();
    all.push(...page);
    if (page.length < 1000) return all;
  }
}

// Miniature de 330 px (taille standard servie par Wikimedia) à partir de l'URL enregistrée.
function thumbUrl(url) {
  if (!url) return null;
  if (url.includes("upload.wikimedia.org") && url.includes("/thumb/")) return url.replace(/\/\d+px-([^/]+)$/, "/330px-$1");
  const m = url.match(/^(https:\/\/upload\.wikimedia\.org\/wikipedia\/[^/]+)\/([0-9a-f])\/([0-9a-f]{2})\/([^/?]+)$/);
  if (m) return `${m[1]}/thumb/${m[2]}/${m[3]}/${m[4]}/330px-${m[4]}${/\.(tiff?|svg)$/i.test(m[4]) ? ".jpg" : ""}`;
  return url;
}

async function download(url, target) {
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      const res = await fetch(url, { headers: { "User-Agent": USER_AGENT }, signal: AbortSignal.timeout(20000) });
      if (res.ok) {
        writeFileSync(target, Buffer.from(await res.arrayBuffer()));
        return res.status;
      }
      if (res.status === 404 || res.status === 400) return res.status;
      await sleep(3000 * (attempt + 1));
    } catch {
      await sleep(3000 * (attempt + 1));
    }
  }
  return "erreur";
}

const recipes = await loadRecipes();
console.log(`${recipes.length} recettes publiées`);
// Budget de temps : on s'arrête proprement avant la limite du job et on publie ce qui est prêt.
const deadline = Date.now() + Number(process.env.AUDIT_BUDGET_MINUTES || 95) * 60_000;
const index = recipes.map((r, k) => {
  const images = (r.recipe_images ?? []).filter((i) => i.status === "ready");
  const image = images.find((i) => i.is_primary) ?? images[0];
  return {
    n: k + 1,
    id: r.id,
    slug: r.slug,
    title: r.original_title || r.title,
    fr: r.title,
    country: r.country_code,
    region: r.region,
    imageId: image?.id ?? null,
    url: image?.external_url ?? null,
    page: image?.source_page_url ?? null,
    thumb: null,
  };
});
const save = () => writeFileSync(join(OUT, "index.json"), JSON.stringify(index, null, 1));
let next = 0;
let done = 0;
let failures = 0;
async function worker() {
  while (next < index.length && Date.now() < deadline) {
    const entry = index[next++];
    const src = thumbUrl(entry.url);
    if (src) {
      const target = join(THUMBS, `${entry.n}.jpg`);
      let status = await download(src, target);
      if (status !== 200 && src !== entry.url) status = await download(entry.url, target);
      if (status === 200) entry.thumb = `thumbs/${entry.n}.jpg`;
      else {
        entry.error = String(status);
        failures += 1;
      }
    }
    done += 1;
    if (done % 100 === 0) {
      save();
      console.log(`${done} / ${index.length} (${failures} échecs)`);
    }
  }
}
await Promise.all(Array.from({ length: 4 }, worker));
save();
console.log(`Terminé : ${done} recettes traitées sur ${index.length}, ${index.filter((e) => e.thumb).length} miniatures, ${failures} échecs.`);
