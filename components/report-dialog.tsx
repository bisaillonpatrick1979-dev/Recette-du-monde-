"use client";

// Bouton « Signaler » + petite fenêtre de signalement (recette, commentaire ou membre).
// Les signalements arrivent dans la table content_reports, visible seulement par l'équipe.

import { FormEvent, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { Database } from "@/lib/supabase/database.types";

type Reason = Database["public"]["Enums"]["report_reason"];

const REASONS: Array<{ value: Reason; label: string }> = [
  { value: "spam", label: "Pourriel ou publicité" },
  { value: "abuse", label: "Propos haineux, harcèlement ou insulte" },
  { value: "unsafe", label: "Instruction dangereuse pour la santé" },
  { value: "misinformation", label: "Information fausse ou trompeuse" },
  { value: "copyright", label: "Photo ou texte copié sans permission" },
  { value: "other", label: "Autre raison" },
];

type Target =
  | { kind: "recipe"; id: string }
  | { kind: "comment"; id: string }
  | { kind: "user"; id: string };

const TARGET_LABEL: Record<Target["kind"], string> = {
  recipe: "cette recette",
  comment: "ce commentaire",
  user: "ce membre",
};

export function ReportDialog({
  target,
  viewerId,
  label = "Signaler",
  className = "link-button",
}: {
  target: Target;
  viewerId: string | null;
  label?: string;
  className?: string;
}) {
  const router = useRouter();
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [reason, setReason] = useState<Reason>("spam");
  const [details, setDetails] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [sent, setSent] = useState(false);

  function open() {
    if (!viewerId) {
      router.push("/login");
      return;
    }
    setMessage("");
    dialogRef.current?.showModal();
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!viewerId || busy) return;
    setBusy(true);
    setMessage("");

    const supabase = createClient();
    const { error } = await supabase.from("content_reports").insert({
      reporter_id: viewerId,
      reason,
      details: details.trim() || null,
      recipe_id: target.kind === "recipe" ? target.id : null,
      comment_id: target.kind === "comment" ? target.id : null,
      reported_user_id: target.kind === "user" ? target.id : null,
    });
    setBusy(false);

    if (error) {
      setMessage("Le signalement n’a pas pu être envoyé. Réessayez dans un instant.");
      return;
    }
    setSent(true);
    setDetails("");
    dialogRef.current?.close();
  }

  return (
    <>
      <button type="button" className={className} onClick={open} disabled={sent}>
        {sent ? "Signalé ✓" : label}
      </button>
      <dialog ref={dialogRef} className="report-dialog" aria-label={`Signaler ${TARGET_LABEL[target.kind]}`}>
        <form onSubmit={submit}>
          <h3>Signaler {TARGET_LABEL[target.kind]}</h3>
          <p className="muted">Votre signalement est confidentiel. L’équipe Spoontrotter le vérifiera.</p>
          <fieldset>
            <legend>Raison</legend>
            {REASONS.map((item) => (
              <label key={item.value}>
                <input
                  type="radio"
                  name="reason"
                  value={item.value}
                  checked={reason === item.value}
                  onChange={() => setReason(item.value)}
                />
                {item.label}
              </label>
            ))}
          </fieldset>
          <label className="report-details">
            Précisions (facultatif)
            <textarea
              value={details}
              onChange={(event) => setDetails(event.target.value)}
              maxLength={1000}
              rows={3}
            />
          </label>
          {message ? <p className="social-status">{message}</p> : null}
          <div className="report-actions">
            <button type="button" className="ghost-button" onClick={() => dialogRef.current?.close()}>
              Annuler
            </button>
            <button type="submit" className="primary-button" disabled={busy}>
              {busy ? "Envoi…" : "Envoyer le signalement"}
            </button>
          </div>
        </form>
      </dialog>
    </>
  );
}
