import type { Metadata } from "next";
import { CulinaryGlobe } from "@/components/culinary-globe";
import type { AtlasRecipe, CulinaryPlace, CulinaryPlaceType } from "@/lib/culinary-places";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = {
  title: "Atlas culinaire | Cuisine du monde",
  description: "Explorez les cuisines du monde par pays, région, île et ville sur un globe interactif.",
};

export default async function ExplorePage() {
  const supabase = await createClient();

  const [placesResult, linksResult] = await Promise.all([
    supabase
      .from("culinary_places")
      .select("id, slug, name, country_code, place_type, parent_id, latitude, longitude, default_zoom, summary")
      .eq("is_active", true)
      .order("country_code")
      .order("name"),
    supabase
      .from("recipe_locations")
      .select("recipe_id, place_id"),
  ]);

  const recipeIds = Array.from(new Set((linksResult.data ?? []).map((link) => link.recipe_id)));
  const recipesResult = recipeIds.length
    ? await supabase
        .from("recipes")
        .select("id, title, description, category, cover_image_path")
        .in("id", recipeIds)
    : { data: [], error: null };

  const places: CulinaryPlace[] = (placesResult.data ?? []).map((place) => ({
    id: place.id,
    slug: place.slug,
    name: place.name,
    countryCode: place.country_code,
    placeType: place.place_type as CulinaryPlaceType,
    parentId: place.parent_id,
    latitude: place.latitude,
    longitude: place.longitude,
    zoom: place.default_zoom,
    summary: place.summary,
  }));

  const recipeById = new Map((recipesResult.data ?? []).map((recipe) => [recipe.id, recipe]));
  const recipes: AtlasRecipe[] = (linksResult.data ?? []).flatMap((link) => {
    const recipe = recipeById.get(link.recipe_id);
    return recipe
      ? [{
          id: recipe.id,
          title: recipe.title,
          description: recipe.description,
          category: recipe.category,
          coverImagePath: recipe.cover_image_path,
          placeId: link.place_id,
        }]
      : [];
  });

  const dataError =
    placesResult.error?.message ||
    linksResult.error?.message ||
    recipesResult.error?.message ||
    null;

  return (
    <main className="atlas-page">
      <CulinaryGlobe places={places} recipes={recipes} dataError={dataError} />
    </main>
  );
}
