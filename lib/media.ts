export type MediaLike = {
  storage_path: string | null;
  external_url: string | null;
};

export type RecipeImageLike = MediaLike & {
  source_type?: "external_licensed" | "generated" | "user_uploaded" | null;
  source_page_url?: string | null;
  moderation_notes?: string | null;
};

function encodeStoragePath(path: string) {
  return path
    .split("/")
    .map((segment) => encodeURIComponent(segment))
    .join("/");
}

export function publicStorageUrl(bucket: string, path: string) {
  const base = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!base) return null;
  return `${base}/storage/v1/object/public/${encodeURIComponent(bucket)}/${encodeStoragePath(path)}`;
}

export function resolveMediaUrl(media: MediaLike, bucket: string) {
  if (media.external_url) return media.external_url;
  if (media.storage_path) return publicStorageUrl(bucket, media.storage_path);
  return null;
}

function normalizeMediaText(value: string) {
  let decoded = value;
  try {
    decoded = decodeURIComponent(value);
  } catch {
    // Keep the original value when a legacy URL contains invalid escaping.
  }

  return decoded
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

const DISH_TYPE_TERMS = new Set([
  "pizza", "burger", "sandwich", "milkshake", "candy", "smoothie",
  "muffin", "muffins", "cupcake", "cupcakes", "cookie", "cookies",
  "brownie", "brownies", "bundt", "pie", "tart", "popsicle", "sundae",
  "schnitzel", "wrap", "wraps",
]);

const GENERIC_RECIPE_WORDS = new Set([
  "classic", "traditional", "style", "recipe", "food", "dish",
  "with", "and", "the", "from", "pour", "avec", "aux", "des", "les",
  "une", "un", "dans", "aux", "de", "du", "la", "le", "en",
]);

function compactRecipeName(value: string) {
  return normalizeMediaText(value.replace(/\([^)]*\)/g, " "));
}

function recipeTokens(value: string) {
  return compactRecipeName(value)
    .split(" ")
    .filter((token) => token.length >= 3 && !GENERIC_RECIPE_WORDS.has(token));
}

function hasConflictingDishType(source: string, recipeName: string) {
  const sourceWords = new Set(source.split(" "));
  const recipeWords = new Set(recipeName.split(" "));
  return [...DISH_TYPE_TERMS].some((term) => sourceWords.has(term) && !recipeWords.has(term));
}

/**
 * Quality gate for persisted recipe photos.
 *
 * Recent editorial batches are explicitly marked as manually verified. Older
 * Wikimedia imports are accepted only when the source filename/page still
 * contains the dish name strongly enough to identify the recipe. This prevents
 * PDFs, SVG icons, books, unrelated dishes and overly-generic search results
 * from bypassing the stricter runtime Wikimedia fallback.
 */
export function isTrustedRecipeImage(
  image: RecipeImageLike,
  recipe: { title: string; originalTitle?: string | null },
) {
  if (image.source_type && image.source_type !== "external_licensed") {
    return true;
  }

  const notes = normalizeMediaText(image.moderation_notes ?? "");
  if (notes.includes("verifie") && notes.includes("represente ce plat")) {
    return true;
  }

  const rawSource = [image.external_url, image.source_page_url].filter(Boolean).join(" ");
  if (!rawSource) return Boolean(image.storage_path);

  if (/\.(?:pdf|svg|tif|tiff|djvu)(?:[?#]|$)/i.test(rawSource)) return false;

  const source = normalizeMediaText(rawSource);
  if (
    /\b(?:ambox|camera photo|coat of arms|locator map|flag icon|placeholder)\b/.test(source)
  ) {
    return false;
  }

  const candidates = [recipe.originalTitle, recipe.title]
    .filter((value): value is string => Boolean(value?.trim()))
    .map(compactRecipeName)
    .filter(Boolean);

  for (const name of candidates) {
    if (hasConflictingDishType(source, name)) continue;
    if (name.length >= 4 && source.includes(name)) return true;

    const tokens = recipeTokens(name);
    if (!tokens.length) continue;

    const matched = tokens.filter((token) => source.includes(token)).length;
    const required = tokens.length <= 3 ? tokens.length : Math.ceil(tokens.length * 0.75);
    if (matched >= required) return true;
  }

  return false;
}

export function mediaSourceLabel(sourceType: "external_licensed" | "generated" | "user_uploaded") {
  if (sourceType === "generated") return "Image illustrative générée";
  if (sourceType === "external_licensed") return "Photo licenciée";
  return "Photo de l’auteur";
}
