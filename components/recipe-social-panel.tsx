"use client";

import Link from "next/link";
import { FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

type SocialComment = {
  id: string;
  authorId: string;
  author: string;
  body: string;
  createdAt: string;
};

function formatDate(value: string) {
  return new Date(value).toLocaleDateString("fr-CA", { day: "numeric", month: "short", year: "numeric" });
}

type Props = {
  recipeId: string;
  initialLikes: number;
  initialLiked: boolean;
  initialRating: number | null;
  initialRatingCount: number;
  initialUserRating: number | null;
  initialComments: SocialComment[];
  currentUserId: string | null;
};

export function RecipeSocialPanel({
  recipeId,
  initialLikes,
  initialLiked,
  initialRating,
  initialRatingCount,
  initialUserRating,
  initialComments,
  currentUserId,
}: Props) {
  const router = useRouter();
  const [likes, setLikes] = useState(initialLikes);
  const [liked, setLiked] = useState(initialLiked);
  const [rating, setRating] = useState(initialRating);
  const [ratingCount, setRatingCount] = useState(initialRatingCount);
  const [userRating, setUserRating] = useState(initialUserRating);
  const [comments, setComments] = useState(initialComments);
  const [comment, setComment] = useState("");
  const [status, setStatus] = useState("");
  const [busy, setBusy] = useState(false);

  const ratingLabel = useMemo(
    () => (rating == null ? "Pas encore notée" : `${rating.toFixed(1)} / 5`),
    [rating],
  );

  async function requireUser() {
    const supabase = createClient();
    const { data } = await supabase.auth.getUser();
    if (!data.user) {
      router.push("/login");
      return null;
    }
    return { supabase, user: data.user };
  }

  async function toggleLike() {
    if (busy) return;
    const auth = await requireUser();
    if (!auth) return;

    setBusy(true);
    setStatus("");

    if (liked) {
      const { error } = await auth.supabase
        .from("recipe_likes")
        .delete()
        .eq("recipe_id", recipeId)
        .eq("user_id", auth.user.id);

      if (error) {
        setStatus(error.message);
      } else {
        setLiked(false);
        setLikes((value) => Math.max(0, value - 1));
      }
    } else {
      const { error } = await auth.supabase.from("recipe_likes").insert({
        recipe_id: recipeId,
        user_id: auth.user.id,
      });

      if (error) {
        setStatus(error.message);
      } else {
        setLiked(true);
        setLikes((value) => value + 1);
      }
    }

    setBusy(false);
  }

  async function rate(value: number) {
    if (busy) return;
    const auth = await requireUser();
    if (!auth) return;

    setBusy(true);
    setStatus("");

    const { error } = await auth.supabase.from("recipe_ratings").upsert(
      {
        recipe_id: recipeId,
        user_id: auth.user.id,
        rating: value,
      },
      { onConflict: "recipe_id,user_id" },
    );

    if (error) {
      setStatus(error.message);
      setBusy(false);
      return;
    }

    const { data: latest } = await auth.supabase
      .from("recipe_ratings")
      .select("rating")
      .eq("recipe_id", recipeId);

    const values = latest ?? [];
    setRatingCount(values.length);
    setRating(values.length ? values.reduce((sum, row) => sum + row.rating, 0) / values.length : null);
    setUserRating(value);
    setBusy(false);
  }

  async function submitComment(event: FormEvent) {
    event.preventDefault();
    const body = comment.trim();
    if (!body || busy) return;

    const auth = await requireUser();
    if (!auth) return;

    setBusy(true);
    setStatus("");

    const { data, error } = await auth.supabase
      .from("recipe_comments")
      .insert({
        recipe_id: recipeId,
        user_id: auth.user.id,
        body,
        language_code: "fr",
      })
      .select("id,body,created_at")
      .single();

    if (error || !data) {
      setStatus(error?.message || "Impossible d’ajouter le commentaire.");
      setBusy(false);
      return;
    }

    const { data: profile } = await auth.supabase
      .from("profiles")
      .select("display_name,username")
      .eq("id", auth.user.id)
      .maybeSingle();

    setComments((items) => [
      {
        id: data.id,
        authorId: auth.user.id,
        author: profile?.display_name || profile?.username || "Vous",
        body: data.body,
        createdAt: data.created_at,
      },
      ...items,
    ]);
    setComment("");
    setBusy(false);
  }

  async function deleteComment(commentId: string) {
    if (busy || !window.confirm("Supprimer ce commentaire ?")) return;
    const auth = await requireUser();
    if (!auth) return;

    setBusy(true);
    const { error } = await auth.supabase
      .from("recipe_comments")
      .update({ deleted_at: new Date().toISOString() })
      .eq("id", commentId)
      .eq("user_id", auth.user.id);
    setBusy(false);

    if (error) {
      setStatus(error.message);
      return;
    }
    setComments((items) => items.filter((item) => item.id !== commentId));
  }

  return (
    <section className="recipe-social-panel">
      <span className="eyebrow">Communauté</span>
      <h2>Vous l’avez cuisinée ?</h2>
      <div className="recipe-social-summary">
        <span>♥ {likes} j’aime</span>
        <span>★ {ratingLabel} ({ratingCount})</span>
        <span>💬 {comments.length} commentaires</span>
      </div>

      <div className="recipe-social-actions">
        <button
          type="button"
          className={liked ? "like-toggle active" : "like-toggle"}
          onClick={() => void toggleLike()}
          disabled={busy}
        >
          {liked ? "♥ Aimée" : "♡ J’aime"}
        </button>

        <div className="rating-row" aria-label="Noter cette recette">
          <strong>Votre note :</strong>
          {[1, 2, 3, 4, 5].map((value) => (
            <button
              key={value}
              type="button"
              className={userRating != null && value <= userRating ? "active" : ""}
              onClick={() => void rate(value)}
              disabled={busy}
              aria-label={`${value} étoile${value > 1 ? "s" : ""}`}
            >
              ★
            </button>
          ))}
        </div>
      </div>

      <form className="comment-form" onSubmit={submitComment}>
        <input
          value={comment}
          onChange={(event) => setComment(event.target.value)}
          placeholder="Posez une question ou partagez votre expérience…"
          maxLength={1000}
        />
        <button type="submit" disabled={busy || !comment.trim()}>Commenter</button>
      </form>

      {status ? <p className="social-status">{status}</p> : null}

      <div className="comment-list">
        {comments.slice(0, 20).map((item) => (
          <article className="comment-item" key={item.id}>
            <div className="comment-meta">
              <Link href={`/cooks/${item.authorId}`}><strong>{item.author}</strong></Link>
              <time dateTime={item.createdAt}>{formatDate(item.createdAt)}</time>
              {item.authorId === currentUserId ? (
                <button type="button" className="link-button" onClick={() => void deleteComment(item.id)} disabled={busy}>
                  Supprimer
                </button>
              ) : null}
            </div>
            <p>{item.body}</p>
          </article>
        ))}
      </div>
    </section>
  );
}
