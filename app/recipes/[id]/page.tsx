import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { RecipePhotoUploader } from "@/components/recipe-photo-uploader";
import { mediaSourceLabel, resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

type Props = { params: Promise<{ id: string }> };

export default async function RecipePage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const [{ data: recipe }, { data: claimsData }] = await Promise.all([
    supabase
      .from("recipes")
      .select("*, recipe_ingredients(*), recipe_steps(*), recipe_images(*)")
      .eq("id", id)
      .maybeSingle(),
    supabase.auth.getClaims(),
  ]);

  if (!recipe) notFound();

  const { data: author } = await supabase
    .from("profiles")
    .select("display_name,username")
    .eq("id", recipe.author_id)
    .maybeSingle();

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

  const userId = typeof claimsData?.claims?.sub === "string" ? claimsData.claims.sub : null;
  const isOwner = userId === recipe.author_id;
  const primaryImage = images.find((image) => image.is_primary) ?? images[0] ?? null;

  return (
    <main className="recipe-page">
      <div className="recipe-detail-shell">
        <div className="account-topbar">
          <Link href="/" className="logo-lockup">
            <span className="logo-globe">🌍</span>
            <span><strong>Cuisine du monde</strong><small>Recette</small></span>
          </Link>
          <div className="recipe-top-actions">
            <Link href="/explore" className="ghost-button">🌍 Globe</Link>
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
            <div className="recipe-media-placeholder">
              <span>🍽️</span>
              <strong>Photo du plat à venir</strong>
              <small>Les photos réelles, licenciées ou générées apparaîtront ici.</small>
            </div>
          )}

          <span className="eyebrow">{recipe.country_code || "Cuisine du monde"} · {recipe.category || "Recette"}</span>
          <h1>{recipe.title}</h1>
          <p className="recipe-author">Par {author?.display_name || author?.username || "un membre"}</p>
          {recipe.description ? <p className="recipe-lead">{recipe.description}</p> : null}

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

          {isOwner && userId ? (
            <RecipePhotoUploader
              recipeId={recipe.id}
              userId={userId}
              recipeTitle={recipe.title}
              hasPrimaryImage={images.some((image) => image.is_primary)}
            />
          ) : null}

          <div className="recipe-columns">
            <section>
              <h2>Ingrédients</h2>
              <ul className="ingredient-list">
                {ingredients.map((item) => (
                  <li key={item.id}>
                    <strong>{item.quantity ?? ""} {item.unit ?? ""}</strong> {item.name}
                    {item.note ? <small>{item.note}</small> : null}
                  </li>
                ))}
              </ul>
            </section>
            <section>
              <h2>Préparation</h2>
              <ol className="step-list">
                {steps.map((step) => <li key={step.id}>{step.instruction}</li>)}
              </ol>
            </section>
          </div>
        </article>
      </div>
    </main>
  );
}
