import type { Metadata } from "next";
import { CulinaryGlobe } from "@/components/culinary-globe";
import type {
  AtlasPlaceImage,
  AtlasRecipe,
  AtlasSpecialty,
  CulinaryPlace,
  CulinaryPlaceType,
} from "@/lib/culinary-places";
import { resolveMediaUrl } from "@/lib/media";
import { fetchAllRows } from "@/lib/supabase/fetch-all";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = {
  title: "Atlas culinaire | Cuisine du monde",
  description: "Explorez les cuisines du monde par pays, région, île et ville sur un globe interactif.",
};

type Props = { searchParams: Promise<{ lieu?: string }> };

export default async function ExplorePage({ searchParams }: Props) {
  const { lieu } = await searchParams;
  const supabase = await createClient();

  const [placesResult, linksResult, specialtiesResult, placeImagesResult] = await Promise.all([
    fetchAllRows((from, to) =>
      supabase
        .from("culinary_places")
        .select("id, slug, name, country_code, place_type, parent_id, latitude, longitude, default_zoom, summary")
        .eq("is_active", true)
        .order("country_code")
        .order("name")
        .range(from, to),
    ),
    // Jointure directe lieu → recette : évite d'envoyer des centaines d'identifiants
    // dans l'URL (.in) et reste complète au-delà de 1000 recettes.
    fetchAllRows((from, to) =>
      supabase
        .from("recipe_locations")
        .select(
          "place_id, recipes!inner(id, title, original_title, description, category, country_code, status, recipe_title_translations(language_code,title), recipe_images!recipe_images_recipe_id_fkey(id, storage_path, external_url, is_primary, status))",
        )
        .eq("recipes.status", "published")
        .order("recipe_id")
        .order("place_id")
        .range(from, to),
    ),
    fetchAllRows((from, to) =>
      supabase
        .from("place_specialties")
        .select("id, place_id, recipe_id, name, description, origin_note, is_signature, sort_order")
        .order("is_signature", { ascending: false })
        .order("sort_order")
        .order("name")
        .order("id")
        .range(from, to),
    ),
    supabase
      .from("place_images")
      .select("id, place_id, storage_path, external_url, alt_text, caption, source_type, attribution_text, source_page_url, is_primary")
      .eq("status", "ready")
      .order("is_primary", { ascending: false }),
  ]);

  const places: CulinaryPlace[] = placesResult.data.map((place) => ({
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

  const recipes: AtlasRecipe[] = linksResult.data.flatMap((link) => {
    const recipe = link.recipes;
    if (!recipe) return [];
    const readyImages = [...(recipe.recipe_images ?? [])]
      .filter((image) => image.status === "ready")
      .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
    const cover = readyImages[0];
    return [{
      id: recipe.id,
      title: recipe.title,
      originalTitle: recipe.original_title || recipe.title,
      titleTranslations: recipe.recipe_title_translations ?? [],
      countryCode: recipe.country_code,
      description: recipe.description,
      category: recipe.category,
      coverImageUrl: cover ? resolveMediaUrl(cover, "recipe-images") : null,
      placeId: link.place_id,
    }];
  });

  const specialties: AtlasSpecialty[] = specialtiesResult.data.map((specialty) => ({
    id: specialty.id,
    placeId: specialty.place_id,
    recipeId: specialty.recipe_id,
    name: specialty.name,
    description: specialty.description,
    originNote: specialty.origin_note,
    isSignature: specialty.is_signature,
    sortOrder: specialty.sort_order,
  }));

  const placeImages: AtlasPlaceImage[] = (placeImagesResult.data ?? []).flatMap((image) => {
    const url = resolveMediaUrl(image, "place-images");
    return url
      ? [{
          id: image.id,
          placeId: image.place_id,
          url,
          altText: image.alt_text,
          caption: image.caption,
          sourceType: image.source_type,
          attributionText: image.attribution_text,
          sourcePageUrl: image.source_page_url,
          isPrimary: image.is_primary,
        }]
      : [];
  });

  const dataError =
    placesResult.error ||
    linksResult.error ||
    specialtiesResult.error ||
    placeImagesResult.error?.message ||
    null;

  return (
    <main className="atlas-page">
      <CulinaryGlobe
        places={places}
        recipes={recipes}
        specialties={specialties}
        placeImages={placeImages}
        dataError={dataError}
        initialPlaceId={places.find((place) => place.slug === lieu)?.id ?? null}
      />
    </main>
  );
}
