export type WikimediaPlaceImage = {
  url: string;
  thumbnailUrl: string;
  sourcePageUrl: string;
  title: string;
  photographer: string | null;
  licenseName: string;
  licenseUrl: string | null;
  attribution: string;
  width: number;
  height: number;
};

type CommonsMetadata = Record<string, { value?: string } | undefined>;

type CommonsImageInfo = {
  url?: string;
  thumburl?: string;
  width?: number;
  height?: number;
  mime?: string;
  extmetadata?: CommonsMetadata;
};

type CommonsPage = {
  pageid?: number;
  title?: string;
  imageinfo?: CommonsImageInfo[];
};

const COMMONS_API = "https://commons.wikimedia.org/w/api.php";
const USER_AGENT =
  "Recette-de-la-planete/1.0 (https://github.com/bisaillonpatrick1979-dev/Recette-du-monde-)";

const REJECT_TITLE =
  /\b(flag|map|locator|coat[ _-]?of[ _-]?arms|emblem|seal|logo|passport|currency|banknote|stamp|diagram|icon|blank|outline)\b/i;

const RECIPE_MATCH_STOPWORDS = new Set([
  "classic","traditional","style","with","and","the","from","food","dish","recipe",
  "chicken","beef","pork","fish","soup","rice","salad","bread","stew","meat",
  "poulet","boeuf","porc","poisson","soupe","riz","salade","pain","ragout",
  "de","du","des","la","le","les","au","aux","avec","et","en",
  "con","y","del","los","las","una","uno",
]);

function normalizedRecipeText(value: string) {
  return value
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function recipeMatchTokens(value: string) {
  return normalizedRecipeText(value)
    .split(" ")
    .filter((token) => token.length >= 4 && !RECIPE_MATCH_STOPWORDS.has(token));
}

function recipeImageMatchesTitle(image: WikimediaPlaceImage, recipeTitle: string) {
  const imageText = normalizedRecipeText(image.title);
  const titleText = normalizedRecipeText(recipeTitle);

  if (titleText && imageText.includes(titleText)) return true;

  const tokens = recipeMatchTokens(recipeTitle);
  if (!tokens.length) return false;

  const matches = tokens.filter((token) => imageText.includes(token));
  const minimumMatches = Math.max(1, Math.ceil(tokens.length * 0.5));

  return matches.length >= minimumMatches;
}

function decodeEntities(value: string) {
  return value
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">");
}

function cleanText(value?: string | null) {
  if (!value) return "";
  return decodeEntities(
    value
      .replace(/<br\s*\/?\s*>/gi, " ")
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim(),
  );
}

function sourcePageUrl(title: string) {
  return `https://commons.wikimedia.org/wiki/${encodeURIComponent(title.replaceAll(" ", "_"))}`;
}

function metadataValue(metadata: CommonsMetadata | undefined, key: string) {
  return cleanText(metadata?.[key]?.value);
}

function licenseIsReusable(name: string) {
  const value = name.toLowerCase();
  if (!value) return false;
  if (
    value.includes("noncommercial") ||
    value.includes("no derivatives") ||
    /(?:^|[-\s])nc(?:[-\s]|$)/.test(value) ||
    /(?:^|[-\s])nd(?:[-\s]|$)/.test(value)
  ) {
    return false;
  }

  return (
    value.includes("public domain") ||
    value.includes("cc0") ||
    value.includes("creative commons attribution") ||
    value.includes("cc by") ||
    value.includes("cc-by") ||
    value.includes("attribution-share alike") ||
    value.includes("attribution sharealike")
  );
}

function scoreCandidate(page: CommonsPage, info: CommonsImageInfo) {
  const width = info.width ?? 0;
  const height = info.height ?? 0;
  const ratio = height > 0 ? width / height : 0;
  let score = 0;

  if (ratio >= 1.35) score += 8;
  else if (ratio >= 1.15) score += 5;
  else if (ratio >= 1) score += 2;
  else score -= 3;

  if (width >= 2400) score += 5;
  else if (width >= 1400) score += 4;
  else if (width >= 900) score += 2;

  const title = page.title ?? "";
  if (/panorama|landscape|skyline|view|national park|old town|historic|mountain|coast|harbour|harbor/i.test(title)) {
    score += 3;
  }

  return score;
}

