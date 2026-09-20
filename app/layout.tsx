import type { Metadata } from "next";
import "maplibre-gl/dist/maplibre-gl.css";
import "./globals.css";
import { OnboardingGate } from "@/components/onboarding-gate";

export const metadata: Metadata = {
  title: "Recette de la planète",
  description: "Explorez les recettes de la planète, partagez vos créations et cuisinez avec une communauté mondiale.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fr">
      <body>
        <OnboardingGate />
        {children}
      </body>
    </html>
  );
}
