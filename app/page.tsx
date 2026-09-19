import { HomeExperience } from "@/components/home-experience";
import { countryCards, featuredRecipes } from "@/lib/demo-data";

export default function HomePage() {
  return <HomeExperience recipes={featuredRecipes} countries={countryCards} />;
}
