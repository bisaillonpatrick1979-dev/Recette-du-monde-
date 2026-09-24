import Image from "next/image";
import Link from "next/link";
import { resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

type Props = { searchParams: Promise<{ fil?: string }> };

export default async function CommunityPage({ searchParams }: Props) {
  const { fil } = await searchParams;
  const supabase = await createClient();
  const { data: claimsData } = await supabase.auth.getClaims();
  const viewerId = typeof claimsData?.claims?.sub === "string" ? claimsData.claims.sub : null;
  const followingFeed = fil === "abonnements" && Boolean(viewerId);

  const followedIds = followingFeed && viewerId
    ? ((await supabase.from("follows").select("following_id").eq("follower_id", viewerId).limit(500)).data ?? [])
        .map((row) => row.following_id)
    : [];

  let recipeQuery = supabase
    .from("recipes")
    .select(
      "id,title,description,author_id,country_code,region,published_at,recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status),recipe_likes(count),recipe_comments(count),recipe_ratings(rating)",
    )
    .eq("status", "published")
    .eq("is_editorial", false)
    .is("recipe_comments.deleted_at", null);

  if (followingFeed) {
    recipeQuery = recipeQuery.in("author_id", followedIds.length ? followedIds : ["00000000-0000-0000-0000-000000000000"]);
  }

  const { data: recipes } = await recipeQuery.order("published_at", { ascending: false }).limit(36);

  const recipeRows = recipes ?? [];
  const authorIds = [...new Set(recipeRows.map((recipe) => recipe.author_id))];
  const { data: profiles } = authorIds.length
    ? await supabase.from("profiles").select("id,display_name,username,country_code").in("id", authorIds)
    : { data: [] };

  const profileById = new Map((profiles ?? []).map((profile) => [profile.id, profile]));

  return (
    <main className="community-page">
      <div className="community-page-shell">
        <section className="community-page-hero">
          <div>
            <span className="planet-eyebrow">Réseau culinaire mondial</span>
            <h1>Communauté</h1>
            <p>
              Un espace séparé des recettes officielles où les membres publient leurs recettes,
              ajoutent des photos et des vidéos, suivent d’autres cuisiniers, notent les plats et échangent dans les commentaires.
            </p>
          </div>
          <div className="community-page-actions">
            <Link href="/" className="secondary-button">← Accueil</Link>
            <Link href="/publish" className="primary-button">+ Publier ma recette</Link>
          </div>
        </section>

        <nav className="community-tabs" aria-label="Fil de la communauté">
          <Link href="/community" className={followingFeed ? "" : "active"} aria-current={followingFeed ? undefined : "page"}>
            🌍 Tout le monde
          </Link>
          <Link
            href={viewerId ? "/community?fil=abonnements" : "/login"}
            className={followingFeed ? "active" : ""}
            aria-current={followingFeed ? "page" : undefined}
          >
            👥 Mes abonnements
          </Link>
        </nav>

        {recipeRows.length ? (
          <section className="community-feed-grid" aria-label="Recettes de la communauté">
            {recipeRows.map((recipe) => {
              const profile = profileById.get(recipe.author_id);
              const authorName = profile?.display_name || profile?.username || "Membre";
              const images = [...(recipe.recipe_images ?? [])]
                .filter((image) => image.status === "ready")
                .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
              const image = images[0] ? resolveMediaUrl(images[0], "recipe-images") : null;
              const likes = recipe.recipe_likes?.[0]?.count ?? 0;
              const comments = recipe.recipe_comments?.[0]?.count ?? 0;
              const ratings = recipe.recipe_ratings ?? [];
              const average = ratings.length
                ? ratings.reduce((sum, row) => sum + row.rating, 0) / ratings.length
                : null;

              return (
                <article className="social-recipe-card" key={recipe.id}>
                  <Link href={`/recipes/${recipe.id}`} className="social-recipe-media">
                    {image ? (
                      <Image src={image} alt={recipe.title} fill sizes="(max-width: 640px) 100vw, 360px" />
                    ) : (
                      <span>🍳</span>
                    )}
                  </Link>
                  <div className="social-recipe-body">
                    <Link href={`/cooks/${recipe.author_id}`} className="social-author-line">
                      <span className="social-avatar">{authorName.slice(0, 1).toUpperCase()}</span>
                      <div>
                        <strong>{authorName}</strong>
                        <small>
                          {[recipe.country_code || profile?.country_code, recipe.region].filter(Boolean).join(" · ") ||
                            "Cuisine sans frontières"}
                        </small>
                      </div>
                    </Link>
                    <h2><Link href={`/recipes/${recipe.id}`}>{recipe.title}</Link></h2>
                    <div className="social-metrics">
                      <span>♥ {likes}</span>
                      <span>💬 {comments}</span>
                      <span>★ {average ? average.toFixed(1) : "—"} ({ratings.length})</span>
                    </div>
                  </div>
                </article>
              );
            })}
          </section>
        ) : followingFeed ? (
          <section className="community-empty">
            <span>👥</span>
            <h2>Votre fil d’abonnements est vide</h2>
            <p>Suivez des cuisiniers depuis leur profil pour voir leurs nouvelles recettes ici.</p>
            <Link href="/community" className="primary-button">Découvrir des cuisiniers</Link>
          </section>
        ) : (
          <section className="community-empty">
            <span>👩‍🍳👨‍🍳</span>
            <h2>La communauté ouvre ses portes</h2>
            <p>
              Les recettes officielles sont déjà dans l’application. Les premières recettes publiées par les membres
              apparaîtront ici, avec leurs photos, vidéos, notes, mentions J’aime et commentaires.
            </p>
            <Link href="/publish" className="primary-button">Publier la première recette utilisateur</Link>
          </section>
        )}
      </div>
    </main>
  );
}
