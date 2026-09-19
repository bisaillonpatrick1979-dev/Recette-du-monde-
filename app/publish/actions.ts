"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { Json } from "@/lib/supabase/database.types";

function textValue(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

function optionalNumber(value: string) {
  if (!value) return undefined;
  const number = Number(value);
  return Number.isFinite(number) ? number : undefined;
}

function parseIngredients(raw: string): Json {
  return raw
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const [quantity = "", unit = "", ...nameParts] = line.split("|").map((part) => part.trim());
      return {
        quantity: quantity ? Number(quantity.replace(",", ".")) : null,
        unit,
        name: nameParts.join("|") || unit || quantity,
      };
    });
}

function parseSteps(raw: string): Json {
  return raw
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((instruction) => ({ instruction }));
}

export async function createRecipe(formData: FormData) {
  const supabase = await createClient();
  const { data: claimsData, error: authError } = await supabase.auth.getClaims();

  if (authError || !claimsData?.claims?.sub) {
    redirect("/login");
  }

  const title = textValue(formData, "title");
  if (title.length < 2) {
    redirect("/publish?error=Le titre est requis.");
  }

  const status = textValue(formData, "status") === "published" ? "published" : "draft";
  const authenticityRaw = textValue(formData, "authenticity");
  const authenticity =
    authenticityRaw === "traditional" || authenticityRaw === "fusion"
      ? authenticityRaw
      : "adapted";
  const difficultyRaw = textValue(formData, "difficulty");
  const difficulty =
    difficultyRaw === "easy" || difficultyRaw === "medium" || difficultyRaw === "hard"
      ? difficultyRaw
      : undefined;

  const { data, error } = await supabase.rpc("create_recipe_with_content", {
    p_title: title,
    p_description: textValue(formData, "description") || undefined,
    p_source_language: textValue(formData, "source_language") || "fr",
    p_country_code: textValue(formData, "country_code") || undefined,
    p_region: textValue(formData, "region") || undefined,
    p_category: textValue(formData, "category") || undefined,
    p_authenticity: authenticity,
    p_difficulty: difficulty,
    p_prep_minutes: optionalNumber(textValue(formData, "prep_minutes")),
    p_cook_minutes: optionalNumber(textValue(formData, "cook_minutes")),
    p_servings: optionalNumber(textValue(formData, "servings")),
    p_status: status,
    p_ingredients: parseIngredients(textValue(formData, "ingredients")),
    p_steps: parseSteps(textValue(formData, "steps")),
  });

  if (error || !data) {
    redirect(`/publish?error=${encodeURIComponent(error?.message || "Impossible de créer la recette.")}`);
  }

  redirect(`/recipes/${data}`);
}
