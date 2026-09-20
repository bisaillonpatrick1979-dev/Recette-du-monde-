"use client";

import { useEffect, useMemo, useState } from "react";
import {
  defaultPreferences,
  PREFERENCES_STORAGE_KEY,
  type LanguageCode,
  type UserPreferences,
} from "@/lib/preferences";

type TranslationMap = Partial<Record<LanguageCode, string>>;

export function LocalizedRecipeTitle({
  originalTitle,
  translations,
  className = "",
}: {
  originalTitle: string;
  translations?: TranslationMap | null;
  className?: string;
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

  const translatedTitle = useMemo(() => {
    const value = translations?.[language]?.trim();
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
