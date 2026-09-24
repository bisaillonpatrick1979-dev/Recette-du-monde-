import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { FollowButton } from "@/components/follow-button";
import { resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

type Props = { params: Promise<{ id: string }> };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function flagFor(code: string | null) {
  if (!code || code.length !== 2) return "🌍";
  return code
    .toUpperCase()
    .replace(/[A-Z]/g, (letter) => String.fromCodePoint(127397 + letter.charCodeAt(0)));
}

export default async function CookProfilePage({ params }: Props) {
  const { id } = await params;
  if (!UUID.test(id)) notFound();

  const supabase = await createClient();
  const [{ data: profile }, { data: claimsData }] = await Promise.all([
    supabase.from("profiles").select("id,display_name,username,bio,country_code,created_at").eq("id", id).maybeSingle(),
    supabase.auth.getClaims(),
  ]);

  if (!profile) notFound();

  const viewerId = typeof claimsData?.claims?.sub === "string" ? claimsData.claims.sub : null;

  const [recipesResult, followersResult, followingResult, viewerFollowResult] = await Promise.all([
    supabase
      .from("recipes")
      .select("id,title,country_code,region,published_at,recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status),recipe_likes(count)")
      .eq("author_id", id)
      .eq("status", "published")
      .eq("is_editorial", false)
      .order("published_at", { ascending: false })
      .limit(60),
    supabase.from("follows").select("follower_id", { count: "exact", head: true }).eq("following_id", id),
    supabase.from("follows").select("following_id", { count: "exact", head: true }).eq("follower_id", id),
    viewerId
      ? supabase.from("follows").select("follower_id").eq("follower_id", viewerId).eq("following_id", id).maybeSingle()
      : Promise.resolve({ data: null }),
  ]);

  const recipes = recipesResult.data ?? [];
  const name = profile.display_name || profile.username || "Cuisinier de la communauté";
  const displayNames = new Intl.DisplayNames(["fr"], { type: "region" });
  const totalLikes = recipes.reduce((sum, recipe) => sum + (recipe.recipe_likes?.[0]?.count ?? 0), 0);

  return (
    <main className="community-page">
      <div className="community-page-shell">
        <section className="profile-hero-card public-profile-card">
          <div className="profile-avatar">{name.slice(0, 1).toUpperCase()}</div>
          <div>
            <span className="eyebrow">
              {flagFor(profile.country_code)}{" "}
              {profile.country_code ? displayNames.of(profile.country_code) ?? profile.country_code : "Cuisinier du monde"}
              {profile.username ? ` · @${profile.username}` : ""}
            </span>
            <h1>{name}</h1>
            <p>{profile.bio || "Membre de la communauté Cuisine du monde."}</p>
            <div className="public-profile-stats">
              <span><strong>{recipes.length}</strong> recettes</span>
              <span><strong>{followingResult.count ?? 0}</strong> abonnements</span>
              <span><strong>{totalLikes}</strong> j’aime reçus</span>
            </div>
          </div>
          <FollowButton
            profileId={profile.id}
            viewerId={viewerId}
            initialFollowing={Boolean(viewerFollowResult.data)}
            initialFollowers={followersResult.count ?? 0}
          />
        </section>

        {recipes.length ? (
          <section className="community-feed-grid" aria-label={`Recettes de ${name}`}>
            {recipes.map((recipe) => {
              const images = [...(recipe.recipe_images ?? [])]
                .filter((image) => image.status === "ready")
                .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
              const image = images[0] ? resolveMediaUrl(images[0], "recipe-images") : null;
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
                    <small>
                      {flagFor(recipe.country_code)}{" "}
                      {[recipe.country_code && (displayNames.of(recipe.country_code) ?? recipe.country_code), recipe.region]
                        .filter(Boolean)
                        .join(" · ") || "Sans frontières"}
                    </small>
                    <h2>{recipe.title}</h2>
                    <div className="social-metrics">
                      <span>♥ {recipe.recipe_likes?.[0]?.count ?? 0}</span>
                    </div>
                  </div>
                </Link>
              );
            })}
          </section>
        ) : (
          <section className="community-empty">
            <span>🍳</span>
            <h2>Pas encore de recette publiée</h2>
            <p>{name} n’a pas encore partagé de recette avec la communauté.</p>
          </section>
        )}

        <p>
          <Link href="/community" className="secondary-button">← Retour à la communauté</Link>
        </p>
      </div>
    </main>
  );
}
