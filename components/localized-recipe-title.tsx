"use client";

import { useMemo } from "react";
import type { LanguageCode } from "@/lib/preferences";
import { usePreferences } from "@/lib/use-preferences";

type TranslationMap = Partial<Record<LanguageCode, string>>;
type TranslationRow = { language_code: string; title: string };

export function LocalizedRecipeTitle({
  originalTitle,
  translations,
  className = "",
}: {
  originalTitle: string;
  translations?: TranslationMap | TranslationRow[] | null;
  className?: string;
}) {
  // Langue choisie à l'onboarding (lecture protégée, mise à jour en direct si elle change).
  const [preferences] = usePreferences();
  const language = preferences.language;

  const translatedTitle = useMemo(() => {
    const value = Array.isArray(translations)
      ? translations.find((item) => item.language_code === language)?.title?.trim()
      : translations?.[language]?.trim();
    if (!value) return null;
    if (value.localeCompare(originalTitle, undefined, { sensitivity: "accent" }) === 0) return null;
    return value;
  }, [language, originalTitle, translations]);

  return (
    <span className={`localized-recipe-title ${className}`.trim()}>
      <span className="localized-recipe-title-main">{originalTitle}</span>
      {translatedTitle ? (
        <small className="localized-recipe-title-translation">({translatedTitle})</small>
      ) : null}
    </span>
  );
}
