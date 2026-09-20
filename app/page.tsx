import { HomeExperience } from "@/components/home-experience";
import type { HomeCountryCard, HomeRecipe } from "@/lib/home-data";
import { resolveMediaUrl } from "@/lib/media";
import { createClient } from "@/lib/supabase/server";

function flagFor(code: string) {
  return code
    .toUpperCase()
    .replace(/[A-Z]/g, (letter) =>
      String.fromCodePoint(127397 + letter.charCodeAt(0)),
    );
}

function difficultyLabel(value: "easy" | "medium" | "hard" | null) {
  if (value === "hard") return "Difficile" as const;
  if (value === "medium") return "Moyen" as const;
  return "Facile" as const;
}

function timeLabel(prep: number | null, cook: number | null) {
  const total = (prep ?? 0) + (cook ?? 0);
  if (!total) return "—";
  if (total < 60) return `${total} min`;
  const hours = Math.floor(total / 60);
  const minutes = total % 60;
  return minutes ? `${hours} h ${minutes}` : `${hours} h`;
}

export default async function HomePage() {
  const supabase = await createClient();

  const { data } = await supabase
    .from("recipes")
    .select(
      "id,title,country_code,region,category,difficulty,prep_minutes,cook_minutes,published_at,recipe_images!recipe_images_recipe_id_fkey(id,storage_path,external_url,is_primary,status)",
    )
    .eq("status", "published")
    .order("published_at", { ascending: false })
    .limit(18);

  const displayNames = new Intl.DisplayNames(["fr"], { type: "region" });

  const recipes: HomeRecipe[] = (data ?? []).flatMap((recipe) => {
    const images = [...(recipe.recipe_images ?? [])]
      .filter((image) => image.status === "ready")
      .sort((a, b) => Number(b.is_primary) - Number(a.is_primary));
    const image = images[0] ? resolveMediaUrl(images[0], "recipe-images") : null;
    if (!image) return [];

    const code = recipe.country_code || "";
    return [{
      id: recipe.id,
      title: recipe.title,
      country: (code && displayNames.of(code)) || code || "Cuisine du monde",
      region: recipe.region,
      flag: code.length === 2 ? flagFor(code) : "🌍",
      image,
      time: timeLabel(recipe.prep_minutes, recipe.cook_minutes),
      difficulty: difficultyLabel(recipe.difficulty),
      category: recipe.category || "Recette",
    }];
  });

  const countryMap = new Map<string, { flag: string; titles: string[] }>();
  for (const recipe of recipes) {
    const current = countryMap.get(recipe.country) ?? { flag: recipe.flag, titles: [] };
    if (!current.titles.includes(recipe.title)) current.titles.push(recipe.title);
    countryMap.set(recipe.country, current);
  }

  const countries: HomeCountryCard[] = [...countryMap.entries()]
    .slice(0, 10)
    .map(([name, value]) => ({
      flag: value.flag,
      name,
      dishes: value.titles.slice(0, 3).join(", "),
    }));

  return <HomeExperience recipes={recipes} countries={countries} />;
}
