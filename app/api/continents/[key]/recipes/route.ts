import { NextRequest, NextResponse } from "next/server";
import { CONTINENTS, isContinentKey } from "@/lib/continents";
import { resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ key: string }> },
) {
  const { key } = await params;
  if (!isContinentKey(key)) {
    return NextResponse.json({ error: "Continent inconnu." }, { status: 404 });
  }

  const supabase = await createClient();
  const continent = CONTINENTS[key];

  const { data: recipes, error } = await supabase
    .from("recipes")
    .select(
      "id,title,original_title,country_code,region,category,difficulty,prep_minutes,cook_minutes,published_at,recipe_title_translations(language_code,title),recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status),recipe_likes(count),recipe_ratings(rating)",
    )
    .eq("status", "published")
    .eq("is_editorial", true)
    .in("country_code", [...continent.codes])
    .order("published_at", { ascending: false })
    .limit(1000);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const rows = recipes ?? [];
  const displayNames = new Intl.DisplayNames(["fr"], { type: "region" });

  const items = rows
    .map((recipe) => {
      const readyImages = [...(recipe.recipe_images ?? [])]
        .filter((image) => image.status === "ready")
        .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
      const image = readyImages[0] ? resolveMediaUrl(readyImages[0], "recipe-images") : null;

      const likes = recipe.recipe_likes?.[0]?.count ?? 0;
      const ratings = recipe.recipe_ratings ?? [];
      const rating = ratings.length
        ? ratings.reduce((sum, row) => sum + row.rating, 0) / ratings.length
        : null;
      const totalMinutes = (recipe.prep_minutes ?? 0) + (recipe.cook_minutes ?? 0);
      const score = likes * 3 + ratings.length * 2 + (rating ?? 0);

      return {
        id: recipe.id,
        title: recipe.title,
        originalTitle: recipe.original_title || recipe.title,
        titleTranslations: recipe.recipe_title_translations ?? [],
        country:
          (recipe.country_code && displayNames.of(recipe.country_code)) ||
          recipe.country_code ||
          "Cuisine du monde",
        countryCode: recipe.country_code,
        region: recipe.region,
        category: recipe.category || "Recette",
        difficulty: recipe.difficulty,
        minutes: totalMinutes || null,
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
      key,
      label: continent.label,
      total: items.length,
      recipes: items.slice(0, 8),
    },
    {
      headers: {
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      },
    },
  );
}
