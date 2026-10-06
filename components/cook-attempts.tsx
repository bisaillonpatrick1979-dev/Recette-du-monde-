"use client";

// « Je l'ai cuisinée » : les membres indiquent qu'ils ont fait la recette, avec un mot facultatif
// (astuce, variante, résultat). Table cook_attempts.

import Link from "next/link";
import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export type CookAttempt = {
  id: string;
  authorId: string;
  author: string;
  note: string | null;
  createdAt: string;
};

function formatDate(value: string) {
  return new Date(value).toLocaleDateString("fr-CA", { day: "numeric", month: "short", year: "numeric" });
}

export function CookAttempts({
  recipeId,
  viewerId,
  initialAttempts,
  initialTotal,
}: {
  recipeId: string;
  viewerId: string | null;
  initialAttempts: CookAttempt[];
  initialTotal: number;
}) {
  const router = useRouter();
  const [attempts, setAttempts] = useState(initialAttempts);
  const [total, setTotal] = useState(initialTotal);
  const [open, setOpen] = useState(false);
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const alreadyCooked = Boolean(viewerId && attempts.some((attempt) => attempt.authorId === viewerId));

  function start() {
    if (!viewerId) {
      router.push("/login");
      return;
    }
    setOpen(true);
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!viewerId || busy) return;

    setBusy(true);
    setError("");
    const supabase = createClient();
    const { data, error: requestError } = await supabase
      .from("cook_attempts")
      .insert({ recipe_id: recipeId, user_id: viewerId, note: note.trim() || null })
      .select("id,note,created_at")
      .single();

    if (requestError || !data) {
      setBusy(false);
      setError("Impossible d’enregistrer pour le moment.");
      return;
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("display_name,username")
      .eq("id", viewerId)
      .maybeSingle();

    setAttempts((items) => [
      {
        id: data.id,
        authorId: viewerId,
        author: profile?.display_name || profile?.username || "Vous",
        note: data.note,
        createdAt: data.created_at,
      },
      ...items,
    ]);
    setTotal((value) => value + 1);
    setNote("");
    setOpen(false);
    setBusy(false);
  }

  async function remove(attemptId: string) {
    if (!viewerId || busy || !window.confirm("Retirer cette mention ?")) return;
    setBusy(true);
    const supabase = createClient();
    const { error: requestError } = await supabase
      .from("cook_attempts")
      .delete()
      .eq("id", attemptId)
      .eq("user_id", viewerId);
    setBusy(false);
    if (requestError) {
      setError("Impossible de retirer cette mention.");
      return;
    }
    setAttempts((items) => items.filter((item) => item.id !== attemptId));
    setTotal((value) => Math.max(0, value - 1));
  }

  return (
    <section className="cook-attempts" aria-labelledby="cook-attempts-title">
      <div className="cook-attempts-head">
        <div>
          <span className="eyebrow">Dans les cuisines du monde</span>
          <h2 id="cook-attempts-title">
            {total > 0
              ? `${total.toLocaleString("fr-CA")} membre${total > 1 ? "s l’ont" : " l’a"} cuisinée`
              : "Soyez la première personne à la cuisiner"}
          </h2>
        </div>
        {!open ? (
          <button type="button" className={alreadyCooked ? "secondary-button" : "primary-button"} onClick={start}>
            {alreadyCooked ? "🍽 Je l’ai refaite" : "🍽 Je l’ai cuisinée"}
          </button>
        ) : null}
      </div>

      {open ? (
        <form className="cook-attempt-form" onSubmit={submit}>
          <label>
            Un mot sur votre résultat ? (facultatif)
            <textarea
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder="Astuce, variante, temps de cuisson ajusté…"
              maxLength={1000}
              rows={3}
            />
          </label>
          <div className="report-actions">
            <button type="button" className="ghost-button" onClick={() => setOpen(false)}>Annuler</button>
            <button type="submit" className="primary-button" disabled={busy}>{busy ? "Envoi…" : "Publier"}</button>
          </div>
        </form>
      ) : null}

      {error ? <p className="social-status">{error}</p> : null}

      {attempts.length ? (
        <ul className="cook-attempt-list">
          {attempts.map((attempt) => (
            <li key={attempt.id}>
              <div className="comment-meta">
                <Link href={`/cooks/${attempt.authorId}`}><strong>{attempt.author}</strong></Link>
                <time dateTime={attempt.createdAt}>{formatDate(attempt.createdAt)}</time>
                {attempt.authorId === viewerId ? (
                  <button type="button" className="link-button" onClick={() => void remove(attempt.id)} disabled={busy}>
                    Retirer
                  </button>
                ) : null}
              </div>
              {attempt.note ? <p>{attempt.note}</p> : null}
            </li>
          ))}
        </ul>
      ) : null}
    </section>
  );
}
