"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { DemoRecipe } from "@/lib/demo-data";
import {
  defaultPreferences,
  PREFERENCES_STORAGE_KEY,
  UserPreferences,
} from "@/lib/preferences";

type CountryCard = {
  flag: string;
  name: string;
  dishes: string;
};

type Props = {
  recipes: DemoRecipe[];
  countries: CountryCard[];
};

const copy = {
  fr: {
    nav: ["Accueil", "Recettes", "Pays", "Catégories", "Desserts", "Soupes", "Communauté", "Chef IA"],
    hero: "Les meilleures recettes du monde entier",
    sub: "Des recettes authentiques, une communauté mondiale et un chef IA pour cuisiner sans frontières.",
    search: "Rechercher un plat, un pays ou un ingrédient…",
    featured: "Recettes en vedette",
    explore: "Explorer sur le globe",
    community: "Communauté gourmande",
    communityText: "Publiez vos recettes, échangez vos astuces et découvrez ce que le monde cuisine aujourd’hui.",
    publish: "Publier une recette",
    tools: "Tout pour mieux cuisiner",
  },
  en: {
    nav: ["Home", "Recipes", "Countries", "Categories", "Desserts", "Soups", "Community", "AI Chef"],
    hero: "The world’s best recipes in one place",
    sub: "Authentic recipes, a global community and an AI chef for cooking without borders.",
    search: "Search a dish, country or ingredient…",
    featured: "Featured recipes",
    explore: "Explore the globe",
    community: "Food community",
    communityText: "Publish your recipes, share tips and discover what the world is cooking today.",
    publish: "Publish a recipe",
    tools: "Everything you need to cook better",
  },
  es: {
    nav: ["Inicio", "Recetas", "Países", "Categorías", "Postres", "Sopas", "Comunidad", "Chef IA"],
    hero: "Las mejores recetas del mundo en un solo lugar",
    sub: "Recetas auténticas, una comunidad global y un chef IA para cocinar sin fronteras.",
    search: "Buscar un plato, país o ingrediente…",
    featured: "Recetas destacadas",
    explore: "Explorar el globo",
    community: "Comunidad gastronómica",
    communityText: "Publica tus recetas, comparte consejos y descubre lo que cocina el mundo.",
    publish: "Publicar una receta",
    tools: "Todo para cocinar mejor",
  },
} as const;

