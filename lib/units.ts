// Conversion des unités et des températures selon les préférences de l'utilisateur.
//
// Les recettes sont stockées dans leur unité d'origine (g, ml, c. à soupe, cups, lb…).
// À l'affichage, on ramène chaque quantité à une unité canonique, on la convertit vers
// le système choisi (métrique, impérial ou tasses), puis on traduit le libellé de l'unité.
// Les unités qu'on ne peut pas convertir (gousses, pincée, bouquet…) sont seulement traduites.

import type { LanguageCode, MeasurementSystem } from "@/lib/preferences";

export type TemperatureUnit = "c" | "f";

type Canonical = "g" | "kg" | "ml" | "l" | "tsp" | "tbsp" | "cup" | "oz" | "lb" | "floz";

// Valeur de chaque unité canonique dans son unité de base (g pour la masse, ml pour le volume).
const MASS: Partial<Record<Canonical, number>> = { g: 1, kg: 1000, oz: 28.3495, lb: 453.592 };
const VOLUME: Partial<Record<Canonical, number>> = {
  ml: 1,
  l: 1000,
  tsp: 4.92892,
  tbsp: 14.7868,
  // Tasse métrique canadienne (250 ml) : 1 tasse = 250 ml, comme dans les recettes du Canada.
  cup: 250,
  floz: 29.5735,
};

// Toutes les façons d'écrire une unité dans les recettes (FR, EN, ES), en minuscules.
const ALIASES: Record<string, Canonical> = {
  g: "g", gr: "g", gramme: "g", grammes: "g", gram: "g", grams: "g", gramo: "g", gramos: "g",
  kg: "kg", kilo: "kg", kilos: "kg", kilogramme: "kg", kilogrammes: "kg", kilogram: "kg", kilograms: "kg",
  ml: "ml", millilitre: "ml", millilitres: "ml", milliliter: "ml", milliliters: "ml", mililitro: "ml", mililitros: "ml",
  l: "l", litre: "l", litres: "l", liter: "l", liters: "l", litro: "l", litros: "l",
  tsp: "tsp", "c. à thé": "tsp", "c. à café": "tsp", "cuillère à thé": "tsp", "cuillères à thé": "tsp",
  "cuillère à café": "tsp", "cuillères à café": "tsp", teaspoon: "tsp", teaspoons: "tsp", cdta: "tsp", cucharadita: "tsp", cucharaditas: "tsp",
  tbsp: "tbsp", "c. à soupe": "tbsp", "cuillère à soupe": "tbsp", "cuillères à soupe": "tbsp",
  tablespoon: "tbsp", tablespoons: "tbsp", cda: "tbsp", cucharada: "tbsp", cucharadas: "tbsp",
  cup: "cup", cups: "cup", tasse: "cup", tasses: "cup", taza: "cup", tazas: "cup",
  oz: "oz", ounce: "oz", ounces: "oz", once: "oz", onces: "oz", onza: "oz", onzas: "oz",
  lb: "lb", lbs: "lb", pound: "lb", pounds: "lb", livre: "lb", livres: "lb", libra: "lb", libras: "lb",
  "fl oz": "floz", "fl. oz": "floz", "fluid ounce": "floz", "fluid ounces": "floz", "oz liq.": "floz",
};

