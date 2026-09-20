"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { LocalizedRecipeTitle } from "@/components/localized-recipe-title";
import { OpenRecipeImage } from "@/components/open-recipe-image";

type CountryRecipe = {
  id: string;
  title: string;
  originalTitle: string;
  titleTranslations: Array<{ language_code: string; title: string }>;
  region: string | null;
  category: string;
  difficulty: "easy" | "medium" | "hard" | null;
  minutes: number | null;
  image: string | null;
  likes: number;
  rating: number | null;
  ratingCount: number;
};

type CountryPlace = {
  id: string;
  name: string;
  placeType: "region" | "city" | "island" | string;
  parentId: string | null;
  recipeIds: string[];
  recipeCount: number;
};

type Payload = {
  country: { code: string; name: string };
  total: number;
  places: CountryPlace[];
  recipes: CountryRecipe[];
};

function difficultyLabel(value: CountryRecipe["difficulty"]) {
  if (value === "hard") return "Difficile";
  if (value === "medium") return "Moyen";
  return "Facile";
}

export function CountryRecipesModal({
  countryCode,
  countryName,
  flag,
  onClose,
}: {
  countryCode: string;
  countryName: string;
  flag: string;
  onClose: () => void;
}) {
  const [data, setData] = useState<Payload | null>(null);
  const [state, setState] = useState<"loading" | "ready" | "error">("loading");
  const [activePlaceId, setActivePlaceId] = useState<string | null>(null);

  useEffect(() => {
    const previous = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    function onKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") onClose();
    }

    window.addEventListener("keydown", onKeyDown);
    return () => {
      document.body.style.overflow = previous;
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [onClose]);

  useEffect(() => {
    let cancelled = false;
    setState("loading");
    setData(null);
    setActivePlaceId(null);

    fetch("/api/countries/" + countryCode + "/recipes")
      .then(async (response) => {
        if (!response.ok) throw new Error("Unable to load country recipes");
        return (await response.json()) as Payload;
      })
      .then((payload) => {
        if (cancelled) return;
        setData(payload);
        setState("ready");
      })
      .catch(() => {
        if (cancelled) return;
        setState("error");
      });

    return () => {
      cancelled = true;
    };
  }, [countryCode]);

  const visibleRecipes = useMemo(() => {
    if (!data) return [];
    if (!activePlaceId) return data.recipes.slice(0, 8);

    const place = data.places.find((item) => item.id === activePlaceId);
    if (!place) return data.recipes.slice(0, 8);

    const allowed = new Set(place.recipeIds);
    return data.recipes.filter((recipe) => allowed.has(recipe.id)).slice(0, 8);
  }, [activePlaceId, data]);

  const groupedPlaces = useMemo(() => {
    if (!data) return { regions: [], cities: [], islands: [] as CountryPlace[] };
    return {
      regions: data.places.filter((place) => place.placeType === "region"),
      cities: data.places.filter((place) => place.placeType === "city"),
      islands: data.places.filter((place) => place.placeType === "island"),
    };
  }, [data]);

  const activePlace = data?.places.find((place) => place.id === activePlaceId) ?? null;

  return (
    <div className="continent-modal-backdrop" role="presentation" onMouseDown={onClose}>
      <section
        className="continent-modal country-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="country-modal-title"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <header className="continent-modal-header country-modal-header">
          <div>
            <span className="planet-eyebrow">Pays à découvrir</span>
            <h2 id="country-modal-title">{flag} {countryName}</h2>
            <p>
              {data
                ? data.total.toLocaleString("fr-CA") + " recettes officielles"
                : "Chargement des recettes…"}
            </p>
          </div>
          <button
            type="button"
            className="continent-modal-close"
            onClick={onClose}
            aria-label="Fermer"
          >
            ×
          </button>
        </header>

        {state === "loading" ? (
          <div className="continent-modal-loading">
            <span className="continent-modal-spinner" />
            <strong>Je rassemble les recettes de {countryName}…</strong>
          </div>
        ) : null}

        {state === "error" ? (
          <div className="continent-modal-empty">
            <span>🍽️</span>
            <h3>Impossible de charger ce pays pour le moment.</h3>
            <button type="button" onClick={onClose}>Fermer</button>
          </div>
        ) : null}

        {state === "ready" && data ? (
          <>
            {data.places.length ? (
              <section className="country-place-browser">
                <div className="country-place-heading">
                  <div>
                    <strong>Explorer les régions et les villes</strong>
                    <span>Choisissez un endroit pour filtrer les recettes liées à cette région ou cette ville.</span>
                  </div>
                  {activePlace ? (
                    <button type="button" onClick={() => setActivePlaceId(null)}>
                      Voir tout {countryName}
                    </button>
                  ) : null}
                </div>

                <div className="country-place-groups">
                  {groupedPlaces.regions.length ? (
                    <div>
                      <small>Régions</small>
                      <div className="country-place-chips">
                        {groupedPlaces.regions.map((place) => (
                          <button
                            type="button"
                            key={place.id}
                            className={activePlaceId === place.id ? "active" : ""}
                            onClick={() => setActivePlaceId(place.id)}
                          >
                            {place.name}
                            <span>{place.recipeCount}</span>
                          </button>
                        ))}
                      </div>
                    </div>
                  ) : null}

                  {groupedPlaces.cities.length ? (
                    <div>
                      <small>Villes</small>
                      <div className="country-place-chips">
                        {groupedPlaces.cities.map((place) => (
                          <button
                            type="button"
                            key={place.id}
                            className={activePlaceId === place.id ? "active" : ""}
                            onClick={() => setActivePlaceId(place.id)}
                          >
                            {place.name}
                            <span>{place.recipeCount}</span>
                          </button>
                        ))}
                      </div>
                    </div>
                  ) : null}

                  {groupedPlaces.islands.length ? (
                    <div>
                      <small>Îles</small>
                      <div className="country-place-chips">
                        {groupedPlaces.islands.map((place) => (
                          <button
                            type="button"
                            key={place.id}
                            className={activePlaceId === place.id ? "active" : ""}
                            onClick={() => setActivePlaceId(place.id)}
                          >
                            {place.name}
                            <span>{place.recipeCount}</span>
                          </button>
                        ))}
                      </div>
                    </div>
                  ) : null}
                </div>
              </section>
            ) : null}

            <div className="continent-modal-subheading">
              <div>
                <strong>{activePlace ? "Recettes de " + activePlace.name : "Recettes à découvrir"}</strong>
                <span>
                  {activePlace
                    ? activePlace.recipeCount + " recette" + (activePlace.recipeCount > 1 ? "s" : "") + " reliée" + (activePlace.recipeCount > 1 ? "s" : "") + " à cet endroit."
                    : "Les mieux placées apparaissent en premier."}
                </span>
              </div>
              <Link href={"/countries/" + countryCode}>Voir toutes →</Link>
            </div>

            {visibleRecipes.length ? (
              <div className="continent-modal-grid">
                {visibleRecipes.map((recipe) => (
                  <Link
                    href={"/recipes/" + recipe.id}
                    className="continent-modal-recipe"
                    key={recipe.id}
                    onClick={onClose}
                  >
                    <div className="continent-modal-recipe-image">
                      {recipe.image ? (
                        <Image
                          src={recipe.image}
                          alt={recipe.title}
                          fill
                          sizes="(max-width: 700px) 80vw, 260px"
                        />
                      ) : (
                        <OpenRecipeImage
                          title={recipe.originalTitle}
                          countryCode={countryCode}
                          className="modal-reference-image"
                          showCredit={false}
                        />
                      )}
                    </div>
                    <div className="continent-modal-recipe-body">
                      <small>{recipe.region || countryName}</small>
                      <h3>
                        <LocalizedRecipeTitle
                          originalTitle={recipe.originalTitle}
                          translations={recipe.titleTranslations}
                        />
                      </h3>
                      <p>
                        {recipe.category}
                        {recipe.minutes ? " · " + recipe.minutes + " min" : ""}
                        {" · " + difficultyLabel(recipe.difficulty)}
                      </p>
                      <div className="continent-modal-metrics">
                        <span>♥ {recipe.likes}</span>
                        <span>★ {recipe.rating ? recipe.rating.toFixed(1) : "—"}</span>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <div className="country-filter-empty">
                <span>🍽️</span>
                <strong>Pas encore de recette directement reliée à {activePlace?.name}.</strong>
                <button type="button" onClick={() => setActivePlaceId(null)}>
                  Voir toutes les recettes de {countryName}
                </button>
              </div>
            )}

            <div className="continent-modal-footer">
              <Link href={"/countries/" + countryCode} className="primary-button" onClick={onClose}>
                Voir toutes les recettes de {countryName}
              </Link>
              <button type="button" className="secondary-button" onClick={onClose}>
                Retour à l’accueil
              </button>
            </div>
          </>
        ) : null}
      </section>
    </div>
  );
}
