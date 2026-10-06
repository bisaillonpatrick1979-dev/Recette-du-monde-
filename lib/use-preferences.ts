"use client";

// Lecture et mise à jour des préférences (langue, mesures, température) stockées dans le navigateur.
// Tous les composants qui utilisent ce hook se mettent à jour ensemble quand une préférence change.
// Si le stockage est bloqué (navigation privée stricte, cookies refusés), les préférences restent
// en mémoire pour la page en cours au lieu de revenir aux valeurs par défaut.

import { useCallback, useEffect, useState } from "react";
import { defaultPreferences, PREFERENCES_STORAGE_KEY, type UserPreferences } from "@/lib/preferences";

const CHANGE_EVENT = "spoontrotter:preferences";

// Valeur gardée en mémoire seulement quand l'écriture dans le stockage a échoué,
// partagée par tous les composants de la page.
let memoryPreferences: UserPreferences | null = null;

export function readPreferences(): UserPreferences {
  // Le stockage a refusé la dernière écriture : la valeur en mémoire fait foi.
  if (memoryPreferences) return memoryPreferences;
  try {
    const saved = window.localStorage.getItem(PREFERENCES_STORAGE_KEY);
    if (!saved) return defaultPreferences;
    return { ...defaultPreferences, ...(JSON.parse(saved) as Partial<UserPreferences>) };
  } catch {
    // Stockage illisible : valeurs par défaut.
    return defaultPreferences;
  }
}

// Vrai si la personne a déjà choisi ses préférences (onboarding fait), même si le stockage est bloqué.
export function hasSavedPreferences(): boolean {
  if (memoryPreferences) return true;
  try {
    return Boolean(window.localStorage.getItem(PREFERENCES_STORAGE_KEY));
  } catch {
    return false;
  }
}

// Enregistre les préférences (stockage du navigateur, sinon mémoire) et prévient les composants.
export function savePreferences(next: UserPreferences) {
  try {
    window.localStorage.setItem(PREFERENCES_STORAGE_KEY, JSON.stringify(next));
    memoryPreferences = null;
  } catch {
    // Stockage indisponible : la valeur reste en mémoire pour cette visite.
    memoryPreferences = next;
  }
  window.dispatchEvent(new CustomEvent<UserPreferences>(CHANGE_EVENT, { detail: next }));
}

export function usePreferences() {
  const [preferences, setPreferences] = useState<UserPreferences>(defaultPreferences);

  useEffect(() => {
    setPreferences(readPreferences());
    // L'événement interne transporte la nouvelle valeur : pas besoin de relire le stockage.
    const onChange = (event: Event) => {
      const detail = (event as CustomEvent<UserPreferences>).detail;
      setPreferences(detail ?? readPreferences());
    };
    const onStorage = (event: StorageEvent) => {
      // Changement fait dans un autre onglet : le stockage redevient la référence.
      if (event.key !== null && event.key !== PREFERENCES_STORAGE_KEY) return;
      memoryPreferences = null;
      setPreferences(readPreferences());
    };
    window.addEventListener(CHANGE_EVENT, onChange);
    window.addEventListener("storage", onStorage);
    return () => {
      window.removeEventListener(CHANGE_EVENT, onChange);
      window.removeEventListener("storage", onStorage);
    };
  }, []);

  const update = useCallback((patch: Partial<UserPreferences>) => {
    const next = { ...readPreferences(), ...patch };
    setPreferences(next);
    savePreferences(next);
  }, []);

  return [preferences, update] as const;
}
