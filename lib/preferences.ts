export const PREFERENCES_STORAGE_KEY = "cuisine-du-monde:preferences:v1";

export type LanguageCode = "fr" | "en" | "es";
export type MeasurementSystem = "metric" | "imperial" | "cups";

export type UserPreferences = {
  country: string;
  language: LanguageCode;
  measurements: MeasurementSystem;
  temperature: "c" | "f";
  currency: "CAD" | "USD" | "EUR";
};

export const defaultPreferences: UserPreferences = {
  country: "CA",
  language: "fr",
  measurements: "metric",
  temperature: "c",
  currency: "CAD",
};
