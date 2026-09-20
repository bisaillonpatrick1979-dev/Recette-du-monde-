"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

type Props = {
  recipeId: string;
  userId: string;
  recipeTitle: string;
  hasPrimaryImage: boolean;
};

const ACCEPTED = new Set(["image/jpeg", "image/png", "image/webp", "image/avif"]);
const MAX_BYTES = 10 * 1024 * 1024;

function extensionFor(file: File) {
  const ext = file.name.split(".").pop()?.toLowerCase();
  if (ext && ["jpg", "jpeg", "png", "webp", "avif"].includes(ext)) return ext === "jpeg" ? "jpg" : ext;
  if (file.type === "image/png") return "png";
  if (file.type === "image/webp") return "webp";
  if (file.type === "image/avif") return "avif";
  return "jpg";
}

export function RecipePhotoUploader({ recipeId, userId, recipeTitle, hasPrimaryImage }: Props) {
  const router = useRouter();
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [status, setStatus] = useState<string>("");
  const [busy, setBusy] = useState(false);

  async function upload(file: File) {
    if (!ACCEPTED.has(file.type)) {
      setStatus("Format non accepté. Utilisez JPG, PNG, WebP ou AVIF.");
      return;
    }
    if (file.size > MAX_BYTES) {
      setStatus("La photo dépasse 10 Mo.");
      return;
    }

    setBusy(true);
    setStatus("Envoi de la photo…");

    const supabase = createClient();
    const ext = extensionFor(file);
    const path = `${userId}/${recipeId}/${crypto.randomUUID()}.${ext}`;

    const { error: uploadError } = await supabase.storage
      .from("recipe-images")
      .upload(path, file, {
        cacheControl: "3600",
        contentType: file.type,
        upsert: false,
      });

    if (uploadError) {
      setBusy(false);
      setStatus(uploadError.message);
      return;
    }

    const { error: rowError } = await supabase.from("recipe_images").insert({
      recipe_id: recipeId,
      source_type: "user_uploaded",
      status: "ready",
      storage_path: path,
      alt_text: recipeTitle,
      is_primary: !hasPrimaryImage,
      is_representative: true,
      created_by: userId,
    });

    if (rowError) {
      await supabase.storage.from("recipe-images").remove([path]);
      setBusy(false);
      setStatus(rowError.message);
      return;
    }

    setBusy(false);
    setStatus("Photo ajoutée.");
    if (inputRef.current) inputRef.current.value = "";
    router.refresh();
  }

  return (
    <div className="recipe-photo-uploader">
      <div>
        <strong>Ajouter une photo du plat</strong>
        <small>JPG, PNG, WebP ou AVIF · maximum 10 Mo</small>
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/avif"
        disabled={busy}
        onChange={(event) => {
          const file = event.target.files?.[0];
          if (file) void upload(file);
        }}
      />
      {status ? <p className="upload-status" aria-live="polite">{status}</p> : null}
    </div>
  );
}
