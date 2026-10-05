"use client";

// Lecture et mise à jour des préférences (langue, mesures, température) stockées dans le navigateur.
// Tous les composants qui utilisent ce hook se mettent à jour ensemble quand une préférence change.

import { useCallback, useEffect, useState } from "react";
import { defaultPreferences, PREFERENCES_STORAGE_KEY, type UserPreferences } from "@/lib/preferences";

const CHANGE_EVENT = "spoontrotter:preferences";

export function readPreferences(): UserPreferences {
  try {
    const saved = window.localStorage.getItem(PREFERENCES_STORAGE_KEY);
    if (!saved) return defaultPreferences;
    return { ...defaultPreferences, ...(JSON.parse(saved) as Partial<UserPreferences>) };
  } catch {
    // Navigation privée ou stockage bloqué : on garde les valeurs par défaut.
    return defaultPreferences;
  }
}

export function usePreferences() {
  const [preferences, setPreferences] = useState<UserPreferences>(defaultPreferences);

  useEffect(() => {
    setPreferences(readPreferences());
    const sync = () => setPreferences(readPreferences());
    window.addEventListener(CHANGE_EVENT, sync);
    window.addEventListener("storage", sync);
    return () => {
      window.removeEventListener(CHANGE_EVENT, sync);
      window.removeEventListener("storage", sync);
    };
  }, []);

  const update = useCallback((patch: Partial<UserPreferences>) => {
    const next = { ...readPreferences(), ...patch };
    try {
      window.localStorage.setItem(PREFERENCES_STORAGE_KEY, JSON.stringify(next));
    } catch {
      // Stockage indisponible : le changement vaut seulement pour cette page.
    }
    setPreferences(next);
    window.dispatchEvent(new Event(CHANGE_EVENT));
  }, []);

  return [preferences, update] as const;
}
