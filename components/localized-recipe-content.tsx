"use client";

import { useEffect, useMemo, useState } from "react";
import { RecipeServingScaler } from "@/components/recipe-serving-scaler";
import {
  defaultPreferences,
  PREFERENCES_STORAGE_KEY,
  type LanguageCode,
  type UserPreferences,
} from "@/lib/preferences";

type BaseIngredient = {
  id: number;
  position: number;
  name: string;
  quantity: number | string | null;
  unit: string | null;
  note: string | null;
};

type BaseStep = {
  id: number;
  position: number;
  instruction: string;
};

type TranslationRow = {
  language_code: string;
  title?: string | null;
  description?: string | null;
  ingredients: unknown;
  steps: unknown;
};

type TranslatedIngredient = {
  position?: number;
  name?: string;
  quantity?: number | string | null;
  unit?: string | null;
  note?: string | null;
};

type TranslatedStep = {
  position?: number;
  instruction?: string;
};

const labels = {
  fr: { preparation: "Préparation" },
  en: { preparation: "Preparation" },
  es: { preparation: "Preparación" },
} satisfies Record<LanguageCode, { preparation: string }>;

function translatedIngredients(value: unknown, fallback: BaseIngredient[]) {
  if (!Array.isArray(value)) return fallback;

  const parsed = value
    .map((item, index) => {
      if (!item || typeof item !== "object") return null;
      const row = item as TranslatedIngredient;
      if (!row.name?.trim()) return null;
      return {
        id: fallback[index]?.id ?? -(index + 1),
        name: row.name.trim(),
        quantity: row.quantity ?? fallback[index]?.quantity ?? null,
        unit: row.unit ?? fallback[index]?.unit ?? null,
        note: row.note ?? null,
      };
    })
    .filter((item): item is NonNullable<typeof item> => Boolean(item));

  return parsed.length ? parsed : fallback;
}

function translatedSteps(value: unknown, fallback: BaseStep[]) {
  if (!Array.isArray(value)) return fallback;

  const parsed = value
    .map((item, index) => {
      if (typeof item === "string") {
        return { id: fallback[index]?.id ?? -(index + 1), instruction: item };
      }
      if (!item || typeof item !== "object") return null;
      const row = item as TranslatedStep;
      if (!row.instruction?.trim()) return null;
      return {
        id: fallback[index]?.id ?? -(index + 1),
        instruction: row.instruction.trim(),
      };
    })
    .filter((item): item is NonNullable<typeof item> => Boolean(item));

  return parsed.length ? parsed : fallback;
}

export function LocalizedRecipeContent({
  baseDescription,
  baseServings,
  baseIngredients,
  baseSteps,
  translations,
}: {
  baseDescription: string | null;
  baseServings: number | string | null;
  baseIngredients: BaseIngredient[];
  baseSteps: BaseStep[];
  translations?: TranslationRow[] | null;
}) {
  const [language, setLanguage] = useState<LanguageCode>(defaultPreferences.language);

  useEffect(() => {
    const saved = window.localStorage.getItem(PREFERENCES_STORAGE_KEY);
    if (!saved) return;
    try {
      const parsed = JSON.parse(saved) as UserPreferences;
      setLanguage(parsed.language ?? defaultPreferences.language);
    } catch {
      setLanguage(defaultPreferences.language);
    }
  }, []);

  const localized = useMemo(() => {
    if (language === "fr") {
      return {
        description: baseDescription,
        ingredients: baseIngredients,
        steps: baseSteps,
      };
    }

    const translation = translations?.find((item) => item.language_code === language);
    if (!translation) {
      return {
        description: baseDescription,
        ingredients: baseIngredients,
        steps: baseSteps,
      };
    }

    return {
      description: translation.description?.trim() || baseDescription,
      ingredients: translatedIngredients(translation.ingredients, baseIngredients),
      steps: translatedSteps(translation.steps, baseSteps),
    };
  }, [baseDescription, baseIngredients, baseSteps, language, translations]);

  const text = labels[language] ?? labels.fr;

  return (
    <>
      {localized.description ? <p className="recipe-lead">{localized.description}</p> : null}

      <div className="recipe-columns">
        <RecipeServingScaler
          baseServings={baseServings}
          ingredients={localized.ingredients}
          language={language}
        />
        <section>
          <h2>{text.preparation}</h2>
          <ol className="step-list">
            {localized.steps.map((step) => (
              <li key={step.id}>{step.instruction}</li>
            ))}
          </ol>
        </section>
      </div>
    </>
  );
}
