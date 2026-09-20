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

type MapPick = {
  name: string;
  placeClass: string;
  longitude: number;
  latitude: number;
};

function normalizeName(value: string) {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLocaleLowerCase("fr")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function labelForMapClass(placeClass: string) {
  const labels: Record<string, string> = {
    country: "Pays",
    state: "Région",
    province: "Province",
    island: "Île",
    city: "Ville",
    town: "Ville",
    village: "Village",
    hamlet: "Localité",
    borough: "Arrondissement",
    suburb: "Quartier",
    quarter: "Quartier",
    neighbourhood: "Quartier",
  };
  return labels[placeClass] ?? "Lieu";
}

function featureName(properties: Record<string, unknown> | null | undefined) {
  if (!properties) return null;
  const candidates = [
    properties.name_fr,
    properties.name_en,
    properties["name:latin"],
    properties.name,
  ];
  return candidates.find((value): value is string => typeof value === "string" && value.trim().length > 0) ?? null;
}

export function CulinaryGlobe({ places, recipes, dataError = null }: Props) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<MapLibreMap | null>(null);
  const markersRef = useRef<Marker[]>([]);
  const initialPlace = places.find((place) => place.slug === "id-bali") ?? places[0] ?? null;
  const [selectedId, setSelectedId] = useState<string | null>(initialPlace?.id ?? null);
  const [mapPick, setMapPick] = useState<MapPick | null>(null);
  const [query, setQuery] = useState("");
  const [mapState, setMapState] = useState<"loading" | "ready" | "error">("loading");

  const placeById = useMemo(
    () => new Map(places.map((place) => [place.id, place])),
    [places],
  );

  const selected = mapPick ? null : ((selectedId ? placeById.get(selectedId) : null) ?? initialPlace);

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
    const normalized = normalizeName(query);
    if (!normalized) return [];

    const matchingRecipePlaceIds = new Set(
      recipes
        .filter((recipe) =>
          normalizeName([recipe.title, recipe.category ?? "", recipe.description ?? ""].join(" ")).includes(normalized),
        )
        .map((recipe) => recipe.placeId),
    );

    return places
      .filter((place) => {
        const path = placePath(place).map((item) => item.name).join(" ");
        return (
          normalizeName([place.name, place.countryCode, path].join(" ")).includes(normalized) ||
          matchingRecipePlaceIds.has(place.id)
        );
      })
      .slice(0, 8);
  }, [query, places, recipes, placeById]);

  function findDatabasePlace(name: string, placeClass: string) {
    const normalized = normalizeName(name);
    const matchingTypes =
      placeClass === "country"
        ? new Set(["country"])
        : placeClass === "state" || placeClass === "province"
          ? new Set(["region"])
          : placeClass === "island"
            ? new Set(["island"])
            : new Set(["city", "locality"]);

    return (
      places.find(
        (place) =>
          matchingTypes.has(place.placeType) &&
          normalizeName(place.name) === normalized,
      ) ??
      places.find((place) => normalizeName(place.name) === normalized) ??
      null
    );
  }

  function useMapFeature(
    name: string,
    placeClass: string,
    longitude: number,
    latitude: number,
  ) {
    const databaseMatch = findDatabasePlace(name, placeClass);

    if (databaseMatch) {
      setMapPick(null);
      setSelectedId(databaseMatch.id);
      return;
    }

    setSelectedId(null);
    setMapPick({ name, placeClass, longitude, latitude });
  }

  useEffect(() => {
    let cancelled = false;

    async function initMap() {
      if (!containerRef.current || mapRef.current) return;

      try {
        const maplibre = await import("maplibre-gl");
        if (cancelled || !containerRef.current) return;

        maplibre.setWorkerUrl("/maplibre/maplibre-gl-worker.mjs");

        const map = new maplibre.Map({
          container: containerRef.current,
          style: STYLE_URL,
          center: [15, 18],
          zoom: 1.55,
          minZoom: 1,
          maxZoom: 16,
          pitch: 0,
        });

        map.addControl(new maplibre.NavigationControl({ visualizePitch: true }), "bottom-right");
        map.addControl(new maplibre.GlobeControl(), "bottom-right");

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

            markerButton.addEventListener("click", (event) => {
              event.stopPropagation();
              setMapPick(null);
              setSelectedId(place.id);
              map.flyTo({
                center: [place.longitude, place.latitude],
                zoom: Math.max(place.zoom, 5),
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

        map.on("click", (event) => {
          const radius = 54;
          const rendered = map
            .queryRenderedFeatures([
              [event.point.x - radius, event.point.y - radius],
              [event.point.x + radius, event.point.y + radius],
            ])
            .filter((feature) => feature.sourceLayer === "place" && featureName(feature.properties));

          const zoom = map.getZoom();
          const classOrder =
            zoom < 3.5
              ? ["country", "state", "province", "city", "island"]
              : zoom < 6
                ? ["state", "province", "city", "town", "country", "island"]
                : ["city", "town", "village", "hamlet", "state", "province", "island", "country"];

          const ranked = [...rendered].sort((a, b) => {
            const aClass = String(a.properties?.class ?? "");
            const bClass = String(b.properties?.class ?? "");
            const ai = classOrder.indexOf(aClass);
            const bi = classOrder.indexOf(bClass);
            return (ai === -1 ? 999 : ai) - (bi === -1 ? 999 : bi);
          });

          let pickedName: string | null = null;
          let pickedClass = "place";
          let pickedCoordinates: [number, number] | null = null;

          const renderedPick = ranked[0];
          if (renderedPick && renderedPick.geometry.type === "Point") {
            pickedName = featureName(renderedPick.properties);
            pickedClass = String(renderedPick.properties?.class ?? "place");
            pickedCoordinates = renderedPick.geometry.coordinates as [number, number];
          }

          if (!pickedName || !pickedCoordinates) {
            const sourceFeatures = map
              .querySourceFeatures("openmaptiles", { sourceLayer: "place" })
              .filter(
                (feature) =>
                  feature.geometry.type === "Point" &&
                  featureName(feature.properties) &&
                  classOrder.includes(String(feature.properties?.class ?? "")),
              );

            let bestDistance = Number.POSITIVE_INFINITY;
            let nearestName: string | null = null;
            let nearestClass = "place";
            let nearestCoordinates: [number, number] | null = null;

            for (const feature of sourceFeatures) {
              if (feature.geometry.type !== "Point") continue;
              const coords = feature.geometry.coordinates as [number, number];
              const dx = (coords[0] - event.lngLat.lng) * Math.cos((event.lngLat.lat * Math.PI) / 180);
              const dy = coords[1] - event.lngLat.lat;
              const distance = dx * dx + dy * dy;
              if (distance < bestDistance) {
                bestDistance = distance;
                nearestName = featureName(feature.properties);
                nearestClass = String(feature.properties?.class ?? "place");
                nearestCoordinates = coords;
              }
            }

            pickedName = nearestName;
            pickedClass = nearestClass;
            pickedCoordinates = nearestCoordinates;
          }

          if (pickedName && pickedCoordinates) {
            useMapFeature(pickedName, pickedClass, pickedCoordinates[0], pickedCoordinates[1]);
            return;
          }

          setSelectedId(null);
          setMapPick({
            name: "Point exploré",
            placeClass: "place",
            longitude: event.lngLat.lng,
            latitude: event.lngLat.lat,
          });
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
    setMapPick(null);
    setSelectedId(place.id);
    setQuery("");
    mapRef.current?.flyTo({
      center: [place.longitude, place.latitude],
      zoom: Math.max(place.zoom, 5),
      essential: true,
    });
  }

  function resetWorld() {
    setMapPick(null);
    setSelectedId(initialPlace?.id ?? null);
    mapRef.current?.flyTo({ center: [15, 18], zoom: 1.55, pitch: 0, bearing: 0, essential: true });
  }

  function surpriseMe() {
    if (!places.length) return;
    const candidates = places.filter((place) => place.placeType !== "country");
    const source = candidates.length ? candidates : places;
    const place = source[Math.floor(Math.random() * source.length)];
    focusPlace(place);
  }

  return (
    <section className="earth-explorer" aria-labelledby="atlas-title">
      <div ref={containerRef} className="earth-map" aria-label="Planète Terre culinaire interactive" />

      {mapState === "loading" ? (
        <div className="earth-loading">Chargement de la planète…</div>
      ) : null}
      {mapState === "error" ? (
        <div className="earth-loading error">Impossible de charger le globe 3D sur cet appareil.</div>
      ) : null}

      <div className="earth-topbar">
        <Link className="earth-home-button" href="/" aria-label="Retour à l’accueil">←</Link>
        <div className="earth-title">
          <span>🌍</span>
          <div>
            <strong id="atlas-title">Globetrotter culinaire</strong>
            <small>Tournez la Terre. Touchez un endroit. Découvrez quoi manger.</small>
          </div>
        </div>
        <button type="button" className="earth-random-button" onClick={surpriseMe}>
          🎲 Je sais pas quoi manger
        </button>
      </div>

      <div className="earth-search-wrap">
        <label className="earth-search">
          <span aria-hidden="true">⌕</span>
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Pays, région, ville ou plat…"
            aria-label="Rechercher un pays, une région, une ville ou un plat"
          />
        </label>
        {query && filteredPlaces.length ? (
          <div className="earth-search-results">
            {filteredPlaces.map((place) => (
              <button key={place.id} type="button" onClick={() => focusPlace(place)}>
                <span>{levelLabels[place.placeType]}</span>
                <strong>{placePath(place).map((item) => item.name).join(" › ")}</strong>
              </button>
            ))}
          </div>
        ) : null}
      </div>

      <div className="earth-instruction">
        <strong>Faites tourner la planète avec le doigt.</strong>
        <span>Zoomez, puis touchez un nom de pays, région ou ville.</span>
      </div>

      <aside className="earth-discovery-card" aria-live="polite">
        {dataError ? (
          <p className="form-alert error">Certaines données culinaires n’ont pas pu être chargées.</p>
        ) : null}

        {mapPick ? (
          <>
            <div className="place-level">{labelForMapClass(mapPick.placeClass)}</div>
            <h2>{mapPick.name}</h2>
            <p className="place-parent">Lieu choisi directement sur la carte mondiale</p>
            <p>
              Cette ville ou région est reconnue par la carte. Elle n’a pas encore de fiche culinaire
              complète dans notre base, mais elle peut être ajoutée sans changer le globe.
            </p>
            <div className="earth-coordinate">
              {mapPick.latitude.toFixed(2)}°, {mapPick.longitude.toFixed(2)}°
            </div>
            <div className="atlas-empty">
              Aucune recette locale n’est encore reliée à ce lieu. À mesure que notre atlas se remplit,
              les spécialités et recettes apparaîtront ici automatiquement.
            </div>
          </>
        ) : selected ? (
          <>
            <div className="place-level">{levelLabels[selected.placeType]}</div>
            <h2>{selected.name}</h2>
            <p className="place-parent">
              {placePath(selected).map((place) => place.name).join(" › ")}
            </p>
            <p>{selected.summary || "Découvrez ce que l’on cuisine dans cette zone."}</p>

            {childPlaces.length > 0 ? (
              <div className="place-examples">
                <span>Explorer plus précisément</span>
                {childPlaces.map((place) => (
                  <button type="button" key={place.id} onClick={() => focusPlace(place)}>
                    {levelLabels[place.placeType]} · {place.name}
                  </button>
                ))}
              </div>
            ) : null}

            <div className="atlas-recipes">
              <div className="atlas-recipes-heading">
                <span>Recettes de cette zone</span>
                <strong>{selectedRecipes.length}</strong>
              </div>
              {selectedRecipes.length ? (
                <div className="atlas-recipe-list">
                  {selectedRecipes.slice(0, 10).map((recipe) => (
                    <Link href={`/recipes/${recipe.id}`} key={`${recipe.id}-${recipe.placeId}`}>
                      <span>{recipe.category || "Recette locale"}</span>
                      <strong>{recipe.title}</strong>
                      <small>Voir ingrédients + étapes complètes →</small>
                    </Link>
                  ))}
                </div>
              ) : (
                <p className="atlas-empty">
                  Aucune recette publiée n’est encore reliée à cette zone. Dès qu’une recette est associée
                  ici, elle apparaîtra automatiquement.
                </p>
              )}
            </div>
          </>
        ) : (
          <p>Tournez la Terre et touchez un endroit pour commencer.</p>
        )}
      </aside>

      <div className="earth-map-hint">
        🖐 Glisser pour tourner · 🤏 Pincer pour zoomer · 👆 Toucher un lieu
      </div>

      <button type="button" className="earth-reset-button" onClick={resetWorld}>
        🌐 Revoir la Terre entière
      </button>
    </section>
  );
}
