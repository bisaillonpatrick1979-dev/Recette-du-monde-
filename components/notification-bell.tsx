"use client";

// Lien vers /notifications avec le nombre de notifications non lues (membres connectés seulement).

import Link from "next/link";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";

export function NotificationBell({ className = "ghost-button" }: { className?: string }) {
  const [signedIn, setSignedIn] = useState(false);
  const [unread, setUnread] = useState(0);

  useEffect(() => {
    let cancelled = false;
    const supabase = createClient();

    async function load() {
      const { data } = await supabase.auth.getClaims();
      const userId = data?.claims?.sub;
      if (cancelled || typeof userId !== "string") return;
      setSignedIn(true);

      const { count } = await supabase
        .from("notifications")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .is("read_at", null);
      if (!cancelled) setUnread(count ?? 0);
    }

    void load();
    return () => {
      cancelled = true;
    };
  }, []);

  if (!signedIn) return null;

  const label = unread > 0 ? `Notifications (${unread} non lue${unread > 1 ? "s" : ""})` : "Notifications";

  return (
    <Link href="/notifications" className={`${className} notification-bell`} aria-label={label} title={label}>
      <span aria-hidden="true">🔔</span>
      {unread > 0 ? <span className="notification-badge">{unread > 99 ? "99+" : unread}</span> : null}
    </Link>
  );
}
