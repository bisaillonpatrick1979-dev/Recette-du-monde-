"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import type {
  HomeAtlasStats,
  HomeCommunityRecipe,
  HomeCountryCard,
  HomeRecipe,
} from "@/lib/home-data";
import {
  defaultPreferences,
  PREFERENCES_STORAGE_KEY,
  UserPreferences,
} from "@/lib/preferences";
import { OpenCountryCard } from "@/components/open-place-image";
import { ContinentRecipesModal } from "@/components/continent-recipes-modal";
import { CountryRecipesModal } from "@/components/country-recipes-modal";
import { LocalizedRecipeTitle } from "@/components/localized-recipe-title";
import { OpenRecipeImage } from "@/components/open-recipe-image";
import type { ContinentKey } from "@/lib/continents";

type Props = {
  recipes: HomeRecipe[];
  countries: HomeCountryCard[];
  communityRecipes: HomeCommunityRecipe[];
  stats: HomeAtlasStats;
};

const EARTH_IMAGE =
  "https://upload.wikimedia.org/wikipedia/commons/9/97/The_Earth_seen_from_Apollo_17.jpg";

const CONTINENT_PHOTOS = {
  "north-america": {
    url: "https://upload.wikimedia.org/wikipedia/commons/2/28/Moraine_lake_banff.jpg",
    alt: "Lac Moraine et Rocheuses canadiennes",
    author: "PDPhoto.org",
    license: "Domaine public",
    source: "https://commons.wikimedia.org/wiki/File:Moraine_lake_banff.jpg",
    licenseUrl: "https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia",
  },
  "latin-america": {
    url: "https://upload.wikimedia.org/wikipedia/commons/5/5a/Machu.jpg",
    alt: "Machu Picchu au Pérou",
    author: "Diespas",
    license: "Domaine public",
    source: "https://commons.wikimedia.org/wiki/File:Machu.jpg",
    licenseUrl: "https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia",
  },
  europe: {
    url: "https://upload.wikimedia.org/wikipedia/commons/1/10/Eiffel_tower_paris.jpg",
    alt: "Tour Eiffel à Paris",
    author: "John Salatas",
    license: "CC BY-SA 4.0",
    source: "https://commons.wikimedia.org/wiki/File:Eiffel_tower_paris.jpg",
    licenseUrl: "https://creativecommons.org/licenses/by-sa/4.0/",
  },
  asia: {
    url: "https://upload.wikimedia.org/wikipedia/commons/9/9e/Chureito_Pagoda_and_Mount_Fuji.jpg",
    alt: "Pagode Chureito, mont Fuji et cerisiers au Japon",
    author: "Manishprabhune",
    license: "CC BY-SA 4.0",
    source: "https://commons.wikimedia.org/wiki/File:Chureito_Pagoda_and_Mount_Fuji.jpg",
    licenseUrl: "https://creativecommons.org/licenses/by-sa/4.0/",
  },
  africa: {
    url: "https://upload.wikimedia.org/wikipedia/commons/e/e1/Amboseli_National_Park_and_Mt._Kilimanjaro.jpg",
    alt: "Éléphants à Amboseli devant le Kilimandjaro",
    author: "Ninaras",
    license: "CC BY 4.0",
    source: "https://commons.wikimedia.org/wiki/File:Amboseli_National_Park_and_Mt._Kilimanjaro.jpg",
    licenseUrl: "https://creativecommons.org/licenses/by/4.0/",
  },
  "middle-east": {
    url: "https://upload.wikimedia.org/wikipedia/commons/b/b8/Petra%2C_Jordan.jpg",
    alt: "Pétra en Jordanie",
    author: "Vyacheslav Argenberg",
    license: "CC BY 4.0",
    source: "https://commons.wikimedia.org/wiki/File:Petra,_Jordan.jpg",
    licenseUrl: "https://creativecommons.org/licenses/by/4.0/",
  },
  oceania: {
    url: "https://upload.wikimedia.org/wikipedia/commons/2/2e/Sydney_Opera_House_and_Sydney_Harbour_Bridge.jpg",
    alt: "Opéra de Sydney et Harbour Bridge en Australie",
    author: "Charles J. Sharp",
    license: "CC BY-SA 4.0",
    source: "https://commons.wikimedia.org/wiki/File:Sydney_Opera_House_and_Sydney_Harbour_Bridge.jpg",
    licenseUrl: "https://creativecommons.org/licenses/by-sa/4.0/",
  },
} as const;

