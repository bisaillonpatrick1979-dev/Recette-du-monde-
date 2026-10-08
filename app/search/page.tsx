import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { LocalizedRecipeTitle } from "@/components/localized-recipe-title";
import { OpenRecipeImage } from "@/components/open-recipe-image";
import { BORDERLESS_LABEL } from "@/lib/continents";
import { isTrustedRecipeImage, resolveMediaUrl } from "@/lib/media";
import { QUICK_FILTERS, SEARCH_CATEGORIES, ilikePattern } from "@/lib/search-filters";
import { fetchAllRows } from "@/lib/supabase/fetch-all";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = {
  title: "Recherche",
};

type Props = {
  searchParams: Promise<{ q?: string; categorie?: string; filtre?: string; page?: string }>;
};

function flagFor(code: string | null) {
  if (!code || code.length !== 2) return "🌐";
  return code
    .toUpperCase()
    .replace(/[A-Z]/g, (letter) => String.fromCodePoint(127397 + letter.charCodeAt(0)));
}

const PAGE_SIZE = 60;

type LightRecipe = {
  id: string;
  prep_minutes: number | null;
  cook_minutes: number | null;
  published_at: string | null;
  search_text: string | null;
  recipe_likes: Array<{ count: number }> | null;
};

const LIGHT_COLUMNS = "id,prep_minutes,cook_minutes,published_at,search_text,recipe_likes(count)";

function normalize(value: string) {
  return value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

export default async function SearchPage({ searchParams }: Props) {
  const params = await searchParams;
  const q = (params.q ?? "").trim().slice(0, 80);
  const category = SEARCH_CATEGORIES.find((item) => item.key === params.categorie) ?? null;
  const filter = QUICK_FILTERS.find((item) => item.key === params.filtre) ?? null;
  const page = Math.max(1, Math.min(500, Number.parseInt(params.page ?? "1", 10) || 1));
  const supabase = await createClient();
  const textPattern = q ? ilikePattern(q) : null;

  // 1. Ensemble complet des recettes correspondantes (colonnes légères), pour que
  //    filtres, tri et pagination s'appliquent à tout le catalogue.
  const [byText, byIngredient] = await Promise.all([
    fetchAllRows<LightRecipe>((from, to) => {
      let query = supabase.from("recipes").select(LIGHT_COLUMNS).eq("status", "published");
      if (textPattern) {
        query = query.or(`search_text.ilike.${textPattern},original_title.ilike.${textPattern}`);
      }
      return query.order("id").range(from, to);
    }),
    textPattern
      ? fetchAllRows<{ recipes: LightRecipe | null }>((from, to) =>
          supabase
            .from("recipe_ingredients")
            .select(`recipes!inner(${LIGHT_COLUMNS})`)
            .ilike("name", textPattern)
            .eq("recipes.status", "published")
            .order("id")
            .range(from, to),
        )
      : Promise.resolve({ data: [], error: null }),
  ]);

  const matches = new Map<string, LightRecipe>();
  for (const recipe of byText.data) matches.set(recipe.id, recipe);
  for (const row of byIngredient.data) {
    if (row.recipes) matches.set(row.recipes.id, row.recipes);
  }

  const patterns = [...(category?.patterns ?? []), ...(filter?.patterns ?? [])].map(normalize);
  let ranked = [...matches.values()]
    .filter((recipe) => {
      if (!patterns.length) return true;
      const text = normalize(recipe.search_text ?? "");
      return patterns.some((pattern) => text.includes(pattern));
    })
    .map((recipe) => ({
      id: recipe.id,
      publishedAt: recipe.published_at ?? "",
      totalMinutes: (recipe.prep_minutes ?? 0) + (recipe.cook_minutes ?? 0) || null,
      likes: recipe.recipe_likes?.[0]?.count ?? 0,
    }));

  if (filter?.maxMinutes) {
    const max = filter.maxMinutes;
    ranked = ranked.filter((recipe) => recipe.totalMinutes !== null && recipe.totalMinutes <= max);
  }
  ranked.sort((a, b) =>
    (filter?.popular ? b.likes - a.likes : 0) || b.publishedAt.localeCompare(a.publishedAt),
  );

  const total = ranked.length;
  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const pageIds = ranked.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE).map((recipe) => recipe.id);
  const rankById = new Map(ranked.map((recipe) => [recipe.id, recipe]));

  // 2. Détails complets pour la page affichée seulement.
  const { data, error: detailError } = pageIds.length
    ? await supabase
        .from("recipes")
        .select(
          "id,title,original_title,country_code,region,category,recipe_title_translations(language_code,title),recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status,source_type,source_page_url,moderation_notes)",
        )
        .in("id", pageIds)
    : { data: [], error: null };
  const error = byText.error || byIngredient.error || detailError;

  const displayNames = new Intl.DisplayNames(["fr"], { type: "region" });
  const detailById = new Map((data ?? []).map((recipe) => [recipe.id, recipe]));
  const results = pageIds.flatMap((id) => {
    const recipe = detailById.get(id);
    const rank = rankById.get(id);
    if (!recipe || !rank) return [];
    const images = [...(recipe.recipe_images ?? [])]
      .filter((image) => image.status === "ready" && isTrustedRecipeImage(image, { title: recipe.title, originalTitle: recipe.original_title }))
      .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
    return [{
      ...recipe,
      image: images[0] ? resolveMediaUrl(images[0], "recipe-images") : null,
      totalMinutes: rank.totalMinutes,
      likes: rank.likes,
      origin: recipe.country_code
        ? [displayNames.of(recipe.country_code) || recipe.country_code, recipe.region].filter(Boolean).join(" · ")
        : BORDERLESS_LABEL,
    }];
  });

  function pageHref(target: number) {
    const next = new URLSearchParams();
    if (q) next.set("q", q);
    if (category) next.set("categorie", category.key);
    if (filter) next.set("filtre", filter.key);
    if (target > 1) next.set("page", String(target));
    const value = next.toString();
    return value ? `/search?${value}` : "/search";
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
            <p>{total.toLocaleString("fr-CA")} recette{total > 1 ? "s" : ""}</p>
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
        ) : null}

        {pageCount > 1 ? (
          <nav className="search-pagination" aria-label="Pages de résultats">
            {page > 1 ? <Link href={pageHref(page - 1)} className="secondary-button">← Précédent</Link> : null}
            <span>Page {page} / {pageCount}</span>
            {page < pageCount ? <Link href={pageHref(page + 1)} className="secondary-button">Suivant →</Link> : null}
          </nav>
        ) : null}

        {!results.length ? (
          <section className="continent-modal-empty">
            <span>🔎</span>
            <h2>Aucune recette trouvée.</h2>
            <p>Essayez un autre mot, ou explorez la carte du monde.</p>
            <Link href="/explore" className="primary-button">🌍 Ouvrir le globe</Link>
          </section>
        ) : null}
      </div>
    </main>
  );
}
