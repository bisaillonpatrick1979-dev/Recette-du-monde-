"use client";

import { FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  defaultPreferences,
  LanguageCode,
  MeasurementSystem,
  PREFERENCES_STORAGE_KEY,
  UserPreferences,
} from "@/lib/preferences";

const countries = [
  { value: "CA", label: "Canada", currency: "CAD", language: "fr", temp: "c" },
  { value: "US", label: "États-Unis / United States", currency: "USD", language: "en", temp: "f" },
  { value: "FR", label: "France", currency: "EUR", language: "fr", temp: "c" },
  { value: "ES", label: "Espagne / España", currency: "EUR", language: "es", temp: "c" },
  { value: "MX", label: "Mexique / México", currency: "USD", language: "es", temp: "c" },
  { value: "GB", label: "Royaume-Uni / United Kingdom", currency: "EUR", language: "en", temp: "c" },
] as const;

const languageLabels: Record<LanguageCode, string> = {
  fr: "Français",
  en: "English",
  es: "Español",
};

const measureLabels: Record<MeasurementSystem, string> = {
  metric: "Métrique · g, kg, ml, L",
  imperial: "Impérial · oz, lb, fl oz",
  cups: "Cuisine · tasses, c. à soupe, c. à thé",
};

export function OnboardingWizard() {
  const router = useRouter();
  const [preferences, setPreferences] = useState<UserPreferences>(defaultPreferences);

  const selectedCountry = useMemo(
    () => countries.find((country) => country.value === preferences.country),
    [preferences.country],
  );

  function update<K extends keyof UserPreferences>(key: K, value: UserPreferences[K]) {
    setPreferences((current) => ({ ...current, [key]: value }));
  }

  function chooseCountry(countryCode: string) {
    const country = countries.find((item) => item.value === countryCode);
    if (!country) return;

    setPreferences((current) => ({
      ...current,
      country: country.value,
      currency: country.currency as UserPreferences["currency"],
      language: country.language as LanguageCode,
      temperature: country.temp as UserPreferences["temperature"],
      measurements: country.value === "US" ? "imperial" : "metric",
    }));
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    window.localStorage.setItem(PREFERENCES_STORAGE_KEY, JSON.stringify(preferences));
    router.replace("/");
  }

  return (
    <form className="onboarding-card" onSubmit={submit}>
      <div className="onboarding-heading">
        <span className="step-pill">Configuration initiale</span>
        <h2>Adaptons l’application à votre cuisine</h2>
        <p>
          Vous pourrez modifier ces choix en tout temps. Les recettes, unités, températures
          et traductions utiliseront ces préférences.
        </p>
      </div>

      <div className="form-grid">
        <label>
          <span>Pays</span>
          <select value={preferences.country} onChange={(event) => chooseCountry(event.target.value)}>
            {countries.map((country) => (
              <option value={country.value} key={country.value}>
                {country.label}
              </option>
            ))}
          </select>
        </label>

        <label>
          <span>Langue de l’application</span>
          <select
            value={preferences.language}
            onChange={(event) => update("language", event.target.value as LanguageCode)}
          >
            {Object.entries(languageLabels).map(([value, label]) => (
              <option value={value} key={value}>
                {label}
              </option>
            ))}
          </select>
        </label>

        <label>
          <span>Mesures préférées</span>
          <select
            value={preferences.measurements}
            onChange={(event) => update("measurements", event.target.value as MeasurementSystem)}
          >
            {Object.entries(measureLabels).map(([value, label]) => (
              <option value={value} key={value}>
                {label}
              </option>
            ))}
          </select>
        </label>

        <label>
          <span>Température</span>
          <div className="segmented">
            <button
              type="button"
              className={preferences.temperature === "c" ? "active" : ""}
              onClick={() => update("temperature", "c")}
            >
              °C
            </button>
            <button
              type="button"
              className={preferences.temperature === "f" ? "active" : ""}
              onClick={() => update("temperature", "f")}
            >
              °F
            </button>
          </div>
        </label>

        <label>
          <span>Devise</span>
          <select
            value={preferences.currency}
            onChange={(event) =>
              update("currency", event.target.value as UserPreferences["currency"])
            }
          >
            <option value="CAD">$ CAD</option>
            <option value="USD">$ USD</option>
            <option value="EUR">€ EUR</option>
          </select>
        </label>
      </div>

      <div className="preference-preview">
        <strong>{selectedCountry?.label}</strong>
        <span>{languageLabels[preferences.language]}</span>
        <span>{measureLabels[preferences.measurements]}</span>
        <span>{preferences.temperature === "c" ? "Celsius" : "Fahrenheit"}</span>
        <span>{preferences.currency}</span>
      </div>

      <button className="primary-button" type="submit">
        Commencer à cuisiner
      </button>

      <p className="privacy-note">
        Ces préférences sont enregistrées localement pour cette première version. La synchronisation
        sécurisée avec le compte utilisateur viendra avec Supabase Auth.
      </p>
    </form>
  );
}
