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
