import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { CONTINENTS, isContinentKey } from "@/lib/continents";
import { resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

type Props = {
  params: Promise<{ key: string }>;
};

function flagFor(code: string | null) {
  if (!code || code.length !== 2) return "🌍";
  return code
    .toUpperCase()
    .replace(/[A-Z]/g, (letter) =>
      String.fromCodePoint(127397 + letter.charCodeAt(0)),
    );
}

function difficultyLabel(value: "easy" | "medium" | "hard" | null) {
  if (value === "hard") return "Difficile";
  if (value === "medium") return "Moyen";
  return "Facile";
}

export default async function ContinentPage({ params }: Props) {
  const { key } = await params;
  if (!isContinentKey(key)) notFound();

  const continent = CONTINENTS[key];
  const supabase = await createClient();

  const { data: recipes, error } = await supabase
    .from("recipes")
    .select(
      "id,title,description,country_code,region,category,difficulty,prep_minutes,cook_minutes,published_at,recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status)",
    )
    .eq("status", "published")
    .eq("is_editorial", true)
    .in("country_code", [...continent.codes])
    .order("published_at", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  const rows = recipes ?? [];
  const ids = rows.map((recipe) => recipe.id);

  const [likesResult, ratingsResult] = ids.length
    ? await Promise.all([
        supabase.from("recipe_likes").select("recipe_id").in("recipe_id", ids),
        supabase.from("recipe_ratings").select("recipe_id,rating").in("recipe_id", ids),
      ])
    : [{ data: [] }, { data: [] }];

  const displayNames = new Intl.DisplayNames(["fr"], { type: "region" });

  const items = rows
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
      const totalMinutes = (recipe.prep_minutes ?? 0) + (recipe.cook_minutes ?? 0);
      const score = likes * 3 + ratings.length * 2 + (rating ?? 0);
      const country =
        (recipe.country_code && displayNames.of(recipe.country_code)) ||
        recipe.country_code ||
        "Cuisine du monde";

      return {
        ...recipe,
        image,
        likes,
        rating,
        ratingCount: ratings.length,
        totalMinutes: totalMinutes || null,
        score,
        country,
      };
    })
    .sort(
      (a, b) =>
        b.score - a.score ||
        String(b.published_at ?? "").localeCompare(String(a.published_at ?? "")),
    );

  const countryCount = new Set(
    items.map((recipe) => recipe.country_code).filter(Boolean),
  ).size;

  return (
    <main className="continent-page">
      <div className="continent-page-shell">
        <header className="continent-page-header">
          <Link href="/" className="continent-page-back">← Accueil</Link>
          <div>
            <span className="planet-eyebrow">Recette de la planète</span>
            <h1>{continent.label}</h1>
            <p>
              {items.length.toLocaleString("fr-CA")} recettes · {countryCount.toLocaleString("fr-CA")} pays représentés
            </p>
          </div>
        </header>

        <section className="continent-page-intro">
          <div>
            <strong>Les recettes les mieux placées apparaissent en premier.</strong>
            <span>Le classement utilise les J’aime, les notes et ensuite les nouveautés.</span>
          </div>
        </section>

        {items.length ? (
          <section className="continent-page-grid" aria-label={"Recettes de " + continent.label}>
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
                    <span>🍲</span>
                  )}
                </div>
                <div className="continent-page-card-body">
                  <small>{flagFor(recipe.country_code)} {recipe.country}</small>
                  <h2>{recipe.title}</h2>
                  {recipe.description ? <p>{recipe.description}</p> : null}
                  <div className="continent-page-card-meta">
                    <span>{recipe.category || "Recette"}</span>
                    {recipe.totalMinutes ? <span>{recipe.totalMinutes} min</span> : null}
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
            <h2>Aucune recette publiée pour cette région pour le moment.</h2>
          </section>
        )}
      </div>
    </main>
  );
}
