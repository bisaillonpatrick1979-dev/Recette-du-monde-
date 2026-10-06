"use client";

// Bloquer / débloquer un membre : ses commentaires, vidéos et « je l'ai cuisinée » sont masqués
// pour vous, et il ne peut plus vous envoyer de notifications.

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export function BlockButton({
  profileId,
  viewerId,
  initialBlocked,
  className = "link-button",
  onBlocked,
}: {
  profileId: string;
  viewerId: string | null;
  initialBlocked: boolean;
  className?: string;
  onBlocked?: (profileId: string) => void;
}) {
  const router = useRouter();
  const [blocked, setBlocked] = useState(initialBlocked);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  if (viewerId === profileId) return null;

  async function toggle() {
    if (!viewerId) {
      router.push("/login");
      return;
    }
    if (busy) return;
    if (!blocked && !window.confirm("Bloquer ce membre ? Vous ne verrez plus ses commentaires ni ses vidéos.")) return;

    setBusy(true);
    setError("");
    const supabase = createClient();
    const { error: requestError } = blocked
      ? await supabase.from("user_blocks").delete().eq("blocker_id", viewerId).eq("blocked_id", profileId)
      : await supabase.from("user_blocks").insert({ blocker_id: viewerId, blocked_id: profileId });
    setBusy(false);

    if (requestError) {
      setError("Action impossible pour le moment.");
      return;
    }
    const nowBlocked = !blocked;
    setBlocked(nowBlocked);
    if (nowBlocked) onBlocked?.(profileId);
    router.refresh();
  }

  return (
    <>
      <button type="button" className={className} onClick={() => void toggle()} disabled={busy} aria-pressed={blocked}>
        {blocked ? "Débloquer" : "Bloquer"}
      </button>
      {error ? <small className="social-status">{error}</small> : null}
    </>
  );
}
