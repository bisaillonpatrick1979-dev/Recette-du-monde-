// Chef IA : répond aux questions d'un membre sur une recette (substitutions, variantes, technique…).
// La clé OpenAI reste côté serveur. Chaque réponse réussie coûte un crédit du forfait mensuel;
// un appel raté ne coûte rien (le crédit est débité seulement après la réponse du modèle).

import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";
const MAX_QUESTION = 500;
const LANGUAGES = { fr: "français québécois", en: "English", es: "español" } as const;
type Language = keyof typeof LANGUAGES;

type ChefRequest = { recipeId?: unknown; question?: unknown; language?: unknown };

function fail(status: number, error: string, extra: Record<string, unknown> = {}) {
  return NextResponse.json({ error, ...extra }, { status });
}

export async function POST(request: NextRequest) {
  let body: ChefRequest;
  try {
    body = (await request.json()) as ChefRequest;
  } catch {
    return fail(400, "Requête invalide.");
  }

  const recipeId = typeof body.recipeId === "string" ? body.recipeId : "";
  const question = typeof body.question === "string" ? body.question.trim().slice(0, MAX_QUESTION) : "";
  const language: Language =
    typeof body.language === "string" && body.language in LANGUAGES ? (body.language as Language) : "fr";

  if (!/^[0-9a-f-]{36}$/i.test(recipeId) || question.length < 3) {
    return fail(400, "Posez une question d’au moins quelques mots.");
  }

  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  if (!claims?.claims?.sub) {
    return fail(401, "Connectez-vous pour consulter le Chef IA.");
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return fail(503, "Le Chef IA n’est pas encore activé sur ce site.");
  }

  // Solde du forfait (remis à zéro chaque mois par la base).
  const { data: credits, error: creditsError } = await supabase.rpc("credits_ia");
  if (creditsError) {
    return fail(503, "Le Chef IA est momentanément indisponible.");
  }
  const balance = credits?.[0];
  if (!balance || balance.credits_restants <= 0) {
    return fail(402, "Vous avez utilisé tous vos crédits du Chef IA ce mois-ci.", {
      remaining: 0,
      monthly: balance?.credits_mensuels ?? 0,
      resetAt: balance?.fin_periode ?? null,
    });
  }

  const { data: recipe } = await supabase
    .from("recipes")
    .select(
      "title,original_title,description,country_code,region,servings,prep_minutes,cook_minutes,recipe_ingredients(position,name,quantity,unit,note),recipe_steps(position,instruction)",
    )
    .eq("id", recipeId)
    .eq("status", "published")
    .maybeSingle();

  if (!recipe) {
    return fail(404, "Recette introuvable.");
  }

  const ingredients = [...(recipe.recipe_ingredients ?? [])]
    .sort((a, b) => a.position - b.position)
    .map((item) => `- ${[item.quantity, item.unit, item.name].filter(Boolean).join(" ")}${item.note ? ` (${item.note})` : ""}`)
    .join("\n");
  const steps = [...(recipe.recipe_steps ?? [])]
    .sort((a, b) => a.position - b.position)
    .map((step, index) => `${index + 1}. ${step.instruction}`)
    .join("\n");

  const recipeText = [
    `Titre : ${recipe.title}${recipe.original_title && recipe.original_title !== recipe.title ? ` (${recipe.original_title})` : ""}`,
    `Origine : ${[recipe.region, recipe.country_code].filter(Boolean).join(", ") || "inconnue"}`,
    `Portions : ${recipe.servings ?? "?"} · Préparation : ${recipe.prep_minutes ?? "?"} min · Cuisson : ${recipe.cook_minutes ?? "?"} min`,
    recipe.description ? `Description : ${recipe.description}` : "",
    `Ingrédients :\n${ingredients || "(non précisés)"}`,
    `Étapes :\n${steps || "(non précisées)"}`,
  ]
    .filter(Boolean)
    .join("\n\n")
    .slice(0, 12000);

  const system = [
    "Tu es le Chef IA de Spoontrotter, une application de recettes du monde entier.",
    `Réponds en ${LANGUAGES[language]}, de façon chaleureuse, concrète et brève (8 phrases ou une courte liste au maximum).`,
    "Tu aides sur la recette fournie : substitutions d'ingrédients, variantes (végétarienne, sans gluten…),",
    "adaptation des portions, techniques, conservation, accords, histoire du plat.",
    "Respecte l'origine culturelle du plat et signale quand une variante s'éloigne de la tradition.",
    "Sécurité alimentaire d'abord : températures de cuisson sûres, allergènes, conservation.",
    "Pour toute question médicale (allergie grave, régime thérapeutique), recommande un professionnel de la santé.",
    "Si la question ne concerne pas la cuisine, ramène poliment la conversation vers la recette.",
    "N'invente pas d'ingrédients absents de la recette en prétendant qu'ils y sont.",
  ].join(" ");

  let answer = "";
  let inputTokens = 0;
  let outputTokens = 0;
  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({
        model: MODEL,
        max_completion_tokens: 700,
        messages: [
          { role: "system", content: system },
          { role: "user", content: `Recette :\n${recipeText}\n\nQuestion du membre : ${question}` },
        ],
      }),
      signal: AbortSignal.timeout(45_000),
    });

    if (!response.ok) {
      console.error("Chef IA : erreur OpenAI", response.status, (await response.text()).slice(0, 300));
      return fail(502, "Le Chef IA n’a pas pu répondre. Aucun crédit n’a été utilisé.");
    }

    const payload = (await response.json()) as {
      choices?: Array<{ message?: { content?: string | null } }>;
      usage?: { prompt_tokens?: number; completion_tokens?: number };
    };
    answer = payload.choices?.[0]?.message?.content?.trim() ?? "";
    inputTokens = payload.usage?.prompt_tokens ?? 0;
    outputTokens = payload.usage?.completion_tokens ?? 0;
  } catch (error) {
    console.error("Chef IA : appel impossible", error);
    return fail(504, "Le Chef IA met trop de temps à répondre. Aucun crédit n’a été utilisé.");
  }

  if (!answer) {
    return fail(502, "Le Chef IA n’a pas pu répondre. Aucun crédit n’a été utilisé.");
  }

  const { data: remaining, error: consumeError } = await supabase.rpc("consommer_credit_ia", {
    p_fonction: "chef_recette",
    p_modele: MODEL,
    p_jetons_entree: inputTokens,
    p_jetons_sortie: outputTokens,
  });
  if (consumeError) {
    console.error("Chef IA : débit du crédit impossible", consumeError.message);
  }

  return NextResponse.json({
    answer,
    remaining: typeof remaining === "number" ? remaining : Math.max(balance.credits_restants - 1, 0),
    monthly: balance.credits_mensuels,
  });
}
