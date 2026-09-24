import { HomeExperience } from "@/components/home-experience";
import type {
  HomeAtlasStats,
  HomeCommunityRecipe,
  HomeContinentStat,
  HomeCountryCard,
  HomeRecipe,
} from "@/lib/home-data";
import { CONTINENTS } from "@/lib/continents";
import { resolveMediaUrl } from "@/lib/media";
import { fetchAllRows } from "@/lib/supabase/fetch-all";
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

const CONTINENT_META: Array<Omit<HomeContinentStat, "recipes">> = [
  { key: "africa", label: CONTINENTS.africa.label, icon: "🌅" },
  { key: "north-america", label: CONTINENTS["north-america"].label, icon: "🏔️" },
  { key: "south-america", label: CONTINENTS["south-america"].label, icon: "🌺" },
  { key: "antarctica", label: CONTINENTS.antarctica.label, icon: "🧊" },
  { key: "asia", label: CONTINENTS.asia.label, icon: "🏯" },
  { key: "europe", label: CONTINENTS.europe.label, icon: "🏛️" },
  { key: "oceania", label: CONTINENTS.oceania.label, icon: "🏝️" },
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
    borderlessCountResult,
  ] = await Promise.all([
    supabase
      .from("recipes")
      .select(
        "id,title,original_title,country_code,region,category,difficulty,prep_minutes,cook_minutes,published_at,recipe_title_translations(language_code,title),recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status)",
      )
      .eq("status", "published")
      .eq("is_editorial", true)
      .order("published_at", { ascending: false })
      .limit(500),
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
    fetchAllRows((from, to) =>
      supabase
        .from("recipes")
        .select("country_code")
        .eq("status", "published")
        .not("country_code", "is", null)
        .order("id")
        .range(from, to),
    ),
    supabase
      .from("culinary_places")
      .select("id", { count: "exact", head: true })
      .eq("is_active", true)
      .in("place_type", ["region", "island", "city", "locality"]),
    supabase
      .from("recipes")
      .select("id", { count: "exact", head: true })
      .eq("status", "published")
      .eq("is_borderless", true),
  ]);

  const displayNames = new Intl.DisplayNames(["fr"], { type: "region" });

  const editorialRows = editorialResult.data ?? [];

  const recipes: HomeRecipe[] = editorialRows
    .map((recipe) => {
      const images = [...(recipe.recipe_images ?? [])]
        .filter((image) => image.status === "ready")
        .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
      const image = images[0] ? resolveMediaUrl(images[0], "recipe-images") : null;

      const code = recipe.country_code?.toUpperCase() || "";
      return {
        id: recipe.id,
        title: recipe.title,
        originalTitle: recipe.original_title || recipe.title,
        titleTranslations: recipe.recipe_title_translations ?? [],
        country: (code && displayNames.of(code)) || code || "Cuisine du monde",
        countryCode: code,
        region: recipe.region,
        flag: code.length === 2 ? flagFor(code) : "🌍",
        image,
        time: timeLabel(recipe.prep_minutes, recipe.cook_minutes),
        difficulty: difficultyLabel(recipe.difficulty),
        category: recipe.category || "Recette",
      };
    })
    .slice(0, 20);

  // Country discovery must not depend on whether a recipe already has a photo.
  // Build it from every published editorial recipe so the section never vanishes
  // when a newly-added batch is still waiting for imagery.
  const countryMap = new Map<string, { flag: string; countryCode: string; titles: string[] }>();
  for (const recipe of editorialRows) {
    const code = recipe.country_code?.toUpperCase() || "";
    if (code.length !== 2) continue;

    const name = displayNames.of(code) || code;
    const current = countryMap.get(name) ?? {
      flag: flagFor(code),
      countryCode: code,
      titles: [],
    };
    if (!current.titles.includes(recipe.title)) current.titles.push(recipe.title);
    countryMap.set(name, current);
  }

  const countries: HomeCountryCard[] = [...countryMap.entries()]
    .slice(0, 10)
    .map(([name, value]) => ({
      flag: value.flag,
      name,
      countryCode: value.countryCode,
      dishes: value.titles.slice(0, 3).join(", "),
    }));

  const publishedCodes = countryCodesResult.data
    .map((row) => row.country_code?.toUpperCase())
    .filter((code): code is string => Boolean(code));

  const continents: HomeContinentStat[] = CONTINENT_META.map((continent) => {
    const allowed = new Set<string>(CONTINENTS[continent.key].codes);
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
    borderlessRecipes: borderlessCountResult.count ?? 0,
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
