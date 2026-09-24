export type VideoProvider = "youtube" | "vimeo" | "upload";

export type RecipeVideo = {
  id: string;
  provider: VideoProvider;
  externalId: string | null;
  url: string | null;
  storagePath: string | null;
  caption: string | null;
  author: string;
  authorId: string;
  createdAt: string;
};

// Reconnaît un lien YouTube (watch, youtu.be, shorts, embed) ou Vimeo.
export function parseVideoLink(raw: string): { provider: "youtube" | "vimeo"; id: string } | null {
  let url: URL;
  try {
    url = new URL(raw.trim());
  } catch {
    return null;
  }

  const host = url.hostname.replace(/^www\.|^m\./, "");
  if (host === "youtu.be") {
    const id = url.pathname.slice(1).split("/")[0];
    return /^[A-Za-z0-9_-]{6,20}$/.test(id) ? { provider: "youtube", id } : null;
  }
  if (host === "youtube.com" || host === "youtube-nocookie.com") {
    const fromQuery = url.searchParams.get("v");
    const fromPath = url.pathname.match(/^\/(?:shorts|embed|live)\/([A-Za-z0-9_-]{6,20})/)?.[1];
    const id = fromQuery || fromPath;
    return id && /^[A-Za-z0-9_-]{6,20}$/.test(id) ? { provider: "youtube", id } : null;
  }
  if (host === "vimeo.com" || host === "player.vimeo.com") {
    const id = url.pathname.match(/(\d{6,12})/)?.[1];
    return id ? { provider: "vimeo", id } : null;
  }
  return null;
}

export function videoEmbedUrl(provider: VideoProvider, externalId: string) {
  return provider === "youtube"
    ? `https://www.youtube-nocookie.com/embed/${externalId}`
    : `https://player.vimeo.com/video/${externalId}`;
}
