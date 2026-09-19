import type { Metadata } from "next";
import { CulinaryGlobe } from "@/components/culinary-globe";

export const metadata: Metadata = {
  title: "Atlas culinaire | Cuisine du monde",
  description: "Explorez les cuisines du monde par pays, région, île et ville sur un globe interactif.",
};

export default function ExplorePage() {
  return (
    <main className="atlas-page">
      <CulinaryGlobe />
    </main>
  );
}
