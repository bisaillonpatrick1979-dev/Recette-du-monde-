import Image from "next/image";
import Link from "next/link";
import { resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

export default async function CommunityPage() {
  const supabase = await createClient();

  const { data: recipes } = await supabase
    .from("recipes")
    .select(
      "id,title,description,author_id,country_code,published_at,recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status)",
    )
    .eq("status", "published")
    .eq("is_editorial", false)
    .order("published_at", { ascending: false })
    .limit(36);

  const recipeRows = recipes ?? [];
  const recipeIds = recipeRows.map((recipe) => recipe.id);
  const authorIds = [...new Set(recipeRows.map((recipe) => recipe.author_id))];

  const [profilesResult, likesResult, commentsResult, ratingsResult] =
    recipeIds.length > 0
      ? await Promise.all([
          authorIds.length
            ? supabase.from("profiles").select("id,display_name,username,country_code").in("id", authorIds)
            : Promise.resolve({ data: [] }),
          supabase.from("recipe_likes").select("recipe_id").in("recipe_id", recipeIds),
          supabase
            .from("recipe_comments")
            .select("recipe_id")
            .in("recipe_id", recipeIds)
            .is("deleted_at", null),
          supabase.from("recipe_ratings").select("recipe_id,rating").in("recipe_id", recipeIds),
        ])
      : [{ data: [] }, { data: [] }, { data: [] }, { data: [] }];

  const profileById = new Map(
    (profilesResult.data ?? []).map((profile) => [profile.id, profile]),
  );

  return (
    <main className="community-page">
      <div className="community-page-shell">
        <section className="community-page-hero">
          <div>
            <span className="planet-eyebrow">Réseau culinaire mondial</span>
            <h1>Communauté</h1>
            <p>
              Un espace séparé des recettes officielles où les membres publient leurs recettes,
              ajoutent des photos, suivent d’autres cuisiniers, notent les plats et échangent dans les commentaires.
            </p>
          </div>
          <div className="community-page-actions">
            <Link href="/" className="secondary-button">← Accueil</Link>
            <Link href="/publish" className="primary-button">+ Publier ma recette</Link>
          </div>
        </section>

        {recipeRows.length ? (
          <section className="community-feed-grid" aria-label="Recettes de la communauté">
            {recipeRows.map((recipe) => {
              const profile = profileById.get(recipe.author_id);
              const images = [...(recipe.recipe_images ?? [])]
                .filter((image) => image.status === "ready")
                .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
              const image = images[0] ? resolveMediaUrl(images[0], "recipe-images") : null;
              const likes = (likesResult.data ?? []).filter((row) => row.recipe_id === recipe.id).length;
              const comments = (commentsResult.data ?? []).filter((row) => row.recipe_id === recipe.id).length;
              const ratings = (ratingsResult.data ?? []).filter((row) => row.recipe_id === recipe.id);
              const average = ratings.length
                ? ratings.reduce((sum, row) => sum + row.rating, 0) / ratings.length
                : null;

              return (
                <Link href={`/recipes/${recipe.id}`} className="social-recipe-card" key={recipe.id}>
                  <div className="social-recipe-media">
                    {image ? (
                      <Image src={image} alt={recipe.title} fill sizes="(max-width: 640px) 100vw, 360px" />
                    ) : (
                      <span>🍳</span>
                    )}
                  </div>
                  <div className="social-recipe-body">
                    <div className="social-author-line">
                      <span className="social-avatar">
                        {(profile?.display_name || profile?.username || "M").slice(0, 1).toUpperCase()}
                      </span>
                      <div>
                        <strong>{profile?.display_name || profile?.username || "Membre"}</strong>
                        <small>{profile?.country_code || recipe.country_code || "Cuisine sans frontières"}</small>
                      </div>
                    </div>
                    <h2>{recipe.title}</h2>
                    <div className="social-metrics">
                      <span>♥ {likes}</span>
                      <span>💬 {comments}</span>
                      <span>★ {average ? average.toFixed(1) : "—"} ({ratings.length})</span>
                    </div>
                  </div>
                </Link>
              );
            })}
          </section>
        ) : (
          <section className="community-empty">
            <span>👩‍🍳👨‍🍳</span>
            <h2>La communauté ouvre ses portes</h2>
            <p>
              Les recettes officielles sont déjà dans l’application. Les premières recettes publiées par les membres
              apparaîtront ici, avec leurs photos, notes, mentions J’aime et commentaires.
            </p>
            <Link href="/publish" className="primary-button">Publier la première recette utilisateur</Link>
          </section>
        )}
      </div>
    </main>
  );
}
