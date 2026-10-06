"use client";

import { useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { hasSavedPreferences } from "@/lib/use-preferences";

export function OnboardingGate() {
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    if (pathname === "/onboarding") return;

    // Lecture protégée : un stockage bloqué ne fait plus planter la page.
    if (!hasSavedPreferences()) {
      router.replace("/onboarding");
    }
  }, [pathname, router]);

  return null;
}
