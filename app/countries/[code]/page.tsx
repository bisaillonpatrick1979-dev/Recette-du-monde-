import Image from "next/image";
import Link from "next/link";
import { LocalizedRecipeTitle } from "@/components/localized-recipe-title";
import { OpenRecipeImage } from "@/components/open-recipe-image";
import { notFound } from "next/navigation";
import { resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

type Props = {
  params: Promise<{ code: string }>;
};

function validCountryCode(value: string) {
  return /^[A-Z]{2}$/.test(value);
}

function difficultyLabel(value: "easy" | "medium" | "hard" | null) {
  if (value === "hard") return "Difficile";
  if (value === "medium") return "Moyen";
  return "Facile";
}

export default async function CountryPage({ params }: Props) {
  const { code: rawCode } = await params;
  const code = rawCode.toUpperCase();
  if (!validCountryCode(code)) notFound();

  const supabase = await createClient();

  const [{ data: country }, { data: places }, { data: recipes, error }] =
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
        .select("id,name,place_type,parent_id")
        .eq("country_code", code)
        .eq("is_active", true)
        .neq("place_type", "country")
        .order("place_type")
        .order("name"),
      supabase
        .from("recipes")
        .select(
          "id,title,original_title,description,country_code,region,category,difficulty,prep_minutes,cook_minutes,published_at,recipe_title_translations(language_code,title),recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status)",
        )
        .eq("status", "published")
        .eq("is_editorial", true)
        .eq("country_code", code)
        .order("published_at", { ascending: false }),
    ]);

  if (!country) notFound();
  if (error) throw new Error(error.message);

  const recipeRows = recipes ?? [];
  const ids = recipeRows.map((recipe) => recipe.id);
  const placeRows = places ?? [];
  const placeIds = placeRows.map((place) => place.id);

  const [likesResult, ratingsResult, locationsResult] = ids.length
    ? await Promise.all([
        supabase.from("recipe_likes").select("recipe_id").in("recipe_id", ids),
        supabase.from("recipe_ratings").select("recipe_id,rating").in("recipe_id", ids),
        placeIds.length
          ? supabase
              .from("recipe_locations")
              .select("recipe_id,place_id")
              .in("recipe_id", ids)
              .in("place_id", placeIds)
          : Promise.resolve({ data: [] }),
      ])
    : [{ data: [] }, { data: [] }, { data: [] }];

  const recipeIdsByPlace = new Map<string, Set<string>>();
  for (const row of locationsResult.data ?? []) {
    const current = recipeIdsByPlace.get(row.place_id) ?? new Set<string>();
    current.add(row.recipe_id);
    recipeIdsByPlace.set(row.place_id, current);
  }

  const childrenByParent = new Map<string, string[]>();
  for (const place of placeRows) {
    if (!place.parent_id) continue;
    const children = childrenByParent.get(place.parent_id) ?? [];
    children.push(place.id);
    childrenByParent.set(place.parent_id, children);
  }

  function countForPlace(placeId: string) {
    const allPlaces = new Set<string>([placeId]);
    const queue = [placeId];

    while (queue.length) {
      const current = queue.shift()!;
      for (const child of childrenByParent.get(current) ?? []) {
        if (!allPlaces.has(child)) {
          allPlaces.add(child);
          queue.push(child);
        }
      }
    }

    const recipeIds = new Set<string>();
    for (const relatedPlaceId of allPlaces) {
      for (const recipeId of recipeIdsByPlace.get(relatedPlaceId) ?? []) {
        recipeIds.add(recipeId);
      }
    }
    return recipeIds.size;
  }

  const placeCards = placeRows.map((place) => ({
    ...place,
    recipeCount: countForPlace(place.id),
  }));

  const items = recipeRows
    .map((recipe) => {
      const images = [...(recipe.recipe_images ?? [])]
        .filter((image) => image.status === "ready")
        .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
      const image = images[0] ? resolveMediaUrl(images[0], "recipe-images") : null;
      const likes = (likesResult.data ?? []).filter((row) => row.recipe_id === recipe.id).length;
      const ratings = (ratingsResult.data ?? []).filter((row) => row.recipe_id === recipe.id);
      const rating = ratings.length
        ? ratings.reduce((sum, row) => sum + row.rating, 0) / ratings.length
        : null;
      const minutes = (recipe.prep_minutes ?? 0) + (recipe.cook_minutes ?? 0);
      const score = likes * 3 + ratings.length * 2 + (rating ?? 0);

      return {
        ...recipe,
        image,
        likes,
        rating,
        ratingCount: ratings.length,
        minutes: minutes || null,
        score,
      };
    })
    .sort(
      (a, b) =>
        b.score - a.score ||
        String(b.published_at ?? "").localeCompare(String(a.published_at ?? "")),
    );

  const regions = placeCards.filter((place) => place.place_type === "region");
  const cities = placeCards.filter((place) => place.place_type === "city");
  const islands = placeCards.filter((place) => place.place_type === "island");

  return (
    <main className="continent-page country-page">
      <div className="continent-page-shell">
        <header className="continent-page-header">
          <Link href="/" className="continent-page-back">← Accueil</Link>
          <div>
            <span className="planet-eyebrow">Pays à découvrir</span>
            <h1>{country.name}</h1>
            <p>{items.length.toLocaleString("fr-CA")} recettes officielles</p>
          </div>
        </header>

        {placeCards.length ? (
          <section className="country-page-places">
            <div className="country-page-places-heading">
              <strong>Régions et villes culinaires</strong>
              <span>Ces lieux servent à organiser les recettes plus précisément à l’intérieur du pays.</span>
            </div>

            <div className="country-page-place-columns">
              {regions.length ? (
                <div>
                  <small>Régions</small>
                  <div className="country-page-place-list">
                    {regions.map((place) => (
                      <div key={place.id}>
                        <strong>{place.name}</strong>
                        <span>{place.recipeCount} recette{place.recipeCount > 1 ? "s" : ""}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ) : null}

              {cities.length ? (
                <div>
                  <small>Villes</small>
                  <div className="country-page-place-list">
                    {cities.map((place) => (
                      <div key={place.id}>
                        <strong>{place.name}</strong>
                        <span>{place.recipeCount} recette{place.recipeCount > 1 ? "s" : ""}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ) : null}

              {islands.length ? (
                <div>
                  <small>Îles</small>
                  <div className="country-page-place-list">
                    {islands.map((place) => (
                      <div key={place.id}>
                        <strong>{place.name}</strong>
                        <span>{place.recipeCount} recette{place.recipeCount > 1 ? "s" : ""}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ) : null}
            </div>
          </section>
        ) : null}

        <section className="continent-page-intro">
          <div>
            <strong>Toutes les recettes de {country.name}</strong>
            <span>Les recettes les mieux notées et les plus appréciées apparaissent en premier.</span>
          </div>
        </section>

        {items.length ? (
          <section className="continent-page-grid" aria-label={"Recettes de " + country.name}>
            {items.map((recipe) => (
              <Link href={"/recipes/" + recipe.id} className="continent-page-card" key={recipe.id}>
                <div className="continent-page-card-image">
                  {recipe.image ? (
                    <Image
                      src={recipe.image}
                      alt={recipe.title}
                      fill
                      sizes="(max-width: 680px) 100vw, (max-width: 1050px) 50vw, 25vw"
                    />
                  ) : (
                    <OpenRecipeImage
                      title={recipe.original_title || recipe.title}
                      countryCode={recipe.country_code}
                      className="continent-card-reference-image"
                      showCredit={false}
                    />
                  )}
                </div>
                <div className="continent-page-card-body">
                  <small>{recipe.region || country.name}</small>
                  <h2>
                    <LocalizedRecipeTitle
                      originalTitle={recipe.original_title || recipe.title}
                      translations={recipe.recipe_title_translations ?? []}
                    />
                  </h2>
                  {recipe.description ? <p>{recipe.description}</p> : null}
                  <div className="continent-page-card-meta">
                    <span>{recipe.category || "Recette"}</span>
                    {recipe.minutes ? <span>{recipe.minutes} min</span> : null}
                    <span>{difficultyLabel(recipe.difficulty)}</span>
                  </div>
                  <div className="continent-page-card-rating">
                    <span>♥ {recipe.likes}</span>
                    <span>★ {recipe.rating ? recipe.rating.toFixed(1) : "—"} ({recipe.ratingCount})</span>
                  </div>
                </div>
              </Link>
            ))}
          </section>
        ) : (
          <section className="continent-modal-empty">
            <span>🍽️</span>
            <h2>Aucune recette publiée pour ce pays pour le moment.</h2>
          </section>
        )}
      </div>
    </main>
  );
}
