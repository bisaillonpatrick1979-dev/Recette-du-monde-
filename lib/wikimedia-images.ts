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

function englishCountryName(countryCode?: string | null) {
  if (!countryCode || countryCode.length !== 2) return null;
  try {
    return new Intl.DisplayNames(["en"], { type: "region" }).of(countryCode.toUpperCase()) ?? null;
  } catch {
    return null;
  }
}

export async function findWikimediaPlaceImage({
  name,
  countryCode,
}: {
  name: string;
  countryCode?: string | null;
}) {
  const englishCountry = englishCountryName(countryCode);
  const base = englishCountry || name;

  const searches = [
    `${base} landscape`,
    `${base} landmark`,
    `${base} national park`,
    `${base} skyline`,
    `${name} ${base}`,
    base,
  ];

  for (const search of searches) {
    const results = await searchCommons(search);
    if (results.length) return results[0];
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
    if (results.length) return results[0];
  }

  return null;
}
