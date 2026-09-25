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
