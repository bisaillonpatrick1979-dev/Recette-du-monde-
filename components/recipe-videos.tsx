"use client";

import Link from "next/link";
import { FormEvent, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { parseVideoLink, videoEmbedUrl, type RecipeVideo } from "@/lib/video";

const ACCEPTED = new Set(["video/mp4", "video/webm", "video/quicktime"]);
const MAX_BYTES = 100 * 1024 * 1024;

type Props = {
  recipeId: string;
  userId: string | null;
  videos: RecipeVideo[];
  available: boolean;
};

export function RecipeVideos({ recipeId, userId, videos, available }: Props) {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement | null>(null);
  const [link, setLink] = useState("");
  const [caption, setCaption] = useState("");
  const [status, setStatus] = useState("");
  const [busy, setBusy] = useState(false);

  async function addLink(event: FormEvent) {
    event.preventDefault();
    if (!userId) {
      router.push("/login");
      return;
    }
    const parsed = parseVideoLink(link);
    if (!parsed) {
      setStatus("Collez un lien YouTube ou Vimeo valide.");
      return;
    }

    setBusy(true);
    setStatus("");
    const { error } = await createClient().from("recipe_videos").insert({
      recipe_id: recipeId,
      user_id: userId,
      provider: parsed.provider,
      external_id: parsed.id,
      caption: caption.trim() || null,
    });
    setBusy(false);

    if (error) {
      setStatus(error.message);
      return;
    }
    setLink("");
    setCaption("");
    setStatus("Vidéo ajoutée. Merci !");
    router.refresh();
  }

  async function upload(file: File) {
    if (!userId) {
      router.push("/login");
      return;
    }
    if (!ACCEPTED.has(file.type)) {
      setStatus("Format non accepté. Utilisez MP4, WebM ou MOV.");
      return;
    }
    if (file.size > MAX_BYTES) {
      setStatus("La vidéo dépasse 100 Mo. Publiez-la plutôt sur YouTube et collez le lien.");
      return;
    }

    setBusy(true);
    setStatus("Envoi de la vidéo…");
    const supabase = createClient();
    const ext = file.type === "video/webm" ? "webm" : file.type === "video/quicktime" ? "mov" : "mp4";
    const path = `${userId}/${recipeId}/${crypto.randomUUID()}.${ext}`;

    const { error: uploadError } = await supabase.storage
      .from("recipe-videos")
      .upload(path, file, { contentType: file.type, upsert: false });

    if (uploadError) {
      setBusy(false);
      setStatus(uploadError.message);
      return;
    }

    const { error } = await supabase.from("recipe_videos").insert({
      recipe_id: recipeId,
      user_id: userId,
      provider: "upload",
      storage_path: path,
      caption: caption.trim() || null,
    });

    if (error) {
      await supabase.storage.from("recipe-videos").remove([path]);
      setBusy(false);
      setStatus(error.message);
      return;
    }

    setBusy(false);
    setCaption("");
    setStatus("Vidéo publiée. Merci !");
    router.refresh();
  }

  async function remove(video: RecipeVideo) {
    if (!window.confirm("Supprimer cette vidéo ?")) return;
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase.from("recipe_videos").delete().eq("id", video.id);
    setBusy(false);
    if (error) {
      setStatus(error.message);
      return;
    }
    router.refresh();
  }

  return (
    <section className="recipe-videos" aria-labelledby="recipe-videos-title">
      <span className="eyebrow">Vidéos de la communauté</span>
      <h2 id="recipe-videos-title">On la cuisine en vidéo</h2>

      {videos.length ? (
        <div className="recipe-video-grid">
          {videos.map((video) => (
            <figure className="recipe-video" key={video.id}>
              <div className="recipe-video-frame">
                {video.provider === "upload" ? (
                  video.url ? <video src={video.url} controls preload="metadata" playsInline /> : null
                ) : video.externalId ? (
                  <iframe
                    src={videoEmbedUrl(video.provider, video.externalId)}
                    title={video.caption || "Vidéo de la recette"}
                    loading="lazy"
                    allow="accelerometer; encrypted-media; gyroscope; picture-in-picture"
                    allowFullScreen
                  />
                ) : null}
              </div>
              <figcaption>
                {video.caption ? <p>{video.caption}</p> : null}
                <span>
                  Par <Link href={`/cooks/${video.authorId}`}>{video.author}</Link>
                </span>
                {video.authorId === userId ? (
                  <button type="button" className="link-button" onClick={() => void remove(video)} disabled={busy}>
                    Supprimer
                  </button>
                ) : null}
              </figcaption>
            </figure>
          ))}
        </div>
      ) : (
        <p className="muted">Aucune vidéo pour l’instant. Montrez-nous votre version !</p>
      )}

      {!available ? (
        <p className="muted">L’ajout de vidéos sera bientôt disponible.</p>
      ) : userId ? (
        <form className="recipe-video-form" onSubmit={addLink}>
          <input
            value={link}
            onChange={(event) => setLink(event.target.value)}
            placeholder="Lien YouTube ou Vimeo"
            aria-label="Lien de la vidéo"
            inputMode="url"
          />
          <input
            value={caption}
            onChange={(event) => setCaption(event.target.value)}
            placeholder="Légende (optionnel)"
            aria-label="Légende de la vidéo"
            maxLength={280}
          />
          <div className="recipe-video-actions">
            <button type="submit" className="primary-button" disabled={busy || !link.trim()}>
              Ajouter le lien
            </button>
            <button type="button" className="secondary-button" onClick={() => fileRef.current?.click()} disabled={busy}>
              📹 Téléverser une vidéo
            </button>
            <input
              ref={fileRef}
              type="file"
              accept="video/mp4,video/webm,video/quicktime"
              hidden
              onChange={(event) => {
                const file = event.target.files?.[0];
                event.target.value = "";
                if (file) void upload(file);
              }}
            />
          </div>
        </form>
      ) : (
        <p className="muted">
          <Link href="/login">Connectez-vous</Link> pour partager votre vidéo de cette recette.
        </p>
      )}

      {status ? <p className="social-status">{status}</p> : null}
    </section>
  );
}
