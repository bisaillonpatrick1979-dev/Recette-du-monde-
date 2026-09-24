"use client";

import { useEffect, useState } from "react";
import { login, resendConfirmation, signup } from "@/app/auth/actions";
import {
  defaultPreferences,
  PREFERENCES_STORAGE_KEY,
  type UserPreferences,
} from "@/lib/preferences";

type Props = {
  error?: string;
  message?: string;
};

export function AuthForm({ error, message }: Props) {
  const [preferences, setPreferences] = useState<UserPreferences>(defaultPreferences);

  useEffect(() => {
    const saved = window.localStorage.getItem(PREFERENCES_STORAGE_KEY);
    if (!saved) return;
    try {
      setPreferences(JSON.parse(saved) as UserPreferences);
    } catch {
      setPreferences(defaultPreferences);
    }
  }, []);

  return (
    <div className="auth-card">
      <div className="onboarding-heading">
        <span className="step-pill">Votre compte</span>
        <h1>Rejoindre Spoontrotter</h1>
        <p>
          Sauvegardez vos recettes, publiez vos créations et échangez avec des cuisiniers du monde entier.
        </p>
      </div>

      {error ? <p className="form-alert error">{error}</p> : null}
      {message ? <p className="form-alert success">{message}</p> : null}

      <form className="auth-form">
        <input type="hidden" name="country_code" value={preferences.country} />
        <input type="hidden" name="language_code" value={preferences.language} />
        <input type="hidden" name="currency_code" value={preferences.currency} />

        <label>
          <span>Nom affiché</span>
          <input name="display_name" autoComplete="name" placeholder="Votre nom ou pseudo" />
        </label>
        <label>
          <span>Courriel</span>
          <input name="email" type="email" autoComplete="email" required placeholder="vous@exemple.com" />
        </label>
        <label>
          <span>Mot de passe</span>
          <input name="password" type="password" autoComplete="current-password" minLength={8} required />
        </label>

        <div className="auth-actions">
          <button className="primary-button" formAction={login}>Connexion</button>
          <button className="secondary-button" formAction={signup}>Créer mon compte</button>
        </div>
      </form>

      <form action={resendConfirmation} className="auth-resend">
        <div>
          <strong>Compte créé mais pas confirmé?</strong>
          <small>Entrez votre courriel et nous renverrons le lien.</small>
        </div>
        <input
          name="resend_email"
          type="email"
          autoComplete="email"
          required
          placeholder="votre courriel"
          aria-label="Courriel du compte à confirmer"
        />
        <button className="ghost-button" type="submit">Renvoyer la confirmation</button>
      </form>
    </div>
  );
}
