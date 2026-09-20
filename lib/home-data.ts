export type HomeRecipe = {
  id: string;
  title: string;
  country: string;
  region: string | null;
  flag: string;
  image: string;
  time: string;
  difficulty: "Facile" | "Moyen" | "Difficile";
  category: string;
};

export type HomeCountryCard = {
  flag: string;
  name: string;
  dishes: string;
};

export type HomeContinentStat = {
  key: "north-america" | "latin-america" | "europe" | "asia" | "africa" | "middle-east" | "oceania";
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
  countries: number;
  subplaces: number;
  continents: HomeContinentStat[];
};
