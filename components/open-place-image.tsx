"use client";

import { useEffect, useState } from "react";

export type OpenPlaceImageData = {
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

function useOpenPlaceImage(name: string, countryCode?: string | null) {
  const [image, setImage] = useState<OpenPlaceImageData | null>(null);
  const [state, setState] = useState<"loading" | "ready" | "empty">("loading");

  useEffect(() => {
    let cancelled = false;
    const params = new URLSearchParams({ name });
    if (countryCode) params.set("countryCode", countryCode);

    setState("loading");

    fetch(`/api/place-image?${params.toString()}`)
      .then(async (response) => {
        if (!response.ok) return null;
        const body = (await response.json()) as { image?: OpenPlaceImageData | null };
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
  }, [name, countryCode]);

  return { image, state };
}

export function OpenPlaceImage({
  name,
  countryCode,
  className = "",
  alt,
  showCredit = true,
}: {
  name: string;
  countryCode?: string | null;
  className?: string;
  alt?: string;
  showCredit?: boolean;
}) {
  const { image, state } = useOpenPlaceImage(name, countryCode);

  return (
    <figure className={`open-place-image ${className}`.trim()}>
      {image ? (
        <img
          src={image.thumbnailUrl || image.url}
          alt={alt || `Photo représentative de ${name}`}
          loading="lazy"
          decoding="async"
        />
      ) : (
        <div className="open-place-image-placeholder" aria-hidden="true">
          {state === "loading" ? <span className="photo-shimmer" /> : <span>🌍</span>}
        </div>
      )}

      {showCredit && image ? (
        <figcaption className="open-place-image-credit">
          <a href={image.sourcePageUrl} target="_blank" rel="noreferrer">
            {image.photographer || "Wikimedia Commons"} · {image.licenseName}
          </a>
          {image.licenseUrl ? (
            <a href={image.licenseUrl} target="_blank" rel="noreferrer" aria-label="Voir la licence">
              licence ↗
            </a>
          ) : null}
        </figcaption>
      ) : null}
    </figure>
  );
}

export function OpenCountryCard({
  name,
  countryCode,
  flag,
  dishes,
  onSelect,
}: {
  name: string;
  countryCode: string;
  flag: string;
  dishes: string;
  onSelect: () => void;
}) {
  const { image, state } = useOpenPlaceImage(name, countryCode);

  return (
    <article className="planet-country-card">
      <button
        type="button"
        className="planet-country-card-link"
        onClick={onSelect}
        aria-label={`Voir les recettes de ${name}`}
      >
        <div className="planet-country-photo">
          {image ? (
            <img
              src={image.thumbnailUrl || image.url}
              alt={`Photo représentative de ${name}`}
              loading="lazy"
              decoding="async"
            />
          ) : (
            <div className="open-place-image-placeholder" aria-hidden="true">
              {state === "loading" ? <span className="photo-shimmer" /> : <span>{flag}</span>}
            </div>
          )}
        </div>
        <div className="planet-country-card-content">
          <span className="planet-country-flag">{flag}</span>
          <div>
            <strong>{name}</strong>
            <small>{dishes}</small>
            <em>Voir les recettes →</em>
          </div>
        </div>
      </button>

      {image ? (
        <div className="planet-country-credit">
          <a href={image.sourcePageUrl} target="_blank" rel="noreferrer">
            {image.photographer || "Commons"} · {image.licenseName}
          </a>
          {image.licenseUrl ? (
            <a href={image.licenseUrl} target="_blank" rel="noreferrer" aria-label={`Licence de la photo de ${name}`}>
              ↗
            </a>
          ) : null}
        </div>
      ) : null}
    </article>
  );
}
