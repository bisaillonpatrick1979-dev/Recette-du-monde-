import Image from "next/image";
import Link from "next/link";
import { redirect } from "next/navigation";
import { signOut } from "@/app/auth/actions";
import { LocalizedRecipeTitle } from "@/components/localized-recipe-title";
import { NotificationBell } from "@/components/notification-bell";
import { OpenRecipeImage } from "@/components/open-recipe-image";
import { isTrustedRecipeImage, resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

const FAVORITES_SHOWN = 24;

const LANGUAGE_LABELS: Record<string, string> = { fr: "Français", en: "English", es: "Español" };
const MEASUREMENT_LABELS: Record<string, string> = {
  metric: "Métrique (g, ml)",
  imperial: "Impérial (oz, lb)",
  cups: "Tasses et cuillères",
};
const STATUS_LABELS: Record<string, string> = { draft: "Brouillon", published: "Publiée", archived: "Archivée" };
const PLAN_LABELS: Record<string, string> = { free: "Gratuit", premium: "Premium", pro: "Pro" };

function countryName(code: string | null | undefined) {
  if (!code) return "—";
  try {
    return new Intl.DisplayNames(["fr"], { type: "region" }).of(code) ?? code;
  } catch {
    return code;
  }
}

export default async function ProfilePage() {
  const supabase = await createClient();
  const { data: claimsData, error } = await supabase.auth.getClaims();
  const userId = claimsData?.claims?.sub;

  if (error || !userId) {
    redirect("/login");
  }

  const [
    { data: profile },
    { data: preferences },
    { data: entitlements },
    { data: credits },
    { data: recipes },
    { data: favorites, count: favoritesCount },
    { count: cookedCount },
  ] = await Promise.all([
    supabase.from("profiles").select("*").eq("id", userId).maybeSingle(),
    supabase.from("user_preferences").select("*").eq("user_id", userId).maybeSingle(),
    supabase.from("entitlements").select("*").eq("user_id", userId).maybeSingle(),
    // Solde à jour (remise à zéro mensuelle comprise); repli sur la table si la fonction manque.
    supabase.rpc("credits_ia"),
    supabase
      .from("recipes")
      .select("id,title,status,created_at")
      .eq("author_id", userId)
      .order("created_at", { ascending: false })
      .limit(12),
    supabase
      .from("favorites")
      .select(
        "created_at,recipes(id,title,original_title,country_code,status,recipe_title_translations(language_code,title),recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status,source_type,source_page_url,moderation_notes))",
        { count: "exact" },
      )
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(FAVORITES_SHOWN),
    supabase.from("cook_attempts").select("id", { count: "exact", head: true }).eq("user_id", userId),
  ]);

  const balance = credits?.[0];
  const monthlyCredits = balance?.credits_mensuels ?? entitlements?.ai_monthly_credits ?? 10;
  const remainingCredits =
    balance?.credits_restants ?? Math.max(monthlyCredits - (entitlements?.ai_credits_used ?? 0), 0);
  const plan = balance?.forfait ?? entitlements?.plan_code ?? "free";
  const resetAt = balance?.fin_periode ?? entitlements?.period_end ?? null;

  const favoriteRecipes = (favorites ?? [])
    .map((favorite) => favorite.recipes)
    .filter((recipe): recipe is NonNullable<typeof recipe> => Boolean(recipe) && recipe?.status === "published")
    .map((recipe) => {
      const images = [...(recipe.recipe_images ?? [])]
        .filter(
          (image) =>
            image.status === "ready" &&
            isTrustedRecipeImage(image, { title: recipe.title, originalTitle: recipe.original_title }),
        )
        .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
      return { ...recipe, image: images[0] ? resolveMediaUrl(images[0], "recipe-images") : null };
    });

  return (
    <main className="account-page">
      <div className="account-shell">
        <div className="account-topbar">
          <Link href="/" className="logo-lockup">
            <span className="logo-globe">🌍</span>
            <span><strong>Spoontrotter</strong><small>Mon espace</small></span>
          </Link>
          <div className="recipe-top-actions">
            <NotificationBell />
            <form action={signOut}><button className="ghost-button">Déconnexion</button></form>
          </div>
        </div>

        <section className="profile-hero-card">
          <div className="profile-avatar">{profile?.display_name?.slice(0, 1).toUpperCase() || "👩‍🍳"}</div>
          <div>
            <span className="eyebrow">Profil</span>
            <h1>{profile?.display_name || "Nouveau cuisinier"}</h1>
            <p>{profile?.bio || "Votre cuisine peut maintenant voyager partout dans le monde, dans l’espace Communauté."}</p>
            <div className="public-profile-stats">
              <span><strong>{favoritesCount ?? 0}</strong> favoris</span>
              <span><strong>{cookedCount ?? 0}</strong> recettes cuisinées</span>
            </div>
          </div>
          <div className="profile-hero-actions">
            <Link className="primary-button" href="/publish">+ Publier une recette</Link>
            <Link className="secondary-button" href={`/cooks/${userId}`}>Voir mon profil public</Link>
          </div>
        </section>

        <section className="account-grid">
          <article className="account-card">
            <h2>Préférences</h2>
            <p><strong>Pays :</strong> {countryName(preferences?.country_code)}</p>
            <p><strong>Langue :</strong> {LANGUAGE_LABELS[preferences?.language_code ?? ""] ?? "—"}</p>
            <p><strong>Mesures :</strong> {MEASUREMENT_LABELS[preferences?.measurement_system ?? ""] ?? "—"}</p>
            <p><strong>Température :</strong> {preferences?.temperature_unit === "f" ? "°F" : "°C"}</p>
            <Link href="/onboarding">Modifier mes préférences →</Link>
          </article>

          <article className="account-card">
            <h2>Chef IA</h2>
            <p className="big-stat">{remainingCredits} / {monthlyCredits}</p>
            <p>
              questions restantes ce mois-ci
              {resetAt
                ? ` · renouvelées le ${new Date(resetAt).toLocaleDateString("fr-CA", { day: "numeric", month: "long" })}`
                : ""}
            </p>
            <span className="plan-chip">Forfait {PLAN_LABELS[plan] ?? plan}</span>
            <p className="muted">Posez vos questions depuis n’importe quelle recette, dans la section « Chef IA ».</p>
          </article>
        </section>

        <section className="account-card" id="favoris">
          <div className="section-heading">
            <div><span className="eyebrow">Mis de côté</span><h2>Mes favoris</h2></div>
            <Link href="/search">Trouver des recettes →</Link>
          </div>
          {favoriteRecipes.length ? (
            <div className="continent-page-grid favorite-grid">
              {favoriteRecipes.map((recipe) => (
                <Link href={`/recipes/${recipe.id}`} className="continent-page-card" key={recipe.id}>
                  <div className="continent-page-card-image">
                    {recipe.image ? (
                      <Image src={recipe.image} alt={recipe.title} fill sizes="(max-width: 680px) 50vw, 240px" />
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
                    <small>{countryName(recipe.country_code)}</small>
                    <h2>
                      <LocalizedRecipeTitle
                        originalTitle={recipe.original_title || recipe.title}
                        translations={recipe.recipe_title_translations ?? []}
                      />
                    </h2>
                  </div>
                </Link>
              ))}
            </div>
          ) : (
            <p className="muted">
              Aucun favori pour l’instant. Touchez « ☆ Ajouter aux favoris » sur une recette pour la retrouver ici.
            </p>
          )}
        </section>

        <section className="account-card">
          <div className="section-heading">
            <div><span className="eyebrow">Recettes de la communauté</span><h2>Mes recettes</h2></div>
            <Link href="/publish">Nouvelle recette →</Link>
          </div>
          {recipes?.length ? (
            <div className="my-recipes-list">
              {recipes.map((recipe) => (
                <Link href={`/recipes/${recipe.id}`} key={recipe.id}>
                  <strong>{recipe.title}</strong>
                  <span>{STATUS_LABELS[recipe.status] ?? recipe.status}</span>
                </Link>
              ))}
            </div>
          ) : (
            <p className="muted">Vous n’avez encore publié aucune recette.</p>
          )}
        </section>
      </div>
    </main>
  );
}
