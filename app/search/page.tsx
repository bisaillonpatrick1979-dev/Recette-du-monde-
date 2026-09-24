import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { LocalizedRecipeTitle } from "@/components/localized-recipe-title";
import { OpenRecipeImage } from "@/components/open-recipe-image";
import { BORDERLESS_LABEL } from "@/lib/continents";
import { resolveMediaUrl } from "@/lib/media";
import { QUICK_FILTERS, SEARCH_CATEGORIES, ilikePattern } from "@/lib/search-filters";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = {
  title: "Recherche | Cuisine du monde",
};

type Props = {
  searchParams: Promise<{ q?: string; categorie?: string; filtre?: string }>;
};

function flagFor(code: string | null) {
  if (!code || code.length !== 2) return "🌐";
  return code
    .toUpperCase()
    .replace(/[A-Z]/g, (letter) => String.fromCodePoint(127397 + letter.charCodeAt(0)));
}

export default async function SearchPage({ searchParams }: Props) {
  const params = await searchParams;
  const q = (params.q ?? "").trim().slice(0, 80);
  const category = SEARCH_CATEGORIES.find((item) => item.key === params.categorie) ?? null;
  const filter = QUICK_FILTERS.find((item) => item.key === params.filtre) ?? null;
  const supabase = await createClient();

  let query = supabase
    .from("recipes")
    .select(
      "id,title,original_title,country_code,region,category,prep_minutes,cook_minutes,is_borderless,published_at,recipe_title_translations(language_code,title),recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status),recipe_likes(count)",
    )
    .eq("status", "published");

  const textPattern = q ? ilikePattern(q) : null;
  if (textPattern) {
    query = query.or(`search_text.ilike.${textPattern},original_title.ilike.${textPattern}`);
  }

  const patterns = [...(category?.patterns ?? []), ...(filter?.patterns ?? [])]
    .map(ilikePattern)
    .filter((value): value is string => Boolean(value));
  if (patterns.length) {
    query = query.or(patterns.map((pattern) => `search_text.ilike.${pattern}`).join(","));
  }

  const { data, error } = await query.order("published_at", { ascending: false }).limit(300);

  const displayNames = new Intl.DisplayNames(["fr"], { type: "region" });
  let results = (data ?? []).map((recipe) => {
    const images = [...(recipe.recipe_images ?? [])]
      .filter((image) => image.status === "ready")
      .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
    const totalMinutes = (recipe.prep_minutes ?? 0) + (recipe.cook_minutes ?? 0);
    return {
      ...recipe,
      image: images[0] ? resolveMediaUrl(images[0], "recipe-images") : null,
      totalMinutes: totalMinutes || null,
      likes: recipe.recipe_likes?.[0]?.count ?? 0,
      origin: recipe.country_code
        ? [displayNames.of(recipe.country_code) || recipe.country_code, recipe.region].filter(Boolean).join(" · ")
        : BORDERLESS_LABEL,
    };
  });

  if (filter?.maxMinutes) {
    const max = filter.maxMinutes;
    results = results.filter((recipe) => recipe.totalMinutes !== null && recipe.totalMinutes <= max);
  }
  if (filter?.popular) {
    results = [...results].sort((a, b) => b.likes - a.likes);
  }

  const heading = category?.label || filter?.label || (q ? `« ${q} »` : "Toutes les recettes");

  return (
    <main className="continent-page">
      <div className="continent-page-shell">
        <header className="continent-page-header">
          <Link href="/" className="continent-page-back">← Accueil</Link>
          <div>
            <span className="planet-eyebrow">Recherche</span>
            <h1>{heading}</h1>
            <p>{results.length.toLocaleString("fr-CA")} recette{results.length > 1 ? "s" : ""}</p>
          </div>
        </header>

        <form className="planet-search search-page-form" action="/search">
          <span aria-hidden="true">⌕</span>
          <input
            name="q"
            defaultValue={q}
            placeholder="Plat, ingrédient, pays, région…"
            aria-label="Rechercher une recette"
          />
          {category ? <input type="hidden" name="categorie" value={category.key} /> : null}
          {filter ? <input type="hidden" name="filtre" value={filter.key} /> : null}
          <button type="submit">Rechercher</button>
        </form>

        <nav className="quick-filters search-page-filters" aria-label="Catégories">
          {SEARCH_CATEGORIES.map((item) => (
            <Link
              key={item.key}
              href={item.key === category?.key ? "/search" : `/search?categorie=${item.key}`}
              className={item.key === category?.key ? "active" : ""}
            >
              {item.icon} {item.label}
            </Link>
          ))}
          {QUICK_FILTERS.map((item) => (
            <Link
              key={item.key}
              href={item.key === filter?.key ? "/search" : `/search?filtre=${item.key}`}
              className={item.key === filter?.key ? "active" : ""}
            >
              {item.label}
            </Link>
          ))}
        </nav>

        {error ? <p className="form-alert error">La recherche est temporairement indisponible.</p> : null}

        {results.length ? (
          <section className="continent-page-grid" aria-label="Résultats">
            {results.map((recipe) => (
              <Link href={`/recipes/${recipe.id}`} className="continent-page-card" key={recipe.id}>
                <div className="continent-page-card-image">
                  {recipe.image ? (
                    <Image
                      src={recipe.image}
                      alt={recipe.title}
                      fill
                      sizes="(max-width: 680px) 100vw, (max-width: 1050px) 50vw, 25vw"
                    />
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
                  <small>{flagFor(recipe.country_code)} {recipe.origin}</small>
                  <h2>
                    <LocalizedRecipeTitle
                      originalTitle={recipe.original_title || recipe.title}
                      translations={recipe.recipe_title_translations ?? []}
                    />
                  </h2>
                  <div className="continent-page-card-meta">
                    <span>{recipe.category || "Recette"}</span>
                    {recipe.totalMinutes ? <span>{recipe.totalMinutes} min</span> : null}
                    <span>♥ {recipe.likes}</span>
                  </div>
                </div>
              </Link>
            ))}
          </section>
        ) : (
          <section className="continent-modal-empty">
            <span>🔎</span>
            <h2>Aucune recette trouvée.</h2>
            <p>Essayez un autre mot, ou explorez la carte du monde.</p>
            <Link href="/explore" className="primary-button">🌍 Ouvrir le globe</Link>
          </section>
        )}
      </div>
    </main>
  );
}
