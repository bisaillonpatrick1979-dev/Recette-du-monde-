"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import type { Map as MapLibreMap, Marker } from "maplibre-gl";
import {
  levelLabels,
  type AtlasRecipe,
  type CulinaryPlace,
} from "@/lib/culinary-places";

const STYLE_URL = "https://tiles.openfreemap.org/styles/liberty";

type Props = {
  places: CulinaryPlace[];
  recipes: AtlasRecipe[];
  dataError?: string | null;
};

export function CulinaryGlobe({ places, recipes, dataError = null }: Props) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<MapLibreMap | null>(null);
  const markersRef = useRef<Marker[]>([]);
  const initialPlace = places.find((place) => place.slug === "id-bali") ?? places[0] ?? null;
  const [selectedId, setSelectedId] = useState<string | null>(initialPlace?.id ?? null);
  const [query, setQuery] = useState("");
  const [mapState, setMapState] = useState<"loading" | "ready" | "error">("loading");

  const placeById = useMemo(
    () => new Map(places.map((place) => [place.id, place])),
    [places],
  );

  const selected = (selectedId ? placeById.get(selectedId) : null) ?? initialPlace;

  function descendantIds(placeId: string) {
    const ids = new Set<string>([placeId]);
    let changed = true;

    while (changed) {
      changed = false;
      for (const place of places) {
        if (place.parentId && ids.has(place.parentId) && !ids.has(place.id)) {
          ids.add(place.id);
          changed = true;
        }
      }
    }

    return ids;
  }

  function placePath(place: CulinaryPlace) {
    const path: CulinaryPlace[] = [];
    const visited = new Set<string>();
    let current: CulinaryPlace | undefined = place;

    while (current && !visited.has(current.id)) {
      visited.add(current.id);
      path.push(current);
      current = current.parentId ? placeById.get(current.parentId) : undefined;
    }

    return path.reverse();
  }

  const selectedPlaceIds = useMemo(
    () => (selected ? descendantIds(selected.id) : new Set<string>()),
    [selected, places],
  );

  const selectedRecipes = useMemo(
    () => recipes.filter((recipe) => selectedPlaceIds.has(recipe.placeId)),
    [recipes, selectedPlaceIds],
  );

  const childPlaces = useMemo(
    () => (selected ? places.filter((place) => place.parentId === selected.id) : []),
    [places, selected],
  );

  const filteredPlaces = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase("fr");
    if (!normalized) return places;

    const matchingRecipePlaceIds = new Set(
      recipes
        .filter((recipe) =>
          [recipe.title, recipe.category ?? "", recipe.description ?? ""]
            .join(" ")
            .toLocaleLowerCase("fr")
            .includes(normalized),
        )
        .map((recipe) => recipe.placeId),
    );

    return places.filter((place) => {
      const path = placePath(place).map((item) => item.name).join(" ");
      return (
        [place.name, place.countryCode, path]
          .join(" ")
          .toLocaleLowerCase("fr")
          .includes(normalized) ||
        matchingRecipePlaceIds.has(place.id)
      );
    });
  }, [query, places, recipes, placeById]);

  useEffect(() => {
    let cancelled = false;

    async function initMap() {
      if (!containerRef.current || mapRef.current || places.length === 0) {
        if (places.length === 0) setMapState("error");
        return;
      }

      try {
        const maplibre = await import("maplibre-gl");
        if (cancelled || !containerRef.current) return;

        maplibre.setWorkerUrl("/maplibre/maplibre-gl-worker.mjs");

        const map = new maplibre.Map({
          container: containerRef.current,
          style: STYLE_URL,
          center: [15, 10],
          zoom: 1.35,
          minZoom: 1,
          maxZoom: 16,
        });

        map.addControl(new maplibre.NavigationControl({ visualizePitch: true }), "top-right");
        map.addControl(new maplibre.GlobeControl(), "top-right");

        map.on("style.load", () => {
          map.setProjection({ type: "globe" });
        });

        map.on("load", () => {
          if (cancelled) return;

          for (const place of places) {
            const markerButton = document.createElement("button");
            markerButton.type = "button";
            markerButton.className = `culinary-map-marker marker-${place.placeType}`;
            markerButton.setAttribute("aria-label", `Explorer ${place.name}`);
            markerButton.title = placePath(place).map((item) => item.name).join(" › ");
            markerButton.innerHTML = "<span>🍴</span>";

            markerButton.addEventListener("click", () => {
              setSelectedId(place.id);
              map.flyTo({
                center: [place.longitude, place.latitude],
                zoom: place.zoom,
                essential: true,
              });
            });

            const marker = new maplibre.Marker({ element: markerButton, anchor: "bottom" })
              .setLngLat([place.longitude, place.latitude])
              .addTo(map);

            markersRef.current.push(marker);
          }

          setMapState("ready");
          map.resize();
        });

        map.on("error", (event) => {
          if (event.error) {
            console.error("Culinary globe map error", event.error);
          }
        });

        mapRef.current = map;
      } catch (error) {
        console.error("Unable to initialize culinary globe", error);
        if (!cancelled) setMapState("error");
      }
    }

    void initMap();

    return () => {
      cancelled = true;
      markersRef.current.forEach((marker) => marker.remove());
      markersRef.current = [];
      mapRef.current?.remove();
      mapRef.current = null;
    };
  }, [places]);

  function focusPlace(place: CulinaryPlace) {
    setSelectedId(place.id);
    mapRef.current?.flyTo({
      center: [place.longitude, place.latitude],
      zoom: place.zoom,
      essential: true,
    });
  }

  function resetWorld() {
    mapRef.current?.flyTo({ center: [15, 10], zoom: 1.35, essential: true });
  }

  return (
    <section className="atlas-shell" aria-labelledby="atlas-title">
      <div className="atlas-toolbar">
        <div>
          <span className="eyebrow">Globetrotter culinaire</span>
          <h1 id="atlas-title">Explorez le monde par ses cuisines</h1>
          <p>
            Tournez le globe, zoomez d’un pays vers une région, une île ou une ville,
            puis découvrez les recettes réellement reliées à cette zone.
          </p>
        </div>
        <Link className="ghost-button" href="/">← Accueil</Link>
      </div>

      {dataError ? (
        <p className="form-alert error">
          Certaines données de l’atlas n’ont pas pu être chargées : {dataError}
        </p>
      ) : null}

      <div className="atlas-search-row">
        <label className="atlas-search">
          <span>Rechercher un lieu ou un plat</span>
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Ex. Sud-Kivu, Bali, Ubud, Oaxaca…"
          />
        </label>
        <button type="button" className="secondary-button" onClick={resetWorld}>
          Voir le monde
        </button>
      </div>

      <div className="atlas-layout">
        <div className="atlas-map-panel">
          <div ref={containerRef} className="atlas-map" aria-label="Globe culinaire interactif" />
          {mapState === "loading" && <div className="atlas-map-message">Chargement du globe…</div>}
          {mapState === "error" && (
            <div className="atlas-map-message error">
              Le globe 3D n’est pas disponible. Utilisez la liste des lieux pour explorer.
            </div>
          )}
          <div className="atlas-map-hint">
            <strong>Astuce :</strong> pincez pour zoomer, glissez pour tourner le globe et touchez 🍴 pour ouvrir un lieu.
          </div>
        </div>

        <aside className="atlas-detail" aria-live="polite">
          {selected ? (
            <>
              <div className="place-level">{levelLabels[selected.placeType]}</div>
              <h2>{selected.name}</h2>
              <p className="place-parent">
                {placePath(selected).map((place) => place.name).join(" › ")}
              </p>
              <p>{selected.summary || "Explorez les recettes reliées à cette zone."}</p>

              {childPlaces.length > 0 ? (
                <div className="place-examples">
                  <span>Descendre plus précisément</span>
                  {childPlaces.map((place) => (
                    <button type="button" key={place.id} onClick={() => focusPlace(place)}>
                      {levelLabels[place.placeType]} · {place.name}
                    </button>
                  ))}
                </div>
              ) : null}

              <div className="atlas-recipes">
                <div className="atlas-recipes-heading">
                  <span>Recettes dans cette zone</span>
                  <strong>{selectedRecipes.length}</strong>
                </div>
                {selectedRecipes.length ? (
                  <div className="atlas-recipe-list">
                    {selectedRecipes.slice(0, 8).map((recipe) => (
                      <Link href={`/recipes/${recipe.id}`} key={`${recipe.id}-${recipe.placeId}`}>
                        <span>{recipe.category || "Recette"}</span>
                        <strong>{recipe.title}</strong>
                      </Link>
                    ))}
                  </div>
                ) : (
                  <p className="atlas-empty">
                    Aucune recette publiée n’est encore reliée à cette zone. Les prochaines recettes
                    ajoutées ici apparaîtront automatiquement.
                  </p>
                )}
              </div>

              <div className="atlas-note">
                Quand vous choisissez un pays ou une région, les recettes de toutes ses sous-régions
                et villes sont incluses automatiquement.
              </div>
            </>
          ) : (
            <p>Aucun lieu n’est encore disponible.</p>
          )}
        </aside>
      </div>

      <div className="place-browser">
        <div className="section-heading">
          <div>
            <span className="eyebrow">Atlas connecté à Supabase</span>
            <h2>Du pays jusqu’à la ville</h2>
          </div>
          <span>{filteredPlaces.length} lieu{filteredPlaces.length > 1 ? "x" : ""}</span>
        </div>
        <div className="place-grid">
          {filteredPlaces.map((place) => (
            <button
              type="button"
              key={place.id}
              className={`place-card ${selected?.id === place.id ? "active" : ""}`}
              onClick={() => focusPlace(place)}
            >
              <span className="place-card-level">{levelLabels[place.placeType]}</span>
              <strong>{place.name}</strong>
              <small>{placePath(place).map((item) => item.name).join(" › ")}</small>
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
