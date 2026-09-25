import type { ContinentKey } from "@/lib/continents";

export type HomeRecipe = {
  id: string;
  title: string;
  originalTitle: string;
  titleTranslations: Array<{ language_code: string; title: string }>;
  country: string;
  countryCode: string;
  region: string | null;
  flag: string;
  image: string | null;
  time: string;
  difficulty: "Facile" | "Moyen" | "Difficile";
  category: string;
};

export type HomeCountryCard = {
  flag: string;
  name: string;
  countryCode: string;
  dishes: string;
};

export type HomeContinentStat = {
  key: ContinentKey;
  label: string;
  icon: string;
  recipes: number;
};

export type HomeCommunityRecipe = {
  id: string;
  title: string;
  author: string;
  authorCountry: string | null;
  image: string | null;
  likes: number;
  comments: number;
  rating: number | null;
  ratingCount: number;
};

export type HomeAtlasStats = {
  recipes: number;
  editorialRecipes: number;
  communityRecipes: number;
  borderlessRecipes: number;
  countries: number;
  subplaces: number;
  continents: HomeContinentStat[];
};