// Libellés affichés des unités canoniques : [singulier, pluriel].
const CANONICAL_LABELS: Record<LanguageCode, Record<Canonical, [string, string]>> = {
  fr: {
    g: ["g", "g"], kg: ["kg", "kg"], ml: ["ml", "ml"], l: ["L", "L"],
    tsp: ["c. à thé", "c. à thé"], tbsp: ["c. à soupe", "c. à soupe"], cup: ["tasse", "tasses"],
    oz: ["oz", "oz"], lb: ["lb", "lb"], floz: ["oz liq.", "oz liq."],
  },
  en: {
    g: ["g", "g"], kg: ["kg", "kg"], ml: ["ml", "ml"], l: ["L", "L"],
    tsp: ["tsp", "tsp"], tbsp: ["tbsp", "tbsp"], cup: ["cup", "cups"],
    oz: ["oz", "oz"], lb: ["lb", "lb"], floz: ["fl oz", "fl oz"],
  },
  es: {
    g: ["g", "g"], kg: ["kg", "kg"], ml: ["ml", "ml"], l: ["L", "L"],
    tsp: ["cdta", "cdtas"], tbsp: ["cda", "cdas"], cup: ["taza", "tazas"],
    oz: ["oz", "oz"], lb: ["lb", "lb"], floz: ["oz líq.", "oz líq."],
  },
};

// Unités non convertibles : traduction simple vers chaque langue (clé en minuscules).
const COUNT_UNITS: Record<string, Record<LanguageCode, string>> = {
  "unité": { fr: "unité", en: "unit", es: "unidad" },
  "unités": { fr: "unités", en: "units", es: "unidades" },
  unit: { fr: "unité", en: "unit", es: "unidad" },
  units: { fr: "unités", en: "units", es: "unidades" },
  gousse: { fr: "gousse", en: "clove", es: "diente" },
  gousses: { fr: "gousses", en: "cloves", es: "dientes" },
  clove: { fr: "gousse", en: "clove", es: "diente" },
  cloves: { fr: "gousses", en: "cloves", es: "dientes" },
  tranche: { fr: "tranche", en: "slice", es: "rebanada" },
  tranches: { fr: "tranches", en: "slices", es: "rebanadas" },
  slice: { fr: "tranche", en: "slice", es: "rebanada" },
  slices: { fr: "tranches", en: "slices", es: "rebanadas" },
  "bâton": { fr: "bâton", en: "stick", es: "rama" },
  "bâtons": { fr: "bâtons", en: "sticks", es: "ramas" },
  stick: { fr: "bâton", en: "stick", es: "barra" },
  sticks: { fr: "bâtons", en: "sticks", es: "barras" },
  branche: { fr: "branche", en: "stalk", es: "tallo" },
  branches: { fr: "branches", en: "stalks", es: "tallos" },
  tige: { fr: "tige", en: "stem", es: "tallo" },
  tiges: { fr: "tiges", en: "stems", es: "tallos" },
  brin: { fr: "brin", en: "sprig", es: "ramita" },
  brins: { fr: "brins", en: "sprigs", es: "ramitas" },
  "pincée": { fr: "pincée", en: "pinch", es: "pizca" },
  "pincées": { fr: "pincées", en: "pinches", es: "pizcas" },
  pinch: { fr: "pincée", en: "pinch", es: "pizca" },
  bouquet: { fr: "bouquet", en: "bunch", es: "manojo" },
  bouquets: { fr: "bouquets", en: "bunches", es: "manojos" },
  "gros bouquet": { fr: "gros bouquet", en: "large bunch", es: "manojo grande" },
  botte: { fr: "botte", en: "bunch", es: "manojo" },
  bottes: { fr: "bottes", en: "bunches", es: "manojos" },
  bunch: { fr: "bouquet", en: "bunch", es: "manojo" },
  "poignée": { fr: "poignée", en: "handful", es: "puñado" },
  "poignées": { fr: "poignées", en: "handfuls", es: "puñados" },
  handful: { fr: "poignée", en: "handful", es: "puñado" },
  feuille: { fr: "feuille", en: "leaf", es: "hoja" },
  feuilles: { fr: "feuilles", en: "leaves", es: "hojas" },
  leaf: { fr: "feuille", en: "leaf", es: "hoja" },
  leaves: { fr: "feuilles", en: "leaves", es: "hojas" },
  portion: { fr: "portion", en: "portion", es: "porción" },
  portions: { fr: "portions", en: "portions", es: "porciones" },
  morceau: { fr: "morceau", en: "piece", es: "trozo" },
  morceaux: { fr: "morceaux", en: "pieces", es: "trozos" },
  piece: { fr: "morceau", en: "piece", es: "trozo" },
  pieces: { fr: "morceaux", en: "pieces", es: "trozos" },
  "boîte": { fr: "boîte", en: "can", es: "lata" },
  "boîtes": { fr: "boîtes", en: "cans", es: "latas" },
  can: { fr: "boîte", en: "can", es: "lata" },
  cans: { fr: "boîtes", en: "cans", es: "latas" },
  sachet: { fr: "sachet", en: "packet", es: "sobre" },
  sachets: { fr: "sachets", en: "packets", es: "sobres" },
  packet: { fr: "sachet", en: "packet", es: "sobre" },
  package: { fr: "paquet", en: "package", es: "paquete" },
  "tête": { fr: "tête", en: "head", es: "cabeza" },
  "têtes": { fr: "têtes", en: "heads", es: "cabezas" },
  head: { fr: "tête", en: "head", es: "cabeza" },
  "épi": { fr: "épi", en: "ear", es: "mazorca" },
  "épis": { fr: "épis", en: "ears", es: "mazorcas" },
  goutte: { fr: "goutte", en: "drop", es: "gota" },
  gouttes: { fr: "gouttes", en: "drops", es: "gotas" },
  dash: { fr: "trait", en: "dash", es: "chorrito" },
  trait: { fr: "trait", en: "dash", es: "chorrito" },
  traits: { fr: "traits", en: "dashes", es: "chorritos" },
  gros: { fr: "gros", en: "large", es: "grandes" },
  grande: { fr: "grande", en: "large", es: "grande" },
};

