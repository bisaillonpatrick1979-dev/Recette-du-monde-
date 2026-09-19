export type DemoRecipe = {
  title: string;
  country: string;
  flag: string;
  image: string;
  rating: string;
  reviews: string;
  time: string;
  difficulty: "Facile" | "Moyen";
  category: string;
};

export const featuredRecipes: DemoRecipe[] = [
  {
    title: "Pâtes Carbonara",
    country: "Italie",
    flag: "🇮🇹",
    image: "https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=900&q=80",
    rating: "4,9",
    reviews: "12,4 k",
    time: "25 min",
    difficulty: "Facile",
    category: "Pâtes",
  },
  {
    title: "Tacos al Pastor",
    country: "Mexique",
    flag: "🇲🇽",
    image: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=900&q=80",
    rating: "4,8",
    reviews: "8,9 k",
    time: "40 min",
    difficulty: "Moyen",
    category: "Cuisine de rue",
  },
  {
    title: "Ramen au miso",
    country: "Japon",
    flag: "🇯🇵",
    image: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
    rating: "4,9",
    reviews: "14,1 k",
    time: "50 min",
    difficulty: "Moyen",
    category: "Soupes",
  },
  {
    title: "Curry de légumes",
    country: "Inde",
    flag: "🇮🇳",
    image: "https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?auto=format&fit=crop&w=900&q=80",
    rating: "4,8",
    reviews: "9,6 k",
    time: "35 min",
    difficulty: "Facile",
    category: "Végétarien",
  },
  {
    title: "Cheesecake new-yorkais",
    country: "États-Unis",
    flag: "🇺🇸",
    image: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=900&q=80",
    rating: "4,9",
    reviews: "11,2 k",
    time: "1 h 20",
    difficulty: "Moyen",
    category: "Desserts",
  },
];

export const countryCards = [
  { flag: "🇮🇹", name: "Italie", dishes: "Pâtes, risotto, pizza" },
  { flag: "🇯🇵", name: "Japon", dishes: "Ramen, sushi, donburi" },
  { flag: "🇲🇽", name: "Mexique", dishes: "Tacos, mole, pozole" },
  { flag: "🇫🇷", name: "France", dishes: "Bistro, pâtisserie, sauces" },
  { flag: "🇹🇭", name: "Thaïlande", dishes: "Curry, nouilles, street food" },
  { flag: "🇲🇦", name: "Maroc", dishes: "Tajines, couscous, pâtisseries" },
];
