"use client";

import { useEffect, useState } from "react";

export type ReferenceRecipeImage = {
  url: string;
  thumbnailUrl: string;
  sourcePageUrl: string;
  title: string;
  photographer: string | null;
  licenseName: string;
  licenseUrl: string | null;
  attribution: string;
  width: number;
  height: number;
};

export function OpenRecipeImage({
  title,
  countryCode,
  className = "",
  alt,
  showCredit = true,
}: {
  title: string;
  countryCode?: string | null;
  className?: string;
  alt?: string;
  showCredit?: boolean;
}) {
  const [image, setImage] = useState<ReferenceRecipeImage | null>(null);
  const [state, setState] = useState<"loading" | "ready" | "empty">("loading");

  useEffect(() => {
    let cancelled = false;
    const params = new URLSearchParams({ title });
    if (countryCode) params.set("countryCode", countryCode);

    setState("loading");

    fetch(`/api/recipe-reference-image?${params.toString()}`)
      .then(async (response) => {
        if (!response.ok) return null;
        const body = (await response.json()) as { image?: ReferenceRecipeImage | null };
        return body.image ?? null;
      })
      .then((value) => {
        if (cancelled) return;
        setImage(value);
        setState(value ? "ready" : "empty");
      })
      .catch(() => {
        if (cancelled) return;
        setImage(null);
        setState("empty");
      });

    return () => {
      cancelled = true;
    };
  }, [title, countryCode]);

  return (
    <figure className={`open-recipe-image ${className}`.trim()}>
      {image ? (
        <img
          src={image.thumbnailUrl || image.url}
          alt={alt || `Photo de référence pour ${title}`}
          loading="lazy"
          decoding="async"
        />
      ) : (
        <div className="open-recipe-image-placeholder" aria-hidden="true">
          {state === "loading" ? <span className="photo-shimmer" /> : <span>🍽️</span>}
        </div>
      )}

      {showCredit && image ? (
        <figcaption className="open-recipe-image-credit">
          <span>Photo de référence</span>
          <a href={image.sourcePageUrl} target="_blank" rel="noreferrer">
            {image.photographer || "Wikimedia Commons"} · {image.licenseName}
          </a>
        </figcaption>
      ) : null}
    </figure>
  );
}
