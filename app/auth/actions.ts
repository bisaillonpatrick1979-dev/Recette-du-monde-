"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

function textValue(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

async function getSiteOrigin() {
  const requestHeaders = await headers();
  const host = requestHeaders.get("x-forwarded-host") ?? requestHeaders.get("host");
  const proto = requestHeaders.get("x-forwarded-proto") ?? "https";
  const fallback = host ? `${proto}://${host}` : "";
  return (process.env.NEXT_PUBLIC_SITE_URL || fallback).replace(/\/+$/, "");
}

export async function login(formData: FormData) {
  const email = textValue(formData, "email");
  const password = textValue(formData, "password");
  const supabase = await createClient();

  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    const lower = error.message.toLowerCase();
    if (lower.includes("email not confirmed") || error.code === "email_not_confirmed") {
      redirect("/login?error=Votre compte existe, mais votre courriel n’est pas encore confirmé. Utilisez le bouton pour renvoyer le courriel de confirmation.");
    }
    redirect(`/login?error=${encodeURIComponent(error.message)}`);
  }

  redirect("/profile");
}

export async function signup(formData: FormData) {
  const email = textValue(formData, "email").toLowerCase();
  const password = textValue(formData, "password");
  const displayName = textValue(formData, "display_name");
  const countryCode = textValue(formData, "country_code") || "CA";
  const languageCode = textValue(formData, "language_code") || "fr";
  const currencyCode = textValue(formData, "currency_code") || "CAD";

  if (!email || !email.includes("@")) {
    redirect("/login?error=Entrez une adresse courriel valide.");
  }
  if (password.length < 8) {
    redirect("/login?error=Le mot de passe doit contenir au moins 8 caractères.");
  }

  const origin = await getSiteOrigin();
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: origin ? `${origin}/auth/callback` : undefined,
      data: {
        display_name: displayName,
        country_code: countryCode,
        language_code: languageCode,
        currency_code: currencyCode,
      },
    },
  });

  if (error) {
    redirect(`/login?error=${encodeURIComponent(error.message)}`);
  }

  if (!data.session) {
    redirect("/login?message=Compte créé. Vérifiez votre boîte de réception et vos pourriels, puis appuyez sur le lien de confirmation. Si le courriel n’arrive pas, utilisez « Renvoyer la confirmation » ci-dessous.");
  }

  redirect("/profile");
}

export async function resendConfirmation(formData: FormData) {
  const email = textValue(formData, "resend_email").toLowerCase();
  if (!email || !email.includes("@")) {
    redirect("/login?error=Entrez le courriel du compte à confirmer.");
  }

  const origin = await getSiteOrigin();
  const supabase = await createClient();
  const { error } = await supabase.auth.resend({
    type: "signup",
    email,
    options: {
      emailRedirectTo: origin ? `${origin}/auth/callback` : undefined,
    },
  });

  if (error) {
    redirect(`/login?error=${encodeURIComponent(error.message)}`);
  }

  redirect("/login?message=Le courriel de confirmation a été renvoyé. Vérifiez aussi votre dossier Pourriels.");
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/");
}
