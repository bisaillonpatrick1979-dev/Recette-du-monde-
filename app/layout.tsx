import type { Metadata } from "next";
import "./globals.css";
import { OnboardingGate } from "@/components/onboarding-gate";

export const metadata: Metadata = {
  title: "Cuisine du monde",
  description: "Découvrez, partagez et cuisinez les meilleures recettes du monde.",
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
