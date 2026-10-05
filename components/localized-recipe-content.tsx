"use client";

import { useMemo } from "react";
import { RecipeServingScaler } from "@/components/recipe-serving-scaler";
import type { LanguageCode } from "@/lib/preferences";
import { convertTemperatures } from "@/lib/units";
import { usePreferences } from "@/lib/use-preferences";

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
  fr: {
    preparation: "Préparation",
    prep: "Préparation",
    cook: "Cuisson",
    servings: "Portions",
    difficulty: { easy: "Facile", medium: "Intermédiaire", hard: "Difficile" },
    authenticity: { traditional: "Traditionnelle", adapted: "Adaptée", fusion: "Fusion" },
    original: "Texte d’origine en",
  },
  en: {
    preparation: "Method",
    prep: "Prep",
    cook: "Cook",
    servings: "Servings",
    difficulty: { easy: "Easy", medium: "Intermediate", hard: "Challenging" },
    authenticity: { traditional: "Traditional", adapted: "Adapted", fusion: "Fusion" },
    original: "Original text in",
  },
  es: {
    preparation: "Preparación",
    prep: "Preparación",
    cook: "Cocción",
    servings: "Porciones",
    difficulty: { easy: "Fácil", medium: "Intermedia", hard: "Difícil" },
    authenticity: { traditional: "Tradicional", adapted: "Adaptada", fusion: "Fusión" },
    original: "Texto original en",
  },
} as const;

const languageNames: Record<LanguageCode, Record<string, string>> = {
  fr: { fr: "français", en: "anglais", es: "espagnol" },
  en: { fr: "French", en: "English", es: "Spanish" },
  es: { fr: "francés", en: "inglés", es: "español" },
};

function translatedIngredients(value: unknown, fallback: BaseIngredient[]) {
  if (!Array.isArray(value)) return fallback;

  const parsed = value
    .map((item, index) => {
      if (!item || typeof item !== "object") return null;
      const row = item as TranslatedIngredient;
      if (!row.name?.trim()) return null;
      return {
        id: fallback[index]?.id ?? -(index + 1),
        position: fallback[index]?.position ?? index,
        name: row.name.trim(),
        quantity: row.quantity ?? fallback[index]?.quantity ?? null,
        // L'unité est traduite et convertie plus loin, dans le module d'unités.
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
        return { id: fallback[index]?.id ?? -(index + 1), position: index, instruction: item };
      }
      if (!item || typeof item !== "object") return null;
      const row = item as TranslatedStep;
      if (!row.instruction?.trim()) return null;
      return {
        id: fallback[index]?.id ?? -(index + 1),
        position: index,
        instruction: row.instruction.trim(),
      };
    })
    .filter((item): item is NonNullable<typeof item> => Boolean(item));

  return parsed.length ? parsed : fallback;
}

export function LocalizedRecipeContent({
  sourceLanguage = "fr",
  baseDescription,
  baseServings,
  baseIngredients,
  baseSteps,
  translations,
  prepMinutes,
  cookMinutes,
  difficulty,
  authenticity,
}: {
  sourceLanguage?: string | null;
  baseDescription: string | null;
  baseServings: number | string | null;
  baseIngredients: BaseIngredient[];
  baseSteps: BaseStep[];
  translations?: TranslationRow[] | null;
  prepMinutes?: number | null;
  cookMinutes?: number | null;
  difficulty?: string | null;
  authenticity?: string | null;
}) {
  const [preferences, updatePreferences] = usePreferences();
  const language = preferences.language;
  const source = (sourceLanguage || "fr") as LanguageCode;

  const localized = useMemo(() => {
    const base = { description: baseDescription, ingredients: baseIngredients, steps: baseSteps, fromSource: true };
    // La recette est déjà dans la langue choisie : on affiche le texte d'origine.
    if (language === source) return base;

    const translation = translations?.find((item) => item.language_code === language);
    if (!translation) return base;

    return {
      description: translation.description?.trim() || baseDescription,
      ingredients: translatedIngredients(translation.ingredients, baseIngredients),
      steps: translatedSteps(translation.steps, baseSteps),
      fromSource: false,
    };
  }, [baseDescription, baseIngredients, baseSteps, language, source, translations]);

  const text = labels[language] ?? labels.fr;
  const difficultyLabel = difficulty ? text.difficulty[difficulty as keyof typeof text.difficulty] : null;
  const authenticityLabel = authenticity ? text.authenticity[authenticity as keyof typeof text.authenticity] : null;
  const showsOtherLanguage = localized.fromSource && source !== language;

  return (
    <>
      <div className="recipe-detail-meta">
        <span>{text.prep} : {prepMinutes ?? "—"} min</span>
        <span>{text.cook} : {cookMinutes ?? "—"} min</span>
        <span>{text.servings} : {baseServings ?? "—"}</span>
        {difficultyLabel ? <span>{difficultyLabel}</span> : null}
        {authenticityLabel ? <span>{authenticityLabel}</span> : null}
      </div>

      {showsOtherLanguage ? (
        <p className="recipe-language-note">
          {text.original} {languageNames[language][source] ?? source}.
        </p>
      ) : null}

      {localized.description ? <p className="recipe-lead">{localized.description}</p> : null}

      <div className="recipe-columns">
        <RecipeServingScaler
          baseServings={baseServings}
          ingredients={localized.ingredients}
          language={language}
          measurements={preferences.measurements}
          temperature={preferences.temperature}
          onMeasurementsChange={(measurements) => updatePreferences({ measurements })}
          onTemperatureChange={(temperature) => updatePreferences({ temperature })}
        />
        <section>
          <h2>{text.preparation}</h2>
          <ol className="step-list">
            {localized.steps.map((step) => (
              <li key={step.id}>{convertTemperatures(step.instruction, preferences.temperature)}</li>
            ))}
          </ol>
        </section>
      </div>
    </>
  );
}
