import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { RecipePhotoUploader } from "@/components/recipe-photo-uploader";
import { RecipeSocialPanel } from "@/components/recipe-social-panel";
import { RecipeVideos } from "@/components/recipe-videos";
import { LocalizedRecipeContent } from "@/components/localized-recipe-content";
import { LocalizedRecipeTitle } from "@/components/localized-recipe-title";
import { OpenRecipeImage } from "@/components/open-recipe-image";
import { BORDERLESS_KEY, BORDERLESS_LABEL } from "@/lib/continents";
import { mediaSourceLabel, publicStorageUrl, resolveMediaUrl } from "@/lib/media";
import type { RecipeVideo } from "@/lib/video";
import { createClient } from "@/lib/supabase/server";

type Props = { params: Promise<{ id: string }> };

export default async function RecipePage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const [{ data: recipe }, { data: claimsData }] = await Promise.all([
    supabase
      .from("recipes")
      .select("*, recipe_ingredients(*), recipe_steps(*), recipe_title_translations(language_code,title), recipe_translations(language_code,title,description,ingredients,steps), recipe_images!recipe_images_recipe_id_fkey(*)")
      .eq("id", id)
      .maybeSingle(),
    supabase.auth.getClaims(),
  ]);

  if (!recipe) notFound();

  const userId = typeof claimsData?.claims?.sub === "string" ? claimsData.claims.sub : null;

  const [
    { data: author },
    { data: likes },
    { data: ratings },
    { data: comments },
    videosResult,
  ] = await Promise.all([
    supabase
      .from("profiles")
      .select("display_name,username")
      .eq("id", recipe.author_id)
      .maybeSingle(),
    supabase
      .from("recipe_likes")
      .select("user_id")
      .eq("recipe_id", id),
    supabase
      .from("recipe_ratings")
      .select("user_id,rating")
      .eq("recipe_id", id),
    supabase
      .from("recipe_comments")
      .select("id,user_id,body,created_at")
      .eq("recipe_id", id)
      .is("deleted_at", null)
      .order("created_at", { ascending: false })
      .limit(20),
    supabase
      .from("recipe_videos")
      .select("id,user_id,provider,external_id,storage_path,caption,created_at")
      .eq("recipe_id", id)
      .order("created_at", { ascending: false })
      .limit(12),
  ]);

  // Tant que la migration recipe_videos n'est pas appliquée, la section reste en lecture seule.
  const videosAvailable = !videosResult.error;
  const videoRows = videosResult.data ?? [];

  // Fil d'Ariane du lieu d'origine : pays › région › ville
  const placePath: Array<{ id: string; slug: string; name: string; place_type: string }> = [];
  let placeId: string | null = recipe.primary_place_id;
  while (placeId && placePath.length < 5) {
    const { data: place } = await supabase
      .from("culinary_places")
      .select("id, slug, name, place_type, parent_id")
      .eq("id", placeId)
      .maybeSingle();
    if (!place) break;
    placePath.unshift(place);
    placeId = place.parent_id;
  }
  const originPlace = placePath.at(-1) ?? null;
  const countryName = recipe.country_code
    ? new Intl.DisplayNames(["fr"], { type: "region" }).of(recipe.country_code) ?? recipe.country_code
    : null;
  const originLabel = placePath.length
    ? placePath.map((place) => place.name).join(" › ")
    : countryName ?? (recipe.is_borderless ? BORDERLESS_LABEL : "Cuisine du monde");

  const commentUserIds = [
    ...new Set([
      ...(comments ?? []).map((comment) => comment.user_id),
      ...videoRows.map((video) => video.user_id),
    ]),
  ];
  const { data: commentProfiles } = commentUserIds.length
    ? await supabase
        .from("profiles")
        .select("id,display_name,username")
        .in("id", commentUserIds)
    : { data: [] };

  const profileById = new Map(
    (commentProfiles ?? []).map((profile) => [profile.id, profile]),
  );

  const socialComments = (comments ?? []).map((comment) => {
    const profile = profileById.get(comment.user_id);
    return {
      id: comment.id,
      authorId: comment.user_id,
      author: profile?.display_name || profile?.username || "Membre",
      body: comment.body,
      createdAt: comment.created_at,
    };
  });

  const videos: RecipeVideo[] = videoRows.map((video) => {
    const profile = profileById.get(video.user_id);
    return {
      id: video.id,
      provider: video.provider as RecipeVideo["provider"],
      externalId: video.external_id,
      url: video.storage_path ? publicStorageUrl("recipe-videos", video.storage_path) : null,
      storagePath: video.storage_path,
      caption: video.caption,
      author: profile?.display_name || profile?.username || "Membre",
      authorId: video.user_id,
      createdAt: video.created_at,
    };
  });

  const averageRating = ratings?.length
    ? ratings.reduce((sum, item) => sum + item.rating, 0) / ratings.length
    : null;
  const initialLiked = Boolean(userId && likes?.some((like) => like.user_id === userId));
  const initialUserRating =
    userId ? ratings?.find((rating) => rating.user_id === userId)?.rating ?? null : null;

  const ingredients = [...(recipe.recipe_ingredients ?? [])].sort((a, b) => a.position - b.position);
  const steps = [...(recipe.recipe_steps ?? [])].sort((a, b) => a.position - b.position);
  const images = [...(recipe.recipe_images ?? [])]
    .filter((image) => image.status === "ready")
    .sort((a, b) => Number(b.is_primary) - Number(a.is_primary) || a.created_at.localeCompare(b.created_at))
    .map((image) => ({
      ...image,
      url: resolveMediaUrl(image, "recipe-images"),
    }))
    .filter((image): image is typeof image & { url: string } => Boolean(image.url));

  const isOwner = userId === recipe.author_id;
  const primaryImage = images.find((image) => image.is_primary) ?? images[0] ?? null;

  return (
    <main className="recipe-page">
      <div className="recipe-detail-shell">
        <div className="account-topbar">
          <Link href="/" className="logo-lockup">
            <span className="logo-globe">🌍</span>
            <span><strong>Recette de la planète</strong><small>Recette</small></span>
          </Link>
          <div className="recipe-top-actions">
            <Link href="/explore" className="ghost-button">🌍 Globe</Link>
            <Link href="/community" className="ghost-button">Communauté</Link>
            <Link href="/profile" className="ghost-button">Mon profil</Link>
          </div>
        </div>

        <article className="recipe-detail-card">
          {primaryImage ? (
            <figure className="recipe-hero-media">
              <Image
                src={primaryImage.url}
                alt={primaryImage.alt_text || recipe.title}
                fill
                priority
                sizes="(max-width: 760px) 100vw, 1100px"
              />
              <figcaption>
                <span>{mediaSourceLabel(primaryImage.source_type)}</span>
                {primaryImage.attribution_text ? <small>{primaryImage.attribution_text}</small> : null}
                {primaryImage.source_page_url ? (
                  <a href={primaryImage.source_page_url} target="_blank" rel="noreferrer">Source ↗</a>
                ) : null}
              </figcaption>
            </figure>
          ) : (
            <OpenRecipeImage
              title={recipe.original_title || recipe.title}
              countryCode={recipe.country_code}
              className="recipe-hero-media recipe-reference-media"
              alt={`Photo de référence pour ${recipe.title}`}
              showCredit
            />
          )}

          <div className="recipe-origin">
            <span className="eyebrow">{originLabel} · {recipe.category || "Recette"}</span>
            {originPlace ? (
              <Link href={`/explore?lieu=${encodeURIComponent(originPlace.slug)}`} className="recipe-origin-link">
                🌍 Voir {originPlace.name} sur le globe
              </Link>
            ) : recipe.is_borderless ? (
              <Link href={`/continents/${BORDERLESS_KEY}`} className="recipe-origin-link">
                🌐 Autres classiques sans frontières
              </Link>
            ) : null}
          </div>
          <h1>
            <LocalizedRecipeTitle
              originalTitle={recipe.original_title || recipe.title}
              translations={recipe.recipe_title_translations ?? []}
            />
          </h1>
          {recipe.is_editorial ? (
            <div className="editorial-provenance">
              <span>Recette officielle · Recette de la planète</span>
              <p>
                Version adaptée rédigée pour l’application à partir de caractéristiques culinaires documentées.
              </p>
              {recipe.source_url ? (
                <a href={recipe.source_url} target="_blank" rel="noreferrer">
                  Source de référence : {recipe.source_name || "voir la source"} ↗
                </a>
              ) : null}
            </div>
          ) : (
            <p className="recipe-author">
              Recette utilisateur · Par{" "}
              <Link href={`/cooks/${recipe.author_id}`}>{author?.display_name || author?.username || "un membre"}</Link>
            </p>
          )}
          <div className="recipe-detail-meta">
            <span>Préparation : {recipe.prep_minutes ?? "—"} min</span>
            <span>Cuisson : {recipe.cook_minutes ?? "—"} min</span>
            <span>Portions : {recipe.servings ?? "—"}</span>
            <span>{recipe.authenticity}</span>
          </div>

          {images.length > 1 ? (
            <section className="recipe-gallery" aria-label="Galerie de la recette">
              {images.slice(1, 7).map((image) => (
                <figure key={image.id}>
                  <div className="recipe-gallery-image">
                    <Image
                      src={image.url}
                      alt={image.alt_text || recipe.title}
                      fill
                      sizes="(max-width: 760px) 42vw, 220px"
                    />
                  </div>
                  <figcaption>
                    <span>{mediaSourceLabel(image.source_type)}</span>
                    {image.source_page_url ? (
                      <a href={image.source_page_url} target="_blank" rel="noreferrer">Source ↗</a>
                    ) : null}
                  </figcaption>
                </figure>
              ))}
            </section>
          ) : null}

          {isOwner && userId && !recipe.is_editorial ? (
            <RecipePhotoUploader
              recipeId={recipe.id}
              userId={userId}
              recipeTitle={recipe.title}
              hasPrimaryImage={images.some((image) => image.is_primary)}
            />
          ) : null}

          <LocalizedRecipeContent
            baseDescription={recipe.description}
            baseServings={recipe.servings}
            baseIngredients={ingredients.map((item) => ({
              id: item.id,
              position: item.position,
              name: item.name,
              quantity: item.quantity,
              unit: item.unit,
              note: item.note,
            }))}
            baseSteps={steps.map((step) => ({
              id: step.id,
              position: step.position,
              instruction: step.instruction,
            }))}
            translations={recipe.recipe_translations ?? []}
          />

          <RecipeSocialPanel
            recipeId={recipe.id}
            initialLikes={likes?.length ?? 0}
            initialLiked={initialLiked}
            initialRating={averageRating}
            initialRatingCount={ratings?.length ?? 0}
            initialUserRating={initialUserRating}
            initialComments={socialComments}
            currentUserId={userId}
          />

          <RecipeVideos
            recipeId={recipe.id}
            userId={userId}
            videos={videos}
            available={videosAvailable}
          />
        </article>
      </div>
    </main>
  );
}
