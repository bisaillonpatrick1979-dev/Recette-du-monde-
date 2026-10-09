// Catégories et filtres rapides de l'accueil → motifs de recherche sur recipes.search_text
// (titre, description, catégorie, pays, région).

export type SearchCategory = {
  key: string;
  icon: string;
  label: string;
  patterns: string[];
};

export const SEARCH_CATEGORIES: SearchCategory[] = [
  { key: "entrees", icon: "🍢", label: "Entrées", patterns: ["entrée", "appetizer", "dip", "starter", "mezze", "tapas"] },
  { key: "soupes", icon: "🥣", label: "Soupes", patterns: ["soup", "soupe", "chorba", "ciorb", "bouillon", "broth"] },
  { key: "plats", icon: "🍲", label: "Plats principaux", patterns: ["stew", "ragoût", "curry", "roast", "rôti", "casserole", "mijoté"] },
  { key: "salades", icon: "🥗", label: "Salades", patterns: ["salad", "salade"] },
  { key: "pates", icon: "🍝", label: "Pâtes", patterns: ["pasta", "pâtes", "noodle", "nouille", "spaghetti", "lasagn", "ravioli", "gnocchi"] },
  { key: "viandes", icon: "🥩", label: "Viandes", patterns: ["beef", "bœuf", "pork", "porc", "lamb", "agneau", "chicken", "poulet", "goat", "chèvre"] },
  { key: "poissons", icon: "🐟", label: "Poissons et fruits de mer", patterns: ["fish", "poisson", "shrimp", "crevette", "crab", "crabe", "salmon", "saumon", "seafood", "fruits de mer", "tuna", "thon"] },
  { key: "vegetarien", icon: "🌿", label: "Végétarien", patterns: ["vegan", "végé", "vegetarian", "vegetable", "légume", "tofu", "lentil", "lentille"] },
  { key: "desserts", icon: "🍰", label: "Desserts", patterns: ["dessert", "cake", "gâteau", "cookie", "biscuit", "pudding", "pie", "tarte", "sucré"] },
];

export type QuickFilter = {
  key: string;
  label: string;
  patterns?: string[];
  maxMinutes?: number;
  popular?: boolean;
};

export const QUICK_FILTERS: QuickFilter[] = [
  { key: "rapide", label: "⚡ 30 minutes et moins", maxMinutes: 30 },
  { key: "bbq", label: "🔥 BBQ", patterns: ["barbecue", "bbq", "grill", "brochette", "asado", "khorovats", "shashlik"] },
  { key: "populaires", label: "⭐ Les plus populaires", popular: true },
];

// Échappe les caractères spéciaux du filtre PostgREST .or() et de ILIKE.
export function ilikePattern(value: string) {
  const cleaned = value.replace(/[%_\\,()"]/g, " ").replace(/\s+/g, " ").trim();
  return cleaned ? `%${cleaned}%` : null;
}

// Recherche par pays : « canada », « Canadá », « canadien » → CA.
// Noms en français, anglais et espagnol générés par Intl, plus quelques gentilés courants.
const DEMONYMS: Record<string, string> = {
  canadien: "CA", canadienne: "CA", quebecois: "CA", quebecoise: "CA", acadien: "CA", acadienne: "CA",
  francais: "FR", francaise: "FR", italien: "IT", italienne: "IT", espagnol: "ES", espagnole: "ES",
  mexicain: "MX", mexicaine: "MX", japonais: "JP", japonaise: "JP", chinois: "CN", chinoise: "CN",
  indien: "IN", indienne: "IN", marocain: "MA", marocaine: "MA", libanais: "LB", libanaise: "LB",
  grec: "GR", grecque: "GR", turc: "TR", turque: "TR", thai: "TH", thailandais: "TH", vietnamien: "VN",
  coreen: "KR", coreenne: "KR", allemand: "DE", allemande: "DE", portugais: "PT", bresilien: "BR",
  peruvien: "PE", americain: "US", americaine: "US", belge: "BE", suisse: "CH", senegalais: "SN",
  irlandais: "IE", polonais: "PL", russe: "RU", ethiopien: "ET", haitien: "HT", cubain: "CU",
};

function normalizeName(value: string) {
  return value.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z]+/g, " ").trim();
}

let countryIndex: Map<string, string> | null = null;
function getCountryIndex() {
  if (countryIndex) return countryIndex;
  countryIndex = new Map(Object.entries(DEMONYMS));
  const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  const names = ["fr", "en", "es"].map((lang) => new Intl.DisplayNames([lang], { type: "region" }));
  for (const a of letters) {
    for (const b of letters) {
      const code = a + b;
      for (const display of names) {
        let name: string | undefined;
        try {
          name = display.of(code);
        } catch {
          name = undefined;
        }
        if (!name || name === code) continue;
        const key = normalizeName(name);
        if (key && !countryIndex.has(key)) countryIndex.set(key, code);
      }
    }
  }
  return countryIndex;
}

/** Codes pays correspondant exactement à la recherche (nom du pays ou gentilé). */
export function countryCodesForQuery(query: string): string[] {
  const key = normalizeName(query);
  if (key.length < 3) return [];
  const code = getCountryIndex().get(key);
  return code ? [code] : [];
}