async function searchCommons(term: string): Promise<WikimediaPlaceImage[]> {
  const params = new URLSearchParams({
    action: "query",
    format: "json",
    formatversion: "2",
    generator: "search",
    gsrsearch: term,
    gsrnamespace: "6",
    gsrlimit: "12",
    prop: "imageinfo",
    iiprop: "url|size|mime|extmetadata",
    iiurlwidth: "1200",
    iiextmetadatalanguage: "en",
    iiextmetadatafilter:
      "LicenseShortName|LicenseUrl|Artist|Credit|ImageDescription|UsageTerms",
  });

  const response = await fetch(`${COMMONS_API}?${params.toString()}`, {
    headers: {
      "Api-User-Agent": USER_AGENT,
      "User-Agent": USER_AGENT,
    },
    next: { revalidate: 60 * 60 * 24 * 30 },
  });

  if (!response.ok) return [];

  const body = (await response.json()) as {
    query?: { pages?: CommonsPage[] };
  };

  const candidates = (body.query?.pages ?? []).flatMap((page) => {
    const info = page.imageinfo?.[0];
    const title = page.title ?? "";

    if (
      !info?.url ||
      !info.thumburl ||
      !title ||
      REJECT_TITLE.test(title) ||
      !["image/jpeg", "image/png", "image/webp"].includes(info.mime ?? "")
    ) {
      return [];
    }

    const width = info.width ?? 0;
    const height = info.height ?? 0;
    if (width < 700 || height < 450) return [];

    const metadata = info.extmetadata;
    const licenseName =
      metadataValue(metadata, "LicenseShortName") ||
      metadataValue(metadata, "UsageTerms");

    if (!licenseIsReusable(licenseName)) return [];

    const photographer =
      metadataValue(metadata, "Artist") ||
      metadataValue(metadata, "Credit") ||
      null;
    const licenseUrl = metadataValue(metadata, "LicenseUrl") || null;
    const shortTitle = title.replace(/^File:/i, "");

    return [{
      image: {
        url: info.url,
        thumbnailUrl: info.thumburl,
        sourcePageUrl: sourcePageUrl(title),
        title: shortTitle,
        photographer,
        licenseName,
        licenseUrl,
        attribution: [photographer, licenseName, "Wikimedia Commons"]
          .filter(Boolean)
          .join(" · "),
        width,
        height,
      } satisfies WikimediaPlaceImage,
      score: scoreCandidate(page, info),
    }];
  });

  return candidates
    .sort((a, b) => b.score - a.score)
    .map((candidate) => candidate.image);
}

function frenchCountryName(countryCode?: string | null) {
  if (!countryCode || countryCode.length !== 2) return null;
  try {
    return new Intl.DisplayNames(["fr"], { type: "region" }).of(countryCode.toUpperCase()) ?? null;
  } catch {
    return null;
  }
}

function englishCountryName(countryCode?: string | null) {
  if (!countryCode || countryCode.length !== 2) return null;
  try {
    return new Intl.DisplayNames(["en"], { type: "region" }).of(countryCode.toUpperCase()) ?? null;
  } catch {
    return null;
  }
}

function placeMatchTokens(value: string) {
  return normalizedRecipeText(value)
    .split(" ")
    .filter((token) => token.length >= 3 && !RECIPE_MATCH_STOPWORDS.has(token));
}

function imageMatchesPlace(image: WikimediaPlaceImage, placeName: string) {
  const imageText = normalizedRecipeText(image.title);
  const tokens = placeMatchTokens(placeName);
  return tokens.length > 0 && tokens.some((token) => imageText.includes(token));
}

async function firstMatchingPlaceImage(searches: string[], placeName: string) {
  for (const search of searches) {
    const results = await searchCommons(search);
    const matching = results.find((image) => imageMatchesPlace(image, placeName));
    if (matching) return matching;
  }
  return null;
}

export async function findWikimediaPlaceImage({
  name,
  countryCode,
}: {
  name: string;
  countryCode?: string | null;
}) {
  const englishCountry = englishCountryName(countryCode);
  const frenchCountry = frenchCountryName(countryCode);
  const isCountry =
    !englishCountry ||
    normalizedRecipeText(name) === normalizedRecipeText(englishCountry) ||
    (frenchCountry !== null && normalizedRecipeText(name) === normalizedRecipeText(frenchCountry));

  // Régions et villes : chercher d'abord le lieu lui-même, et n'accepter
  // qu'une photo dont le titre nomme ce lieu. Avant, la recherche utilisait
  // le pays et renvoyait n'importe quel paysage (ex. l'Islande pour Marseille).
  if (!isCountry) {
    const local = await firstMatchingPlaceImage(
      [
        `${name} ${englishCountry}`,
        `${name} city`,
        `${name} landscape`,
        name,
      ],
      name,
    );
    if (local) return local;
  }

  const countryName = englishCountry || name;
  const national = await firstMatchingPlaceImage(
    [
      `${countryName} landscape`,
      `${countryName} landmark`,
      `${countryName} national park`,
      `${countryName} skyline`,
      countryName,
    ],
    countryName,
  );
  if (national) return national;

  // Dernier recours culinaire : photo de cuisine du pays, jamais générée par IA,
  // toujours sous licence libre Commons.
  if (englishCountry) {
    return firstMatchingPlaceImage(
      [
        `${englishCountry} traditional food`,
        `${englishCountry} cuisine dish`,
        `${englishCountry} traditional cuisine`,
      ],
      englishCountry,
    );
  }

  return null;
}


function compactRecipeSearchTitle(title: string) {
  return title
    .replace(/\([^)]*\)/g, " ")
    .replace(/\b(classique|traditionnel(?:le)?|style)\b/gi, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export async function findWikimediaRecipeImage({
  title,
  countryCode,
}: {
  title: string;
  countryCode?: string | null;
}) {
  const cleanTitle = compactRecipeSearchTitle(title);
  const englishCountry = englishCountryName(countryCode);

  const searches = [
    `${cleanTitle} food`,
    `${cleanTitle} dish`,
    englishCountry ? `${cleanTitle} ${englishCountry} cuisine` : cleanTitle,
    title,
  ];

  for (const search of searches) {
    const results = await searchCommons(search);
    const matching = results.find((image) => recipeImageMatchesTitle(image, cleanTitle));
    if (matching) return matching;
  }

  return null;
}
