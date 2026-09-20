export type MediaLike = {
  storage_path: string | null;
  external_url: string | null;
};

function encodeStoragePath(path: string) {
  return path
    .split("/")
    .map((segment) => encodeURIComponent(segment))
    .join("/");
}

export function publicStorageUrl(bucket: string, path: string) {
  const base = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!base) return null;
  return `${base}/storage/v1/object/public/${encodeURIComponent(bucket)}/${encodeStoragePath(path)}`;
}

export function resolveMediaUrl(media: MediaLike, bucket: string) {
  if (media.external_url) return media.external_url;
  if (media.storage_path) return publicStorageUrl(bucket, media.storage_path);
  return null;
}

export function mediaSourceLabel(sourceType: "external_licensed" | "generated" | "user_uploaded") {
  if (sourceType === "generated") return "Image illustrative générée";
  if (sourceType === "external_licensed") return "Photo licenciée";
  return "Photo de l’auteur";
}
