"use client";

import { useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { PREFERENCES_STORAGE_KEY } from "@/lib/preferences";

export function OnboardingGate() {
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    if (pathname === "/onboarding") return;

    const saved = window.localStorage.getItem(PREFERENCES_STORAGE_KEY);
    if (!saved) {
      router.replace("/onboarding");
    }
  }, [pathname, router]);

  return null;
}