export function canonicalUnit(unit: string | null | undefined): Canonical | null {
  if (!unit) return null;
  const key = unit.trim().toLowerCase().replace(/\s+/g, " ");
  return ALIASES[key] ?? null;
}

// Arrondi lisible selon l'unité : pas de « 237,57 ml ».
function tidy(value: number, unit: Canonical) {
  if (unit === "g" || unit === "ml") {
    if (value >= 100) return Math.round(value / 5) * 5;
    if (value >= 10) return Math.round(value);
    return Math.round(value * 10) / 10;
  }
  if (unit === "oz" || unit === "floz") return value >= 10 ? Math.round(value) : Math.round(value * 4) / 4;
  if (unit === "lb") return value < 5 ? Math.round(value * 8) / 8 : Math.round(value * 4) / 4;
  if (unit === "kg" || unit === "l") return Math.round(value * 100) / 100;
  // Cuillères et tasses : au quart près (affiché ensuite en fraction ¼, ½, ¾).
  const quarter = Math.round(value * 4) / 4;
  if (quarter > 0) return quarter;
  const eighth = Math.round(value * 8) / 8;
  return eighth > 0 ? eighth : Math.round(value * 100) / 100;
}

function pickVolume(ml: number, system: MeasurementSystem): [number, Canonical] {
  if (system === "metric") {
    // Les cuillères restent des cuillères : 1 c. à thé est plus parlante que 4,9 ml.
    if (ml < 15 * 3) return ml < 14 ? [ml / VOLUME.tsp!, "tsp"] : [ml / VOLUME.tbsp!, "tbsp"];
    return ml >= 1000 ? [ml / 1000, "l"] : [ml, "ml"];
  }
  if (system === "imperial") {
    if (ml < 14) return [ml / VOLUME.tsp!, "tsp"];
    if (ml < 44) return [ml / VOLUME.tbsp!, "tbsp"];
    return [ml / VOLUME.floz!, "floz"];
  }
  // Système « tasses » (cuisine nord-américaine).
  if (ml < 14) return [ml / VOLUME.tsp!, "tsp"];
  if (ml < 59) return [ml / VOLUME.tbsp!, "tbsp"];
  return [ml / VOLUME.cup!, "cup"];
}