export function HomeExperience({ recipes, countries }: Props) {
  const [preferences, setPreferences] = useState<UserPreferences>(defaultPreferences);
  const [query, setQuery] = useState("");

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
      [recipe.title, recipe.country, recipe.category].some((value) =>
        value.toLowerCase().includes(normalized),
      ),
    );
  }, [query, recipes]);

  return (
    <main>
      <header className="site-header">
        <Link href="/" className="logo-lockup">
          <span className="logo-globe">🌍</span>
          <span>
            <strong>Cuisine du monde</strong>
            <small>Voyagez. Cuisinez. Partagez.</small>
          </span>
        </Link>
        <nav className="desktop-nav" aria-label="Navigation principale">
          {text.nav.map((item, index) => (
            <Link
              href={index === 2 ? "/explore" : item === text.nav[6] ? "#community" : "#"}
              key={item}
            >
              {item}
            </Link>
          ))}
        </nav>
        <div className="header-actions">
          <Link className="globe-shortcut" href="/explore" aria-label="Ouvrir la planète culinaire" title="Explorer la planète">
            🌍
          </Link>
          <span className="language-chip">{preferences.language.toUpperCase()}</span>
          <Link className="ghost-button" href="/onboarding">
            ⚙
          </Link>
          <Link className="ghost-button" href="/profile">Compte</Link>
          <Link className="compact-primary" href="/publish">{text.publish}</Link>
        </div>
      </header>

      <section className="hero">
        <div className="hero-copy">
          <span className="hero-kicker">🌎 Un monde de saveurs</span>
          <h1>{text.hero}</h1>
          <p>{text.sub}</p>
          <div className="search-bar">
            <span aria-hidden="true">⌕</span>
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder={text.search}
              aria-label={text.search}
            />
            <button>Rechercher</button>
          </div>
          <div className="chip-row">
            {["🇮🇹 Italien", "🇲🇽 Mexicain", "🇯🇵 Japonais", "🥣 Soupes", "🍰 Desserts", "🌱 Végétarien"].map(
              (chip) => (
                <button key={chip} className="filter-chip">
                  {chip}
                </button>
              ),
            )}
          </div>
        </div>
        <Link className="hero-art hero-globe-link" href="/explore" aria-label="Ouvrir la planète Terre culinaire">
          <div className="continent">🌍</div>
          <div className="floating-dish dish-one">🍜</div>
          <div className="floating-dish dish-two">🥘</div>
          <div className="floating-dish dish-three">🍣</div>
          <p>Tourner la planète et choisir quoi manger</p>
        </Link>
      </section>

      <section className="content-section">
        <div className="section-heading">
          <div>
            <span className="eyebrow">À découvrir maintenant</span>
            <h2>{text.featured}</h2>
          </div>
          <a href="#">Voir toutes →</a>
        </div>
        <div className="recipe-grid">
          {filtered.map((recipe) => (
            <article className="recipe-card" key={recipe.title}>
              <div className="recipe-image">
                <Image src={recipe.image} alt={recipe.title} fill sizes="(max-width: 700px) 90vw, 280px" />
                <span className="country-badge">{recipe.flag} {recipe.country}</span>
                <button className="heart-button" aria-label="Ajouter aux favoris">♡</button>
              </div>
              <div className="recipe-body">
                <span className="recipe-category">{recipe.category}</span>
                <h3>{recipe.title}</h3>
                <div className="rating">★★★★★ <span>{recipe.rating} ({recipe.reviews})</span></div>
                <div className="recipe-meta">
                  <span>◷ {recipe.time}</span>
                  <span>♨ {recipe.difficulty}</span>
                </div>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="content-section country-section">
        <div className="section-heading">
          <div>
            <span className="eyebrow">Atlas culinaire</span>
            <h2>{text.explore}</h2>
          </div>
          <Link href="/explore">Ouvrir le globe →</Link>
        </div>
        <div className="country-grid">
          {countries.map((country) => (
            <article className="country-card" key={country.name}>
              <span>{country.flag}</span>
              <h3>{country.name}</h3>
              <p>{country.dishes}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="community-section" id="community">
        <div className="community-intro">
          <span className="eyebrow">Partage & découverte</span>
          <h2>{text.community}</h2>
          <p>{text.communityText}</p>
          <Link className="primary-button" href="/publish">{text.publish}</Link>
        </div>
        <div className="community-feed">
          <article>
            <div className="author-line"><span>👩🏻‍🍳</span><div><strong>LucieM</strong><small>Québec · il y a 2 h</small></div></div>
            <h3>Ma soupe pho familiale</h3>
            <p>Le bouillon mijote doucement depuis ce matin. Voici la version que ma famille préfère.</p>
            <div className="social-stats">♥ 248 &nbsp; 💬 32 &nbsp; 🔖 91</div>
          </article>
          <article>
            <div className="author-line"><span>👨🏽‍🍳</span><div><strong>MarcoCucina</strong><small>Naples · il y a 3 h</small></div></div>
            <h3>Pizza napolitaine maison</h3>
            <p>72 heures de fermentation et seulement quelques ingrédients. La pâte fait toute la différence.</p>
            <div className="social-stats">♥ 521 &nbsp; 💬 68 &nbsp; 🔖 174</div>
          </article>
          <article>
            <div className="author-line"><span>👩🏻‍🍳</span><div><strong>SakuraHana</strong><small>Tokyo · il y a 5 h</small></div></div>
            <h3>Mochis aux fraises</h3>
            <p>Une version simple et douce, parfaite pour apprendre la texture de la pâte mochi.</p>
            <div className="social-stats">♥ 376 &nbsp; 💬 41 &nbsp; 🔖 133</div>
          </article>
        </div>
      </section>

      <section className="content-section">
        <div className="section-heading">
          <div>
            <span className="eyebrow">Pensé pour le quotidien</span>
            <h2>{text.tools}</h2>
          </div>
        </div>
        <div className="feature-grid">
          <article><span>🌐</span><h3>Traduction automatique</h3><p>Recettes, profils et commentaires dans votre langue, avec accès au texte original.</p></article>
          <article><span>🤖</span><h3>Chef IA</h3><p>Substitutions, dépannage en cuisine, planification de repas et aide mains libres.</p></article>
          <article><span>⚖️</span><h3>Conversion intelligente</h3><p>Grammes, millilitres, onces, livres, tasses et portions selon vos préférences.</p></article>
          <article><span>🛒</span><h3>Liste de courses</h3><p>Ajoutez les ingrédients d’une recette et regroupez automatiquement les quantités.</p></article>
        </div>
      </section>
    </main>
  );
}
