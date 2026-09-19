import Link from "next/link";
import { redirect } from "next/navigation";
import { signOut } from "@/app/auth/actions";
import { createClient } from "@/lib/supabase/server";

export default async function ProfilePage() {
  const supabase = await createClient();
  const { data: claimsData, error } = await supabase.auth.getClaims();
  const userId = claimsData?.claims?.sub;

  if (error || !userId) {
    redirect("/login");
  }

  const [{ data: profile }, { data: preferences }, { data: entitlements }, { data: recipes }] =
    await Promise.all([
      supabase.from("profiles").select("*").eq("id", userId).maybeSingle(),
      supabase.from("user_preferences").select("*").eq("user_id", userId).maybeSingle(),
      supabase.from("entitlements").select("*").eq("user_id", userId).maybeSingle(),
      supabase
        .from("recipes")
        .select("id,title,status,created_at")
        .eq("author_id", userId)
        .order("created_at", { ascending: false })
        .limit(12),
    ]);

  return (
    <main className="account-page">
      <div className="account-shell">
        <div className="account-topbar">
          <Link href="/" className="logo-lockup">
            <span className="logo-globe">🌍</span>
            <span><strong>Cuisine du monde</strong><small>Mon espace</small></span>
          </Link>
          <form action={signOut}><button className="ghost-button">Déconnexion</button></form>
        </div>

        <section className="profile-hero-card">
          <div className="profile-avatar">{profile?.display_name?.slice(0, 1).toUpperCase() || "👩‍🍳"}</div>
          <div>
            <span className="eyebrow">Profil</span>
            <h1>{profile?.display_name || "Nouveau cuisinier"}</h1>
            <p>{profile?.bio || "Votre cuisine peut maintenant voyager partout dans le monde."}</p>
          </div>
          <Link className="primary-button" href="/publish">+ Publier une recette</Link>
        </section>

        <section className="account-grid">
          <article className="account-card">
            <h2>Préférences</h2>
            <p><strong>Pays :</strong> {preferences?.country_code ?? "—"}</p>
            <p><strong>Langue :</strong> {preferences?.language_code ?? "—"}</p>
            <p><strong>Mesures :</strong> {preferences?.measurement_system ?? "—"}</p>
            <p><strong>Température :</strong> {preferences?.temperature_unit === "f" ? "°F" : "°C"}</p>
            <Link href="/onboarding">Modifier mes préférences →</Link>
          </article>

          <article className="account-card">
            <h2>Forfait IA</h2>
            <p className="big-stat">{entitlements?.ai_credits_used ?? 0} / {entitlements?.ai_monthly_credits ?? 10}</p>
            <p>crédits utilisés ce mois-ci</p>
            <span className="plan-chip">{entitlements?.plan_code ?? "free"}</span>
          </article>
        </section>

        <section className="account-card">
          <div className="section-heading">
            <div><span className="eyebrow">Vos créations</span><h2>Mes recettes</h2></div>
            <Link href="/publish">Nouvelle recette →</Link>
          </div>
          {recipes?.length ? (
            <div className="my-recipes-list">
              {recipes.map((recipe) => (
                <Link href={`/recipes/${recipe.id}`} key={recipe.id}>
                  <strong>{recipe.title}</strong>
                  <span>{recipe.status}</span>
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