function pickMass(g: number, system: MeasurementSystem): [number, Canonical] {
  if (system === "imperial") {
    const oz = g / MASS.oz!;
    return oz >= 16 ? [g / MASS.lb!, "lb"] : [oz, "oz"];
  }
  // Métrique et tasses : les masses restent en grammes (pas de conversion masse → volume sans densité).
  return g >= 1000 ? [g / 1000, "kg"] : [g, "g"];
}

export type DisplayQuantity = { value: number | null; unit: string | null };

/**
 * Convertit une quantité (déjà multipliée par le ratio de portions) vers le système voulu
 * et renvoie la valeur arrondie avec le libellé d'unité traduit.
 */
export function convertQuantity(
  value: number | null,
  unit: string | null,
  system: MeasurementSystem,
  language: LanguageCode,
): DisplayQuantity {
  const canonical = canonicalUnit(unit);
  if (canonical == null) return { value, unit: localizedUnit(unit, language, value) };
  if (value == null) return { value: null, unit: unitLabel(canonical, language, 1) };

  let converted: [number, Canonical];
  if (MASS[canonical] != null) converted = pickMass(value * MASS[canonical]!, system);
  else converted = pickVolume(value * VOLUME[canonical]!, system);

  const [amount, target] = converted;
  const rounded = tidy(amount, target);
  return { value: rounded, unit: unitLabel(target, language, rounded) };
}

function unitLabel(unit: Canonical, language: LanguageCode, value: number) {
  const [one, many] = (CANONICAL_LABELS[language] ?? CANONICAL_LABELS.fr)[unit];
  return value > 1 ? many : one;
}

/** Traduit une unité non convertible (gousses, pincée…) ; garde le texte d'origine si inconnue. */
export function localizedUnit(unit: string | null, language: LanguageCode, value: number | null = null) {
  if (!unit) return unit;
  const key = unit.trim().toLowerCase();
  const canonical = ALIASES[key];
  if (canonical) return unitLabel(canonical, language, value ?? 1);
  return COUNT_UNITS[key]?.[language] ?? unit;
}

// Températures dans le texte des étapes : « 180 °C », « 350°F », « 350 degrees F ».
const PAIR = /(\d{2,3})\s*°\s*([CF])\b\s*\(\s*(?:environ\s+|about\s+|unos\s+)?(\d{2,3})\s*°\s*([CF])\s*\)/gi;
const SINGLE = /(\d{2,3})\s*(?:°\s*|degrees?\s+|degrés?\s+|grados?\s+)([CF])(?:ahrenheit|elsius)?\b/gi;

function toTarget(degrees: number, from: string, to: TemperatureUnit) {
  const source = from.toLowerCase() as TemperatureUnit;
  if (source === to) return degrees;
  const raw = to === "f" ? degrees * 9 / 5 + 32 : (degrees - 32) * 5 / 9;
  // Les fours en °F se règlent par paliers de 25 (350, 375, 400…); en °C, par 5.
  if (to === "f" && raw >= 200) return Math.round(raw / 25) * 25;
  return Math.round(raw / 5) * 5;
}

/** Réécrit les températures d'une étape dans l'unité choisie (°C ou °F). */
export function convertTemperatures(text: string, to: TemperatureUnit) {
  const label = to === "f" ? "°F" : "°C";
  return text
    // « 350 °F (175 °C) » : on garde seulement la valeur dans l'unité voulue.
    .replace(PAIR, (match, a: string, ua: string, b: string, ub: string) => {
      if (ua.toLowerCase() === to) return `${a} ${label}`;
      if (ub.toLowerCase() === to) return `${b} ${label}`;
      return match;
    })
    .replace(SINGLE, (_match, value: string, unit: string) => `${toTarget(Number(value), unit, to)} ${label}`);
}
