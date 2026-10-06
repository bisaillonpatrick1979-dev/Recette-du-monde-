"use client";

// Ajouter / retirer une recette de « Mes favoris » (table favorites, privée à chaque membre).

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export function FavoriteButton({
  recipeId,
  viewerId,
  initialFavorite,
}: {
  recipeId: string;
  viewerId: string | null;
  initialFavorite: boolean;
}) {
  const router = useRouter();
  const [favorite, setFavorite] = useState(initialFavorite);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function toggle() {
    if (!viewerId) {
      router.push("/login");
      return;
    }
    if (busy) return;

    setBusy(true);
    setError("");
    const supabase = createClient();
    const { error: requestError } = favorite
      ? await supabase.from("favorites").delete().eq("recipe_id", recipeId).eq("user_id", viewerId)
      : await supabase.from("favorites").insert({ recipe_id: recipeId, user_id: viewerId });
    setBusy(false);

    // Déjà en favori (double clic, autre onglet) : on considère l'ajout réussi.
    if (requestError && requestError.code !== "23505") {
      setError("Impossible de modifier vos favoris pour le moment.");
      return;
    }
    setFavorite(!favorite);
  }

  return (
    <span className="favorite-control">
      <button
        type="button"
        className={favorite ? "favorite-toggle active" : "favorite-toggle"}
        onClick={() => void toggle()}
        disabled={busy}
        aria-pressed={favorite}
      >
        {favorite ? "★ Dans mes favoris" : "☆ Ajouter aux favoris"}
      </button>
      {error ? <small className="social-status">{error}</small> : null}
    </span>
  );
}