const categoryCards = [
  { icon: "🍢", label: "Entrées" },
  { icon: "🥣", label: "Soupes" },
  { icon: "🍲", label: "Plats principaux" },
  { icon: "🥗", label: "Salades" },
  { icon: "🍝", label: "Pâtes" },
  { icon: "🥩", label: "Viandes" },
  { icon: "🐟", label: "Poissons et fruits de mer" },
  { icon: "🌿", label: "Végétarien" },
  { icon: "🍰", label: "Desserts" },
];

const quickFilters = [
  "⚡ 30 minutes et moins",
  "🍲 Instant Pot",
  "🔥 BBQ",
  "🌿 Santé",
  "👨‍👩‍👧‍👦 Repas en famille",
  "💰 Économique",
  "⭐ Les plus populaires",
];

const copy = {
  fr: {
    search: "Rechercher une recette, un pays, un plat, un ingrédient…",
    community: "La cuisine du monde, faite aussi par le monde",
  },
  en: {
    search: "Search a recipe, country, dish or ingredient…",
    community: "World cuisine, also made by the world",
  },
  es: {
    search: "Buscar una receta, país, plato o ingrediente…",
    community: "La cocina del mundo, hecha también por el mundo",
  },
} as const;

export function HomeExperience({
  recipes,
  countries,
  communityRecipes,
  stats,
}: Props) {
  const [preferences, setPreferences] = useState<UserPreferences>(defaultPreferences);
  const [query, setQuery] = useState("");
  const [activeContinent, setActiveContinent] = useState<{ key: ContinentKey; label: string } | null>(null);
  const [activeCountry, setActiveCountry] = useState<{ code: string; name: string; flag: string } | null>(null);
  const featuredRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const saved = window.localStorage.getItem(PREFERENCES_STORAGE_KEY);
    if (!saved) return;
    try {
      setPreferences(JSON.parse(saved) as UserPreferences);
    } catch {
      setPreferences(defaultPreferences);
    }
  }, []);

  const text = copy[preferences.language] ?? copy.fr;

  const filtered = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) return recipes;
    return recipes.filter((recipe) =>
      [
        recipe.title,
        recipe.originalTitle,
        ...recipe.titleTranslations.map((item) => item.title),
        recipe.country,
        recipe.region ?? "",
        recipe.category,
      ].some((value) =>
        value.toLowerCase().includes(normalized),
      ),
    );
  }, [query, recipes]);

  function scrollFeatured(direction: -1 | 1) {
    const track = featuredRef.current;
    if (!track) return;
    track.scrollBy({
      left: direction * Math.max(track.clientWidth * 0.82, 280),
      behavior: "smooth",
    });
  }

  return (
    <main className="planet-home">
      <header className="planet-header">
        <button className="planet-icon-button" type="button" aria-label="Menu">☰</button>
        <Link href="/" className="planet-brand">
          <span className="planet-brand-leaf">◒</span>
          <strong>Recette de la planète</strong>
        </Link>
        <div className="planet-header-actions">
          <Link href="/community" className="planet-icon-button" aria-label="Communauté">♡</Link>
          <Link href="/profile" className="planet-icon-button" aria-label="Mon profil">●</Link>
        </div>
      </header>

      <section className="planet-hero">
        <Link href="/explore" className="earth-visual" aria-label="Explorer la planète culinaire">
          <div className="earth-photo">
            <Image
              src={EARTH_IMAGE}
              alt="La planète Terre vue depuis Apollo 17"
              fill
              priority
              sizes="(max-width: 760px) 72vw, 390px"
            />
          </div>
          <div className="earth-touch-note">
            <span>↗</span>
            <strong>Touchez le globe<br />pour explorer !</strong>
          </div>
        </Link>

        <div className="planet-hero-copy">
          <p className="planet-script">Un monde de saveurs à portée de main !</p>
          <h1>Recette<br />de la planète</h1>

          <div className="world-counter" aria-label="Nombre total de recettes">
            <span className="world-counter-icon">◎</span>
            <div>
              <strong>{stats.recipes.toLocaleString("fr-CA")}</strong>
              <span>recettes du monde entier</span>
            </div>
          </div>

          <div className="world-substats">
            <div><strong>{stats.countries}</strong><span>pays</span></div>
            <div><strong>7</strong><span>grandes régions</span></div>
            <div><strong>{stats.subplaces}</strong><span>régions et villes</span></div>
          </div>

          <p className="planet-side-note">Cuisiner<br />Rassembler<br />Découvrir<br />Partager ♡</p>
        </div>
      </section>

      <section className="planet-search-wrap">
        <div className="planet-search">
          <span aria-hidden="true">⌕</span>
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder={text.search}
            aria-label={text.search}
          />
          <button type="button">Rechercher</button>
        </div>
      </section>

      <section className="planet-section">
        <div className="planet-section-heading">
          <h2>Explorer par continent</h2>
          <Link href="/explore">⌘ Voir la carte du monde →</Link>
        </div>
        <div className="continent-strip">
          {stats.continents.map((continent) => {
            const photo = CONTINENT_PHOTOS[continent.key];
            return (
              <article className={`continent-card continent-${continent.key}`} key={continent.key}>
                <button
                  type="button"
                  className="continent-card-main"
                  onClick={() =>
                    setActiveContinent({
                      key: continent.key as ContinentKey,
                      label: continent.label,
                    })
                  }
                  aria-label={`Voir les recettes de ${continent.label}`}
                >
                  <div className="continent-art">
                    <Image
                      src={photo.url}
                      alt={photo.alt}
                      fill
                      sizes="190px"
                    />
                  </div>
                  <div className="continent-card-body">
                    <strong>{continent.label}</strong>
                    <span>{continent.recipes.toLocaleString("fr-CA")} recettes</span>
                    <small>Voir les recettes →</small>
                  </div>
                </button>
                <div className="continent-photo-credit">
                  <a href={photo.source} target="_blank" rel="noreferrer">{photo.author}</a>
                  <span> · </span>
                  <a href={photo.licenseUrl} target="_blank" rel="noreferrer">{photo.license}</a>
                </div>
              </article>
            );
          })}
        </div>
      </section>

      <section className="planet-section compact-section">
        <div className="planet-section-heading">
          <h2>Explorer par catégorie</h2>
          <Link href="/explore">Voir toutes les catégories →</Link>
        </div>
        <div className="category-strip">
          {categoryCards.map((category) => (
            <button className="category-card" type="button" key={category.label}>
              <span>{category.icon}</span>
              <strong>{category.label}</strong>
            </button>
          ))}
        </div>

        <h3 className="quick-title">Filtres rapides</h3>
        <div className="quick-filters">
          {quickFilters.map((filter) => (
            <button type="button" key={filter}>{filter}</button>
          ))}
        </div>
      </section>

      <section className="planet-section">
        <div className="planet-section-heading">
          <div>
            <span className="planet-eyebrow">Sélection officielle</span>
            <h2>Recettes populaires autour du monde</h2>
          </div>
          <div className="featured-heading-actions">
            <button type="button" className="carousel-arrow" onClick={() => scrollFeatured(-1)} aria-label="Précédentes">‹</button>
            <button type="button" className="carousel-arrow" onClick={() => scrollFeatured(1)} aria-label="Suivantes">›</button>
            <Link href="/explore">Voir plus →</Link>
          </div>
        </div>

        <div className="planet-recipe-carousel" ref={featuredRef} tabIndex={0}>
          {filtered.map((recipe) => (
            <Link className="planet-recipe-card" key={recipe.id} href={`/recipes/${recipe.id}`}>
              <div className="planet-recipe-image">
                {recipe.image ? (
                  <Image src={recipe.image} alt={recipe.title} fill sizes="(max-width: 700px) 78vw, 270px" />
                ) : (
                  <OpenRecipeImage
                    title={recipe.originalTitle}
                    countryCode={recipe.countryCode}
                    className="home-reference-image"
                    showCredit={false}
                  />
                )}
                <span className="planet-official-badge">✓ Recette de l’application</span>
              </div>
              <div className="planet-recipe-body">
                <span>{recipe.flag} {recipe.region || recipe.country}</span>
                <h3>
                  <LocalizedRecipeTitle
                    originalTitle={recipe.originalTitle}
                    translations={recipe.titleTranslations}
                  />
                </h3>
                <small>{recipe.category} · {recipe.time} · {recipe.difficulty}</small>
              </div>
            </Link>
          ))}
        </div>
      </section>

      <section className="planet-community" id="community">
        <div className="community-banner-copy">
          <span className="planet-eyebrow">Communauté mondiale</span>
          <h2>{text.community}</h2>
          <p>
            Les recettes officielles restent séparées. Ici, les membres publient leurs propres recettes,
            ajoutent leurs photos, suivent d’autres cuisiniers, donnent une note et discutent dans les commentaires.
          </p>
          <div className="community-banner-actions">
            <Link href="/community" className="primary-button">Découvrir la communauté</Link>
            <Link href="/publish" className="secondary-button">+ Publier ma recette</Link>
          </div>
          <div className="community-live-stats">
            <span><strong>{stats.communityRecipes}</strong> recettes utilisateurs</span>
            <span><strong>{stats.editorialRecipes}</strong> recettes officielles</span>
          </div>
        </div>

        <div className="community-preview-grid">
          {communityRecipes.length ? (
            communityRecipes.slice(0, 4).map((recipe) => (
              <Link href={`/recipes/${recipe.id}`} className="community-preview-card" key={recipe.id}>
                <div className="community-preview-media">
                  {recipe.image ? <Image src={recipe.image} alt={recipe.title} fill sizes="320px" /> : <span>🍳</span>}
                </div>
                <div>
                  <small>Par {recipe.author}{recipe.authorCountry ? ` · ${recipe.authorCountry}` : ""}</small>
                  <h3>{recipe.title}</h3>
                  <p>♥ {recipe.likes} · 💬 {recipe.comments} · ★ {recipe.rating ? recipe.rating.toFixed(1) : "—"}</p>
                </div>
              </Link>
            ))
          ) : (
            <>
              <article className="community-feature-card"><span>📸</span><h3>Photos de vos plats</h3><p>Publiez vos créations dans un espace distinct des recettes officielles.</p></article>
              <article className="community-feature-card"><span>⭐</span><h3>Notes & avis</h3><p>Évaluez une recette et partagez ce que vous avez changé ou amélioré.</p></article>
              <article className="community-feature-card"><span>💬</span><h3>Commentaires</h3><p>Posez des questions et échangez directement entre cuisiniers.</p></article>
              <article className="community-feature-card"><span>👥</span><h3>Abonnements</h3><p>Suivez les membres dont vous aimez la cuisine et retrouvez leurs nouveautés.</p></article>
            </>
          )}
        </div>
      </section>

      <section className="planet-section country-discovery">
        <div className="planet-section-heading">
          <div><span className="planet-eyebrow">Voyager par les saveurs</span><h2>Pays à découvrir</h2></div>
          <Link href="/explore">Explorer la planète →</Link>
        </div>
        <div className="planet-country-grid">
          {countries.map((country) => (
            <OpenCountryCard
              key={country.name}
              name={country.name}
              countryCode={country.countryCode}
              flag={country.flag}
              dishes={country.dishes}
              onSelect={() =>
                setActiveCountry({
                  code: country.countryCode,
                  name: country.name,
                  flag: country.flag,
                })
              }
            />
          ))}
        </div>
      </section>

      <footer className="planet-footer">
        <div><strong>Des recettes d’aujourd’hui et de toujours…</strong></div>
        <div className="planet-footer-links">
          <Link href="/explore">◎ Découvrir</Link>
          <Link href="/publish">♨ Cuisiner</Link>
          <Link href="/community">♧ Partager</Link>
          <Link href="/profile">♡ Mon espace</Link>
        </div>
        <span>Bon appétit, le monde ! ♡</span>
      </footer>

      <nav className="planet-mobile-nav" aria-label="Navigation mobile">
        <Link href="/"><span>⌂</span>Accueil</Link>
        <Link href="/explore"><span>◎</span>Explorer</Link>
        <Link href="/profile"><span>▢</span>Mes recettes</Link>
        <Link href="/community"><span>♡</span>Communauté</Link>
        <Link href="/onboarding"><span>•••</span>Plus</Link>
      </nav>

      {activeContinent ? (
        <ContinentRecipesModal
          continentKey={activeContinent.key}
          continentLabel={activeContinent.label}
          onClose={() => setActiveContinent(null)}
        />
      ) : null}

      {activeCountry ? (
        <CountryRecipesModal
          countryCode={activeCountry.code}
          countryName={activeCountry.name}
          flag={activeCountry.flag}
          onClose={() => setActiveCountry(null)}
        />
      ) : null}
    </main>
  );
}
