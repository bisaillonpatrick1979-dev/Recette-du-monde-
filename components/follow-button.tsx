"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

type Props = {
  profileId: string;
  viewerId: string | null;
  initialFollowing: boolean;
  initialFollowers: number;
};

export function FollowButton({ profileId, viewerId, initialFollowing, initialFollowers }: Props) {
  const router = useRouter();
  const [following, setFollowing] = useState(initialFollowing);
  const [followers, setFollowers] = useState(initialFollowers);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  if (viewerId === profileId) return null;

  async function toggle() {
    if (!viewerId) {
      router.push("/login");
      return;
    }
    if (busy) return;

    setBusy(true);
    setError("");
    const supabase = createClient();
    const { error: requestError } = following
      ? await supabase.from("follows").delete().eq("follower_id", viewerId).eq("following_id", profileId)
      : await supabase.from("follows").insert({ follower_id: viewerId, following_id: profileId });
    setBusy(false);

    if (requestError) {
      setError(requestError.message);
      return;
    }
    setFollowing(!following);
    setFollowers((count) => Math.max(0, count + (following ? -1 : 1)));
    router.refresh();
  }

  return (
    <div className="follow-control">
      <button
        type="button"
        className={following ? "secondary-button" : "primary-button"}
        onClick={() => void toggle()}
        disabled={busy}
        aria-pressed={following}
      >
        {following ? "✓ Abonné" : "+ Suivre"}
      </button>
      <small>{followers.toLocaleString("fr-CA")} abonné{followers > 1 ? "s" : ""}</small>
      {error ? <small className="social-status">{error}</small> : null}
    </div>
  );
}
