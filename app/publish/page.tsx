import Link from "next/link";
import { redirect } from "next/navigation";
import { createRecipe } from "@/app/publish/actions";
import { createClient } from "@/lib/supabase/server";

type Props = { searchParams: Promise<{ error?: string }> };

export default async function PublishPage({ searchParams }: Props) {
  const params = await searchParams;
  const supabase = await createClient();
  const { data: claimsData } = await supabase.auth.getClaims();

  if (!claimsData?.claims?.sub) {
    redirect("/login");
  }

  const { data: places } = await supabase
    .from("culinary_places")
    .select("id, name, country_code, place_type, parent_id")
    .eq("is_active", true)
    .order("country_code")
    .order("name");

  const placeRows = places ?? [];
  const placeById = new Map(placeRows.map((place) => [place.id, place]));

  function placeLabel(place: (typeof placeRows)[number]) {
    const parts: string[] = [];
    const visited = new Set<string>();
    let current: (typeof placeRows)[number] | undefined = place;

    while (current && !visited.has(current.id)) {
      visited.add(current.id);
      parts.push(current.name);
      current = current.parent_id ? placeById.get(current.parent_id) : undefined;
    }

    return parts.reverse().join(" › ");
  }

  const sortedPlaces = [...placeRows].sort((a, b) =>
    placeLabel(a).localeCompare(placeLabel(b), "fr"),
  );

  return (
    <main className="publish-page">
      <div className="publish-shell">
        <div className="account-topbar">
          <Link href="/" className="logo-lockup">
            <span className="logo-globe">🌍</span>
            <span><strong>Cuisine du monde</strong><small>Nouvelle recette</small></span>
          </Link>
          <Link href="/profile" className="ghost-button">Mon profil</Link>
        </div>

        <form action={createRecipe} className="publish-card">
          <div className="onboarding-heading">
            <span className="step-pill">Partager une recette</span>
            <h1>Votre recette, votre histoire</h1>
            <p>
              Ajoutez la recette originale et choisissez le lieu d’origine le plus précis connu.
              Une recette de Bukavu restera aussi découvrable dans Sud-Kivu et en RDC.
            </p>
          </div>

          {params.error ? <p className="form-alert error">{params.error}</p> : null}

          <div className="form-grid">
            <label className="span-2"><span>Titre</span><input name="title" required minLength={2} /></label>
            <label className="span-2"><span>Description</span><textarea name="description" rows={4} /></label>

            <label className="span-2">
              <span>Lieu d’origine précis</span>
              <select name="place_id" defaultValue="">
                <option value="">Choisir dans l’atlas (optionnel)</option>
                {sortedPlaces.map((place) => (
                  <option value={place.id} key={place.id}>
                    {placeLabel(place)}
                  </option>
                ))}
              </select>
              <small className="form-help">
                Choisissez la ville ou région la plus précise disponible. Le pays et la région seront remplis automatiquement.
              </small>
            </label>

            <label><span>Pays — si le lieu n’est pas encore dans l’atlas</span><input name="country_code" placeholder="CA, IT, JP…" maxLength={3} /></label>
            <label><span>Région — si le lieu n’est pas encore dans l’atlas</span><input name="region" placeholder="Québec, Toscane…" /></label>
            <label><span>Catégorie</span><input name="category" placeholder="Soupe, dessert, BBQ…" /></label>
            <label><span>Langue originale</span><input name="source_language" defaultValue="fr" /></label>
            <label><span>Authenticité</span>
              <select name="authenticity" defaultValue="adapted">
                <option value="traditional">Traditionnelle</option>
                <option value="adapted">Adaptée</option>
                <option value="fusion">Fusion</option>
              </select>
            </label>
            <label><span>Difficulté</span>
              <select name="difficulty" defaultValue="easy">
                <option value="easy">Facile</option>
                <option value="medium">Moyenne</option>
                <option value="hard">Difficile</option>
              </select>
            </label>
            <label><span>Préparation (min)</span><input name="prep_minutes" type="number" min="0" /></label>
            <label><span>Cuisson (min)</span><input name="cook_minutes" type="number" min="0" /></label>
            <label><span>Portions</span><input name="servings" type="number" min="0.25" step="0.25" /></label>
            <label><span>Publication</span>
              <select name="status" defaultValue="published">
                <option value="published">Publier maintenant</option>
                <option value="draft">Enregistrer en brouillon</option>
              </select>
            </label>
            <label className="span-2">
              <span>Ingrédients — quantité | unité | ingrédient</span>
              <textarea name="ingredients" rows={8} placeholder={"2 | tasse | farine\n1 | c. à thé | sel\n500 | g | poulet"} />
            </label>
            <label className="span-2">
              <span>Étapes — une ligne par étape</span>
              <textarea name="steps" rows={10} placeholder={"Préchauffer le four.\nMélanger les ingrédients.\nCuire jusqu’à cuisson complète."} />
            </label>
          </div>

          <button className="primary-button" type="submit">Enregistrer la recette</button>
        </form>
      </div>
    </main>
  );
}
