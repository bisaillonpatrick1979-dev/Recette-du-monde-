import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

type Props = { params: Promise<{ id: string }> };

export default async function RecipePage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: recipe } = await supabase
    .from("recipes")
    .select("*, recipe_ingredients(*), recipe_steps(*)")
    .eq("id", id)
    .maybeSingle();

  if (!recipe) notFound();

  const { data: author } = await supabase
    .from("profiles")
    .select("display_name,username")
    .eq("id", recipe.author_id)
    .maybeSingle();

  const ingredients = [...(recipe.recipe_ingredients ?? [])].sort((a, b) => a.position - b.position);
  const steps = [...(recipe.recipe_steps ?? [])].sort((a, b) => a.position - b.position);

  return (
    <main className="recipe-page">
      <div className="recipe-detail-shell">
        <div className="account-topbar">
          <Link href="/" className="logo-lockup">
            <span className="logo-globe">🌍</span>
            <span><strong>Cuisine du monde</strong><small>Recette</small></span>
          </Link>
          <Link href="/profile" className="ghost-button">Mon profil</Link>
        </div>

        <article className="recipe-detail-card">
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
