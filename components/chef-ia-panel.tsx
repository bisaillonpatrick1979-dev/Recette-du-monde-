"use client";

// Panneau « Demandez au Chef IA » sur la page recette.

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { usePreferences } from "@/lib/use-preferences";

const SUGGESTIONS = [
  "Par quoi remplacer un ingrédient difficile à trouver ?",
  "Comment en faire une version végétarienne ?",
  "Peut-on la préparer la veille ?",
  "Quelle boisson servir avec ce plat ?",
];

type Exchange = { question: string; answer: string };

export function ChefIaPanel({ recipeId, viewerId }: { recipeId: string; viewerId: string | null }) {
  const router = useRouter();
  const [preferences] = usePreferences();
  const [question, setQuestion] = useState("");
  const [history, setHistory] = useState<Exchange[]>([]);
  const [remaining, setRemaining] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function ask(text: string) {
    const value = text.trim();
    if (!value || busy) return;
    if (!viewerId) {
      router.push("/login");
      return;
    }

    setBusy(true);
    setError("");
    try {
      const response = await fetch("/api/chef", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ recipeId, question: value, language: preferences.language }),
      });
      const payload = (await response.json().catch(() => ({}))) as {
        answer?: string;
        error?: string;
        remaining?: number;
      };
      if (typeof payload.remaining === "number") setRemaining(payload.remaining);
      if (!response.ok || !payload.answer) {
        setError(payload.error || "Le Chef IA n’a pas pu répondre.");
        return;
      }
      setHistory((items) => [{ question: value, answer: payload.answer! }, ...items].slice(0, 5));
      setQuestion("");
    } catch {
      setError("Connexion impossible. Vérifiez votre réseau et réessayez.");
    } finally {
      setBusy(false);
    }
  }

  function submit(event: FormEvent) {
    event.preventDefault();
    void ask(question);
  }

  return (
    <section className="chef-ia-panel" aria-labelledby="chef-ia-title">
      <div className="chef-ia-head">
        <span className="chef-ia-avatar" aria-hidden="true">👨‍🍳</span>
        <div>
          <span className="eyebrow">Chef IA</span>
          <h2 id="chef-ia-title">Une question sur cette recette ?</h2>
          <p className="muted">
            Substitutions, variantes, techniques, conservation…
            {remaining != null ? ` Il vous reste ${remaining} crédit${remaining > 1 ? "s" : ""} ce mois-ci.` : ""}
          </p>
        </div>
      </div>

      <div className="chef-ia-suggestions">
        {SUGGESTIONS.map((suggestion) => (
          <button key={suggestion} type="button" onClick={() => void ask(suggestion)} disabled={busy}>
            {suggestion}
          </button>
        ))}
      </div>

      <form className="comment-form" onSubmit={submit}>
        <input
          value={question}
          onChange={(event) => setQuestion(event.target.value)}
          placeholder={viewerId ? "Ex. : je n’ai pas de crème, que faire ?" : "Connectez-vous pour poser une question"}
          maxLength={500}
          aria-label="Votre question au Chef IA"
        />
        <button type="submit" disabled={busy || question.trim().length < 3}>
          {busy ? "Le chef réfléchit…" : "Demander"}
        </button>
      </form>

      {error ? <p className="social-status">{error}</p> : null}

      {history.map((item, index) => (
        <article className="chef-ia-answer" key={`${index}-${item.question}`}>
          <p className="chef-ia-question">« {item.question} »</p>
          <div className="chef-ia-text">{item.answer}</div>
        </article>
      ))}

      <p className="chef-ia-disclaimer">
        Réponses générées par IA : vérifiez les températures et les allergènes avant de cuisiner.
      </p>
    </section>
  );
}
