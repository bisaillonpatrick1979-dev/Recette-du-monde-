"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import type { ContinentKey } from "@/lib/continents";
import { LocalizedRecipeTitle } from "@/components/localized-recipe-title";
import { OpenRecipeImage } from "@/components/open-recipe-image";

type PreviewRecipe = {
  id: string;
  title: string;
  originalTitle: string;
  titleTranslations: Array<{ language_code: string; title: string }>;
  country: string;
  countryCode: string | null;
  region: string | null;
  category: string;
  difficulty: "easy" | "medium" | "hard" | null;
  minutes: number | null;
  image: string | null;
  likes: number;
  rating: number | null;
  ratingCount: number;
};

type PreviewPayload = {
  key: ContinentKey;
  label: string;
  total: number;
  recipes: PreviewRecipe[];
};

function flagFor(code: string | null) {
  if (!code || code.length !== 2) return "🌍";
  return code
    .toUpperCase()
    .replace(/[A-Z]/g, (letter) =>
      String.fromCodePoint(127397 + letter.charCodeAt(0)),
    );
}

function difficultyLabel(value: PreviewRecipe["difficulty"]) {
  if (value === "hard") return "Difficile";
  if (value === "medium") return "Moyen";
  return "Facile";
}

export function ContinentRecipesModal({
  continentKey,
  continentLabel,
  onClose,
}: {
  continentKey: ContinentKey;
  continentLabel: string;
  onClose: () => void;
}) {
  const [data, setData] = useState<PreviewPayload | null>(null);
  const [state, setState] = useState<"loading" | "ready" | "error">("loading");

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

    fetch("/api/continents/" + continentKey + "/recipes")
      .then(async (response) => {
        if (!response.ok) throw new Error("Unable to load continent recipes");
        return (await response.json()) as PreviewPayload;
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
  }, [continentKey]);

  return (
    <div className="continent-modal-backdrop" role="presentation" onMouseDown={onClose}>
      <section
        className="continent-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="continent-modal-title"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <header className="continent-modal-header">
          <div>
            <span className="planet-eyebrow">Explorer par continent</span>
            <h2 id="continent-modal-title">{continentLabel}</h2>
            <p>
              {data
                ? data.total.toLocaleString("fr-CA") + " recettes officielles dans cette région"
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
            <strong>Je rassemble les recettes de {continentLabel}…</strong>
          </div>
        ) : null}

        {state === "error" ? (
          <div className="continent-modal-empty">
            <span>🍽️</span>
            <h3>Impossible de charger les recettes pour le moment.</h3>
            <button type="button" onClick={onClose}>Fermer</button>
          </div>
        ) : null}

        {state === "ready" && data ? (
          <>
            <div className="continent-modal-subheading">
              <div>
                <strong>À découvrir en premier</strong>
                <span>Triées selon les J’aime, les notes et les nouveautés.</span>
              </div>
              <Link href={"/continents/" + continentKey}>Voir toutes →</Link>
            </div>

            {data.recipes.length ? (
              <div className="continent-modal-grid">
                {data.recipes.map((recipe) => (
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
                          countryCode={recipe.countryCode}
                          className="modal-reference-image"
                          showCredit={false}
                        />
                      )}
                    </div>
                    <div className="continent-modal-recipe-body">
                      <small>{flagFor(recipe.countryCode)} {recipe.country}</small>
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
              <div className="continent-modal-empty">
                <span>🍽️</span>
                <h3>Aucune recette publiée pour cette région pour le moment.</h3>
              </div>
            )}

            <div className="continent-modal-footer">
              <Link href={"/continents/" + continentKey} className="primary-button" onClick={onClose}>
                Voir toutes les recettes de {continentLabel}
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
