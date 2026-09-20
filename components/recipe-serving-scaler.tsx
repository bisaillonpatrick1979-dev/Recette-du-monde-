"use client";

import { useMemo, useState } from "react";
import type { LanguageCode } from "@/lib/preferences";

type Ingredient = {
  id: number;
  name: string;
  quantity: number | string | null;
  unit: string | null;
  note: string | null;
};

const QUICK_SERVINGS = [2, 4, 6, 8, 12, 24];

function numericQuantity(value: number | string | null) {
  if (value == null || value === "") return null;
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function formatQuantity(value: number, locale: string) {
  const rounded = Math.round(value * 100) / 100;
  const whole = Math.floor(rounded);
  const fraction = Math.round((rounded - whole) * 100) / 100;

  const commonFractions: Array<[number, string]> = [
    [0.125, "⅛"],
    [0.25, "¼"],
    [0.333, "⅓"],
    [0.375, "⅜"],
    [0.5, "½"],
    [0.625, "⅝"],
    [0.667, "⅔"],
    [0.75, "¾"],
    [0.875, "⅞"],
  ];

  const match = commonFractions.find(([candidate]) => Math.abs(fraction - candidate) < 0.025);

  if (match) {
    return whole > 0 ? `${whole} ${match[1]}` : match[1];
  }

  if (Math.abs(rounded - Math.round(rounded)) < 0.001) {
    return String(Math.round(rounded));
  }

  return new Intl.NumberFormat(locale, {
    maximumFractionDigits: 2,
  }).format(rounded);
}

const labels = {
  fr: {
    eyebrow: "Quantités adaptatives",
    ingredients: "Ingrédients",
    servings: "Nombre de portions",
    remove: "Retirer une portion",
    add: "Ajouter une portion",
    one: "personne",
    many: "personnes",
    quick: "Choix rapides de portions",
    original: "Recette originale pour",
    recalculated: "Les quantités sont recalculées automatiquement pour",
    locale: "fr-CA",
  },
  en: {
    eyebrow: "Adaptive quantities",
    ingredients: "Ingredients",
    servings: "Number of servings",
    remove: "Remove one serving",
    add: "Add one serving",
    one: "person",
    many: "people",
    quick: "Quick serving choices",
    original: "Original recipe for",
    recalculated: "Quantities are automatically recalculated for",
    locale: "en-CA",
  },
  es: {
    eyebrow: "Cantidades adaptables",
    ingredients: "Ingredientes",
    servings: "Número de porciones",
    remove: "Quitar una porción",
    add: "Añadir una porción",
    one: "persona",
    many: "personas",
    quick: "Selección rápida de porciones",
    original: "Receta original para",
    recalculated: "Las cantidades se recalculan automáticamente para",
    locale: "es",
  },
} satisfies Record<LanguageCode, {
  eyebrow: string;
  ingredients: string;
  servings: string;
  remove: string;
  add: string;
  one: string;
  many: string;
  quick: string;
  original: string;
  recalculated: string;
  locale: string;
}>;

export function RecipeServingScaler({
  baseServings,
  ingredients,
  language = "fr",
}: {
  baseServings: number | string | null;
  ingredients: Ingredient[];
  language?: LanguageCode;
}) {
  const normalizedBase = Math.max(1, Math.round(numericQuantity(baseServings) ?? 4));
  const [servings, setServings] = useState(normalizedBase);
  const text = labels[language] ?? labels.fr;

  const scaledIngredients = useMemo(() => {
    const ratio = servings / normalizedBase;
    return ingredients.map((ingredient) => {
      const baseQuantity = numericQuantity(ingredient.quantity);
      return {
        ...ingredient,
        displayQuantity: baseQuantity == null ? null : formatQuantity(baseQuantity * ratio, text.locale),
      };
    });
  }, [ingredients, normalizedBase, servings, text.locale]);

  function updateServings(value: number) {
    setServings(Math.min(48, Math.max(1, Math.round(value))));
  }

  return (
    <section className="serving-scaler" aria-labelledby="serving-scaler-title">
      <div className="serving-scaler-heading">
        <div>
          <span className="eyebrow">{text.eyebrow}</span>
          <h2 id="serving-scaler-title">{text.ingredients}</h2>
        </div>

        <div className="serving-stepper" aria-label={text.servings}>
          <button
            type="button"
            onClick={() => updateServings(servings - 1)}
            aria-label={text.remove}
          >
            −
          </button>
          <div>
            <strong>{servings}</strong>
            <span>{servings > 1 ? text.many : text.one}</span>
          </div>
          <button
            type="button"
            onClick={() => updateServings(servings + 1)}
            aria-label={text.add}
          >
            +
          </button>
        </div>
      </div>

      <div className="serving-quick-picks" aria-label={text.quick}>
        {QUICK_SERVINGS.map((value) => (
          <button
            type="button"
            key={value}
            className={servings === value ? "active" : ""}
            onClick={() => updateServings(value)}
          >
            {value}
          </button>
        ))}
      </div>

      {servings !== normalizedBase ? (
        <p className="serving-scale-note">
          {text.original} {normalizedBase} {normalizedBase > 1 ? text.many : text.one}.
          {text.recalculated} {servings}.
        </p>
      ) : null}

      <ul className="ingredient-list scaled-ingredient-list">
        {scaledIngredients.map((item) => (
          <li key={item.id}>
            <strong>
              {item.displayQuantity ? `${item.displayQuantity} ${item.unit ?? ""}`.trim() : item.unit ?? ""}
            </strong>
            <span>{item.name}</span>
            {item.note ? <small>{item.note}</small> : null}
          </li>
        ))}
      </ul>
    </section>
  );
}
