import { HomeExperience } from "@/components/home-experience";
import type {
  HomeAtlasStats,
  HomeCommunityRecipe,
  HomeContinentStat,
  HomeCountryCard,
  HomeRecipe,
} from "@/lib/home-data";
import { resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

function flagFor(code: string) {
  return code
    .toUpperCase()
    .replace(/[A-Z]/g, (letter) =>
      String.fromCodePoint(127397 + letter.charCodeAt(0)),
    );
}

function difficultyLabel(value: "easy" | "medium" | "hard" | null) {
  if (value === "hard") return "Difficile" as const;
  if (value === "medium") return "Moyen" as const;
  return "Facile" as const;
}

function timeLabel(prep: number | null, cook: number | null) {
  const total = (prep ?? 0) + (cook ?? 0);
  if (!total) return "—";
  if (total < 60) return `${total} min`;
  const hours = Math.floor(total / 60);
  const minutes = total % 60;
  return minutes ? `${hours} h ${minutes}` : `${hours} h`;
}

const CONTINENT_CODES = {
  "north-america": ["CA", "US", "GL", "BM"],
  "latin-america": [
    "MX", "GT", "BZ", "HN", "SV", "NI", "CR", "PA", "CU", "DO", "HT", "JM",
    "BS", "BB", "TT", "GD", "LC", "VC", "AG", "DM", "KN", "CO", "VE", "GY",
    "SR", "EC", "PE", "BO", "BR", "PY", "UY", "AR", "CL",
  ],
  europe: [
    "AL", "AD", "AT", "BY", "BE", "BA", "BG", "HR", "CY", "CZ", "DK", "EE",
    "FI", "FR", "DE", "GR", "HU", "IS", "IE", "IT", "LV", "LI", "LT", "LU",
    "MT", "MD", "MC", "ME", "NL", "MK", "NO", "PL", "PT", "RO", "RU", "SM",
    "RS", "SK", "SI", "ES", "SE", "CH", "UA", "GB", "VA",
  ],
  asia: [
    "AF", "BD", "BT", "BN", "KH", "CN", "IN", "ID", "JP", "KZ", "KG", "LA",
    "MY", "MV", "MN", "MM", "NP", "KP", "KR", "PK", "PH", "SG", "LK", "TW",
    "TJ", "TH", "TL", "TM", "UZ", "VN",
  ],
  africa: [
    "DZ", "AO", "BJ", "BW", "BF", "BI", "CV", "CM", "CF", "TD", "KM", "CG",
    "CD", "CI", "DJ", "EG", "GQ", "ER", "SZ", "ET", "GA", "GM", "GH", "GN",
    "GW", "KE", "LS", "LR", "LY", "MG", "MW", "ML", "MR", "MU", "MA", "MZ",
    "NA", "NE", "NG", "RW", "ST", "SN", "SC", "SL", "SO", "ZA", "SS", "SD",
    "TZ", "TG", "TN", "UG", "ZM", "ZW",
  ],
  "middle-east": [
    "AM", "AZ", "BH", "GE", "IR", "IQ", "IL", "JO", "KW", "LB", "OM", "PS",
    "QA", "SA", "SY", "TR", "AE", "YE",
  ],
  oceania: ["AU", "FJ", "KI", "MH", "FM", "NR", "NZ", "PW", "PG", "WS", "SB", "TO", "TV", "VU"],
} as const;

const CONTINENT_META: Array<Omit<HomeContinentStat, "recipes">> = [
  { key: "north-america", label: "Amérique du Nord", icon: "🏔️" },
  { key: "latin-america", label: "Amérique latine", icon: "🌺" },
  { key: "europe", label: "Europe", icon: "🏛️" },
  { key: "asia", label: "Asie", icon: "🏯" },
  { key: "africa", label: "Afrique", icon: "🌅" },
  { key: "middle-east", label: "Moyen-Orient", icon: "🕌" },
  { key: "oceania", label: "Océanie", icon: "🏝️" },
];

export default async function HomePage() {
  const supabase = await createClient();

  const [
    editorialResult,
    communityResult,
    totalCountResult,
    editorialCountResult,
    communityCountResult,
    countryCodesResult,
    subplaceCountResult,
  ] = await Promise.all([
    supabase
      .from("recipes")
      .select(
        "id,title,country_code,region,category,difficulty,prep_minutes,cook_minutes,published_at,recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status)",
      )
      .eq("status", "published")
      .eq("is_editorial", true)
      .order("published_at", { ascending: false })
      .limit(20),
    supabase
      .from("recipes")
      .select(
        "id,title,author_id,country_code,published_at,recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status)",
      )
      .eq("status", "published")
      .eq("is_editorial", false)
      .order("published_at", { ascending: false })
      .limit(8),
    supabase
      .from("recipes")
      .select("id", { count: "exact", head: true })
      .eq("status", "published"),
    supabase
      .from("recipes")
      .select("id", { count: "exact", head: true })
      .eq("status", "published")
      .eq("is_editorial", true),
    supabase
      .from("recipes")
      .select("id", { count: "exact", head: true })
      .eq("status", "published")
      .eq("is_editorial", false),
    supabase
      .from("recipes")
      .select("country_code")
      .eq("status", "published"),
    supabase
      .from("culinary_places")
      .select("id", { count: "exact", head: true })
      .eq("is_active", true)
      .in("place_type", ["region", "island", "city", "locality"]),
  ]);

  const displayNames = new Intl.DisplayNames(["fr"], { type: "region" });

  const recipes: HomeRecipe[] = (editorialResult.data ?? []).flatMap((recipe) => {
    const images = [...(recipe.recipe_images ?? [])]
      .filter((image) => image.status === "ready")
      .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
    const image = images[0] ? resolveMediaUrl(images[0], "recipe-images") : null;
    if (!image) return [];

    const code = recipe.country_code || "";
    return [{
      id: recipe.id,
      title: recipe.title,
      country: (code && displayNames.of(code)) || code || "Cuisine du monde",
      region: recipe.region,
      flag: code.length === 2 ? flagFor(code) : "🌍",
      image,
      time: timeLabel(recipe.prep_minutes, recipe.cook_minutes),
      difficulty: difficultyLabel(recipe.difficulty),
      category: recipe.category || "Recette",
    }];
  });

  const countryMap = new Map<string, { flag: string; titles: string[] }>();
  for (const recipe of recipes) {
    const current = countryMap.get(recipe.country) ?? { flag: recipe.flag, titles: [] };
    if (!current.titles.includes(recipe.title)) current.titles.push(recipe.title);
    countryMap.set(recipe.country, current);
  }

  const countries: HomeCountryCard[] = [...countryMap.entries()]
    .slice(0, 10)
    .map(([name, value]) => ({
      flag: value.flag,
      name,
      dishes: value.titles.slice(0, 3).join(", "),
    }));

  const publishedCodes = (countryCodesResult.data ?? [])
    .map((row) => row.country_code?.toUpperCase())
    .filter((code): code is string => Boolean(code));

  const continents: HomeContinentStat[] = CONTINENT_META.map((continent) => {
    const allowed = new Set<string>(CONTINENT_CODES[continent.key]);
    return {
      ...continent,
      recipes: publishedCodes.reduce((count, code) => count + (allowed.has(code) ? 1 : 0), 0),
    };
  });

  const communityRows = communityResult.data ?? [];
  const communityIds = communityRows.map((recipe) => recipe.id);
  const authorIds = [...new Set(communityRows.map((recipe) => recipe.author_id))];

  const [profilesResult, likesResult, commentsResult, ratingsResult] =
    communityIds.length > 0
      ? await Promise.all([
          authorIds.length
            ? supabase.from("profiles").select("id,display_name,username,country_code").in("id", authorIds)
            : Promise.resolve({ data: [] }),
          supabase.from("recipe_likes").select("recipe_id").in("recipe_id", communityIds),
          supabase
            .from("recipe_comments")
            .select("recipe_id")
            .in("recipe_id", communityIds)
            .is("deleted_at", null),
          supabase.from("recipe_ratings").select("recipe_id,rating").in("recipe_id", communityIds),
        ])
      : [{ data: [] }, { data: [] }, { data: [] }, { data: [] }];

  const profileById = new Map(
    (profilesResult.data ?? []).map((profile) => [profile.id, profile]),
  );

  const communityRecipes: HomeCommunityRecipe[] = communityRows.map((recipe) => {
    const profile = profileById.get(recipe.author_id);
    const images = [...(recipe.recipe_images ?? [])]
      .filter((image) => image.status === "ready")
      .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
    const image = images[0] ? resolveMediaUrl(images[0], "recipe-images") : null;
    const ratings = (ratingsResult.data ?? []).filter((row) => row.recipe_id === recipe.id);
    const rating = ratings.length
      ? ratings.reduce((sum, row) => sum + row.rating, 0) / ratings.length
      : null;

    return {
      id: recipe.id,
      title: recipe.title,
      author: profile?.display_name || profile?.username || "Membre de la communauté",
      authorCountry: profile?.country_code || recipe.country_code || null,
      image,
      likes: (likesResult.data ?? []).filter((row) => row.recipe_id === recipe.id).length,
      comments: (commentsResult.data ?? []).filter((row) => row.recipe_id === recipe.id).length,
      rating,
      ratingCount: ratings.length,
    };
  });

  const stats: HomeAtlasStats = {
    recipes: totalCountResult.count ?? recipes.length,
    editorialRecipes: editorialCountResult.count ?? recipes.length,
    communityRecipes: communityCountResult.count ?? communityRecipes.length,
    countries: new Set(publishedCodes).size,
    subplaces: subplaceCountResult.count ?? 0,
    continents,
  };

  return (
    <HomeExperience
      recipes={recipes}
      countries={countries}
      communityRecipes={communityRecipes}
      stats={stats}
    />
  );
}
