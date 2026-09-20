import { NextResponse } from "next/server";
import { resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

function validCountryCode(value: string) {
  return /^[A-Z]{2}$/.test(value);
}

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ code: string }> },
) {
  const { code: rawCode } = await params;
  const code = rawCode.toUpperCase();

  if (!validCountryCode(code)) {
    return NextResponse.json({ error: "Pays inconnu." }, { status: 404 });
  }

  const supabase = await createClient();

  const [{ data: country }, { data: places }, { data: recipes, error: recipesError }] =
    await Promise.all([
      supabase
        .from("culinary_places")
        .select("id,name,country_code,place_type,parent_id")
        .eq("country_code", code)
        .eq("place_type", "country")
        .eq("is_active", true)
        .maybeSingle(),
      supabase
        .from("culinary_places")
        .select("id,name,country_code,place_type,parent_id")
        .eq("country_code", code)
        .eq("is_active", true)
        .neq("place_type", "country")
        .order("place_type")
        .order("name"),
      supabase
        .from("recipes")
        .select(
          "id,title,original_title,country_code,region,category,difficulty,prep_minutes,cook_minutes,published_at,recipe_title_translations(language_code,title),recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status)",
        )
        .eq("status", "published")
        .eq("is_editorial", true)
        .eq("country_code", code)
        .order("published_at", { ascending: false }),
    ]);

  if (!country) {
    return NextResponse.json({ error: "Pays inconnu." }, { status: 404 });
  }
  if (recipesError) {
    return NextResponse.json({ error: recipesError.message }, { status: 500 });
  }

  const recipeRows = recipes ?? [];
  const recipeIds = recipeRows.map((recipe) => recipe.id);
  const placeRows = places ?? [];
  const placeIds = placeRows.map((place) => place.id);

  const [likesResult, ratingsResult, locationsResult] = recipeIds.length
    ? await Promise.all([
        supabase.from("recipe_likes").select("recipe_id").in("recipe_id", recipeIds),
        supabase.from("recipe_ratings").select("recipe_id,rating").in("recipe_id", recipeIds),
        placeIds.length
          ? supabase
              .from("recipe_locations")
              .select("recipe_id,place_id,is_primary")
              .in("recipe_id", recipeIds)
              .in("place_id", placeIds)
          : Promise.resolve({ data: [] }),
      ])
    : [{ data: [] }, { data: [] }, { data: [] }];

  const childrenByParent = new Map<string, string[]>();
  for (const place of placeRows) {
    if (!place.parent_id) continue;
    const children = childrenByParent.get(place.parent_id) ?? [];
    children.push(place.id);
    childrenByParent.set(place.parent_id, children);
  }

  function descendants(placeId: string) {
    const collected = new Set<string>([placeId]);
    const queue = [placeId];
    while (queue.length) {
      const current = queue.shift()!;
      for (const child of childrenByParent.get(current) ?? []) {
        if (!collected.has(child)) {
          collected.add(child);
          queue.push(child);
        }
      }
    }
    return collected;
  }

  const directRecipeIdsByPlace = new Map<string, Set<string>>();
  for (const location of locationsResult.data ?? []) {
    const current = directRecipeIdsByPlace.get(location.place_id) ?? new Set<string>();
    current.add(location.recipe_id);
    directRecipeIdsByPlace.set(location.place_id, current);
  }

  const placeSummaries = placeRows.map((place) => {
    const relatedPlaces = descendants(place.id);
    const relatedRecipeIds = new Set<string>();

    for (const relatedPlaceId of relatedPlaces) {
      for (const recipeId of directRecipeIdsByPlace.get(relatedPlaceId) ?? []) {
        relatedRecipeIds.add(recipeId);
      }
    }

    return {
      id: place.id,
      name: place.name,
      placeType: place.place_type,
      parentId: place.parent_id,
      recipeIds: [...relatedRecipeIds],
      recipeCount: relatedRecipeIds.size,
    };
  });

  const items = recipeRows
    .map((recipe) => {
      const readyImages = [...(recipe.recipe_images ?? [])]
        .filter((image) => image.status === "ready")
        .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
      const image = readyImages[0] ? resolveMediaUrl(readyImages[0], "recipe-images") : null;
      const likes = (likesResult.data ?? []).filter((row) => row.recipe_id === recipe.id).length;
      const ratings = (ratingsResult.data ?? []).filter((row) => row.recipe_id === recipe.id);
      const rating = ratings.length
        ? ratings.reduce((sum, row) => sum + row.rating, 0) / ratings.length
        : null;
      const minutes = (recipe.prep_minutes ?? 0) + (recipe.cook_minutes ?? 0);
      const score = likes * 3 + ratings.length * 2 + (rating ?? 0);

      return {
        id: recipe.id,
        title: recipe.title,
        originalTitle: recipe.original_title || recipe.title,
        titleTranslations: recipe.recipe_title_translations ?? [],
        region: recipe.region,
        category: recipe.category || "Recette",
        difficulty: recipe.difficulty,
        minutes: minutes || null,
        image,
        likes,
        rating,
        ratingCount: ratings.length,
        score,
        publishedAt: recipe.published_at,
      };
    })
    .sort(
      (a, b) =>
        b.score - a.score ||
        String(b.publishedAt ?? "").localeCompare(String(a.publishedAt ?? "")),
    );

  return NextResponse.json(
    {
      country: {
        code,
        name: country.name,
      },
      total: items.length,
      places: placeSummaries,
      recipes: items,
    },
    {
      headers: {
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      },
    },
  );
}
