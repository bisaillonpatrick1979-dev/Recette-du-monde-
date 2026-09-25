import type { Metadata } from "next";
import "maplibre-gl/dist/maplibre-gl.css";
import "./globals.css";
import { OnboardingGate } from "@/components/onboarding-gate";
import { APP_NAME, APP_TAGLINE_EN, APP_TAGLINE_FR } from "@/lib/brand";

export const metadata: Metadata = {
  title: {
    default: `${APP_NAME} · ${APP_TAGLINE_EN}`,
    template: `%s | ${APP_NAME}`,
  },
  description: `${APP_TAGLINE_FR}. Explorez les spécialités de chaque pays, région et ville sur un globe interactif, partagez vos recettes et cuisinez avec une communauté mondiale.`,
  applicationName: APP_NAME,
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
