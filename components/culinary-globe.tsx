"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import type { GeoJSONSource, Map as MapLibreMap } from "maplibre-gl";
import {
  levelLabels,
  type AtlasPlaceImage,
  type AtlasRecipe,
  type AtlasSpecialty,
  type CulinaryPlace,
} from "@/lib/culinary-places";
import { mediaSourceLabel } from "@/lib/media";
import { LocalizedRecipeTitle } from "@/components/localized-recipe-title";
import { OpenPlaceImage } from "@/components/open-place-image";
import { OpenRecipeImage } from "@/components/open-recipe-image";

const STYLE_URL = "https://tiles.openfreemap.org/styles/liberty";
const MARKER_SOURCE = "culinary-places";

// Plus on zoome, plus on descend : pays → régions et îles → villes et localités.
const MARKER_LEVELS = [
  { id: "country", types: ["country"], minzoom: 0, maxzoom: 4.6, color: "#f59e0b", radius: 7 },
  { id: "region", types: ["region", "island"], minzoom: 3.4, maxzoom: 24, color: "#e4572e", radius: 8 },
  { id: "city", types: ["city", "locality"], minzoom: 5.2, maxzoom: 24, color: "#b91c1c", radius: 7 },
] as const;

const MARKER_CIRCLE_LAYERS = MARKER_LEVELS.map((level) => `culinary-${level.id}-circle`);

type MarkerCollection = GeoJSON.FeatureCollection<GeoJSON.Point, {
  id: string;
  name: string;
  placeType: string;
  recipeCount: number;
  specialty: string;
}>;

type Props = {
  places: CulinaryPlace[];
  recipes: AtlasRecipe[];
  specialties: AtlasSpecialty[];
  placeImages: AtlasPlaceImage[];
  dataError?: string | null;
  initialPlaceId?: string | null;
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

export function CulinaryGlobe({
  places,
  recipes,
  specialties,
  placeImages,
  dataError = null,
  initialPlaceId = null,
}: Props) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<MapLibreMap | null>(null);
  const initialPlace: CulinaryPlace | null = null;
  const [selectedId, setSelectedId] = useState<string | null>(initialPlaceId);
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

  const selectedRecipes = useMemo(() => {
    const ordered = recipes
      .filter((recipe) => selectedPlaceIds.has(recipe.placeId))
      .sort((a, b) => {
        const aDirect = selected && a.placeId === selected.id ? 1 : 0;
        const bDirect = selected && b.placeId === selected.id ? 1 : 0;
        return bDirect - aDirect || a.title.localeCompare(b.title, "fr");
      });

    const unique = new Map<string, AtlasRecipe>();
    for (const recipe of ordered) {
      if (!unique.has(recipe.id)) unique.set(recipe.id, recipe);
    }
    return [...unique.values()];
  }, [recipes, selectedPlaceIds, selected]);

  const selectedSpecialties = useMemo(
    () =>
      specialties
        .filter((specialty) => selectedPlaceIds.has(specialty.placeId))
        .sort((a, b) => {
          const aDirect = selected && a.placeId === selected.id ? 1 : 0;
          const bDirect = selected && b.placeId === selected.id ? 1 : 0;
          return (
            bDirect - aDirect ||
            Number(b.isSignature) - Number(a.isSignature) ||
            a.sortOrder - b.sortOrder ||
            a.name.localeCompare(b.name, "fr")
          );
        }),
    [specialties, selectedPlaceIds, selected],
  );

  const recipeLimit =
    selected?.placeType === "country"
      ? 4
      : selected?.placeType === "region" || selected?.placeType === "island"
        ? 6
        : 8;

  const specialtyLimit = recipeLimit;

  const recipeSectionLabel =
    selected?.placeType === "country"
      ? "Recettes représentatives du pays"
      : selected?.placeType === "region" || selected?.placeType === "island"
        ? "Recettes de la région"
        : "Recettes locales";

  const specialtySectionLabel =
    selected?.placeType === "country"
      ? "Spécialités du pays"
      : selected?.placeType === "region" || selected?.placeType === "island"
        ? "Spécialités de la région"
        : "Spécialités du coin";

  const worldRecipeCount = useMemo(
    () => new Set(recipes.map((recipe) => recipe.id)).size,
    [recipes],
  );

  const worldCountryCount = useMemo(() => {
    const countries = new Set<string>();
    for (const recipe of recipes) {
      let place = placeById.get(recipe.placeId);
      const visited = new Set<string>();
      while (place && !visited.has(place.id)) {
        visited.add(place.id);
        if (place.placeType === "country") {
          countries.add(place.id);
          break;
        }
        place = place.parentId ? placeById.get(place.parentId) : undefined;
      }
    }
    return countries.size;
  }, [recipes, placeById]);

  const worldSubplaceCount = useMemo(
    () => places.filter((place) => place.placeType !== "country").length,
    [places],
  );

  const markerData = useMemo<MarkerCollection>(() => {
    const recipeCount = new Map<string, Set<string>>();
    for (const recipe of recipes) {
      let place = placeById.get(recipe.placeId);
      const visited = new Set<string>();
      while (place && !visited.has(place.id)) {
        visited.add(place.id);
        const ids = recipeCount.get(place.id) ?? new Set<string>();
        ids.add(recipe.id);
        recipeCount.set(place.id, ids);
        place = place.parentId ? placeById.get(place.parentId) : undefined;
      }
    }

    const topSpecialty = new Map<string, string>();
    for (const specialty of [...specialties].sort(
      (a, b) => Number(b.isSignature) - Number(a.isSignature) || a.sortOrder - b.sortOrder,
    )) {
      if (!topSpecialty.has(specialty.placeId)) topSpecialty.set(specialty.placeId, specialty.name);
    }

    return {
      type: "FeatureCollection",
      features: places
        .filter((place) => recipeCount.has(place.id) || topSpecialty.has(place.id))
        .map((place) => ({
          type: "Feature",
          geometry: { type: "Point", coordinates: [place.longitude, place.latitude] },
          properties: {
            id: place.id,
            name: place.name,
            placeType: place.placeType,
            recipeCount: recipeCount.get(place.id)?.size ?? 0,
            specialty: (topSpecialty.get(place.id) ?? "").slice(0, 42),
          },
        })),
    };
  }, [places, recipes, specialties, placeById]);

  const markerDataRef = useRef(markerData);
  markerDataRef.current = markerData;

  useEffect(() => {
    const source = mapRef.current?.getSource(MARKER_SOURCE) as GeoJSONSource | undefined;
    source?.setData(markerData);
  }, [markerData]);

  const selectedPlaceImage = useMemo(() => {
    if (!selected) return null;
    return (
      placeImages.find((image) => image.placeId === selected.id && image.isPrimary) ??
      placeImages.find((image) => image.placeId === selected.id) ??
      null
    );
  }, [placeImages, selected]);

  const childPlaces = useMemo(
    () => (selected ? places.filter((place) => place.parentId === selected.id) : []),
    [places, selected],
  );

  const filteredPlaces = useMemo(() => {
    const normalized = normalizeName(query);
    if (!normalized) return [];

    const matchingPlaceIds = new Set<string>();

    for (const recipe of recipes) {
      if (
        normalizeName([recipe.title, recipe.category ?? "", recipe.description ?? ""].join(" ")).includes(normalized)
      ) {
        matchingPlaceIds.add(recipe.placeId);
      }
    }

    for (const specialty of specialties) {
      if (
        normalizeName([specialty.name, specialty.description ?? "", specialty.originNote ?? ""].join(" ")).includes(normalized)
      ) {
        matchingPlaceIds.add(specialty.placeId);
      }
    }

    return places
      .filter((place) => {
        const path = placePath(place).map((item) => item.name).join(" ");
        return (
          normalizeName([place.name, place.countryCode, path].join(" ")).includes(normalized) ||
          matchingPlaceIds.has(place.id)
        );
      })
      .slice(0, 8);
  }, [query, places, recipes, specialties, placeById]);

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
      focusPlace(databaseMatch);
      return;
    }

    setSelectedId(null);
    setMapPick({ name, placeClass, longitude, latitude });
  }

  const placeByIdRef = useRef(placeById);
  placeByIdRef.current = placeById;
  const focusPlaceRef = useRef<(place: CulinaryPlace) => void>(() => undefined);

  function addCulinaryMarkers(map: MapLibreMap) {
    if (map.getSource(MARKER_SOURCE)) return;

    map.addSource(MARKER_SOURCE, { type: "geojson", data: markerDataRef.current });

    for (const level of MARKER_LEVELS) {
      const filter = ["in", ["get", "placeType"], ["literal", [...level.types]]] as const;

      map.addLayer({
        id: `culinary-${level.id}-circle`,
        type: "circle",
        source: MARKER_SOURCE,
        minzoom: level.minzoom,
        maxzoom: level.maxzoom,
        filter: filter as never,
        paint: {
          "circle-color": level.color,
          "circle-radius": [
            "interpolate", ["linear"], ["get", "recipeCount"],
            0, level.radius - 2,
            10, level.radius + 2,
            60, level.radius + 6,
          ],
          "circle-stroke-color": "#ffffff",
          "circle-stroke-width": 2,
          "circle-opacity": 0.92,
        },
      });

      map.addLayer({
        id: `culinary-${level.id}-label`,
        type: "symbol",
        source: MARKER_SOURCE,
        minzoom: level.id === "country" ? 2.2 : level.minzoom + 0.4,
        maxzoom: level.maxzoom,
        filter: filter as never,
        layout: {
          "text-field": [
            "format",
            ["get", "name"], { "font-scale": 1 },
            ["case", ["!=", ["get", "specialty"], ""], "\n", ""], {},
            ["get", "specialty"], { "font-scale": 0.85 },
          ] as never,
          "text-font": ["Noto Sans Bold"],
          "text-size": level.id === "country" ? 11 : 12,
          "text-offset": [0, 1.1],
          "text-anchor": "top",
          "text-max-width": 12,
          "text-optional": true,
        },
        paint: {
          "text-color": "#3b1d0e",
          "text-halo-color": "#fffaf2",
          "text-halo-width": 1.6,
        },
      });
    }
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
          addCulinaryMarkers(map);
          setMapState("ready");
          map.resize();
          const initial = initialPlaceId ? placeByIdRef.current.get(initialPlaceId) : undefined;
          if (initial) focusPlaceRef.current(initial);
        });

        for (const layerId of MARKER_CIRCLE_LAYERS) {
          map.on("mouseenter", layerId, () => {
            map.getCanvas().style.cursor = "pointer";
          });
          map.on("mouseleave", layerId, () => {
            map.getCanvas().style.cursor = "";
          });
        }

        map.on("click", (event) => {
          const markerLayers = MARKER_CIRCLE_LAYERS.filter((layerId) => map.getLayer(layerId));
          const markerHits = markerLayers.length
            ? map.queryRenderedFeatures(
                [
                  [event.point.x - 12, event.point.y - 12],
                  [event.point.x + 12, event.point.y + 12],
                ],
                { layers: markerLayers },
              )
            : [];
          const markerPlace = markerHits
            .map((feature) => placeByIdRef.current.get(String(feature.properties?.id ?? "")))
            .find((place): place is CulinaryPlace => Boolean(place));

          if (markerPlace) {
            focusPlaceRef.current(markerPlace);
            return;
          }

          const zoom = map.getZoom();
          const radius = zoom < 3.5 ? 90 : zoom < 6 ? 72 : 54;
          const rendered = map
            .queryRenderedFeatures([
              [event.point.x - radius, event.point.y - radius],
              [event.point.x + radius, event.point.y + radius],
            ])
            .filter((feature) => feature.sourceLayer === "place" && featureName(feature.properties));

          const classOrder =
            zoom < 3.5
              ? ["country"]
              : zoom < 6
                ? ["state", "province", "island", "country"]
                : ["city", "town", "village", "hamlet", "borough", "suburb", "quarter", "neighbourhood", "state", "province", "island", "country"];

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
      mapRef.current?.remove();
      mapRef.current = null;
    };
  }, [places]);

  function focusPlace(place: CulinaryPlace) {
    setMapPick(null);
    setSelectedId(place.id);
    setQuery("");

    const targetZoom =
      place.placeType === "country"
        ? Math.min(Math.max(place.zoom, 3.2), 4.2)
        : place.placeType === "region" || place.placeType === "island"
          ? Math.max(place.zoom, 5.7)
          : Math.max(place.zoom, 8.5);

    mapRef.current?.flyTo({
      center: [place.longitude, place.latitude],
      zoom: targetZoom,
      essential: true,
    });
  }

  focusPlaceRef.current = focusPlace;

  function resetWorld() {
    setMapPick(null);
    setSelectedId(null);
    mapRef.current?.flyTo({ center: [15, 18], zoom: 1.55, pitch: 0, bearing: 0, essential: true });
  }

  function surpriseMe() {
    if (!places.length) return;
    const usefulPlaceIds = new Set([
      ...recipes.map((recipe) => recipe.placeId),
      ...specialties.map((specialty) => specialty.placeId),
    ]);
    const useful = places.filter((place) => place.placeType !== "country" && usefulPlaceIds.has(place.id));
    const candidates = useful.length
      ? useful
      : places.filter((place) => place.placeType !== "country");
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
            <div className="earth-title-stats">
              <span>{worldRecipeCount.toLocaleString("fr-CA")} recettes</span>
              <span>{worldCountryCount.toLocaleString("fr-CA")} pays</span>
              <span>{worldSubplaceCount.toLocaleString("fr-CA")} régions/villes</span>
            </div>
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
            {selectedPlaceImage ? (
              <figure className="atlas-place-media">
                <Image
                  src={selectedPlaceImage.url}
                  alt={selectedPlaceImage.altText || selected.name}
                  fill
                  sizes="390px"
                />
                <figcaption>
                  <span>{mediaSourceLabel(selectedPlaceImage.sourceType)}</span>
                  {selectedPlaceImage.attributionText ? <small>{selectedPlaceImage.attributionText}</small> : null}
                  {selectedPlaceImage.sourcePageUrl ? (
                    <a href={selectedPlaceImage.sourcePageUrl} target="_blank" rel="noreferrer">Source ↗</a>
                  ) : null}
                </figcaption>
              </figure>
            ) : (
              <OpenPlaceImage
                name={selected.name}
                countryCode={selected.countryCode}
                className="atlas-place-media atlas-open-place-media"
                alt={`Photo représentative de ${selected.name}`}
                showCredit
              />
            )}

            <div className="place-level">{levelLabels[selected.placeType]}</div>
            <h2>{selected.name}</h2>
            <p className="place-parent">
              {placePath(selected).map((place) => place.name).join(" › ")}
            </p>
            <p>{selected.summary || "Découvrez ce que l’on cuisine dans cette zone."}</p>

            <div className="atlas-context-stats">
              <div>
                <strong>{selectedRecipes.length.toLocaleString("fr-CA")}</strong>
                <span>recettes dans cette zone</span>
              </div>
              <div>
                <strong>{childPlaces.length.toLocaleString("fr-CA")}</strong>
                <span>régions ou villes à explorer</span>
              </div>
            </div>

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

            {selectedSpecialties.length ? (
              <div className="atlas-specialties">
                <div className="atlas-recipes-heading">
                  <span>{specialtySectionLabel}</span>
                  <strong>{selectedSpecialties.length}</strong>
                </div>
                <div className="atlas-specialty-list">
                  {selectedSpecialties.slice(0, specialtyLimit).map((specialty) => {
                    const body = (
                      <>
                        {specialty.isSignature ? <span>Spécialité emblématique</span> : <span>Spécialité locale</span>}
                        <strong>{specialty.name}</strong>
                        {specialty.description ? <small>{specialty.description}</small> : null}
                      </>
                    );
                    return specialty.recipeId ? (
                      <Link href={`/recipes/${specialty.recipeId}`} key={specialty.id}>{body}</Link>
                    ) : (
                      <div className="atlas-specialty-item" key={specialty.id}>{body}</div>
                    );
                  })}
                </div>
              </div>
            ) : null}

            <div className="atlas-recipes">
              <div className="atlas-recipes-heading">
                <span>{recipeSectionLabel}</span>
                <strong>{selectedRecipes.length}</strong>
              </div>
              {selectedRecipes.length ? (
                <div className="atlas-recipe-list">
                  {selectedRecipes.slice(0, recipeLimit).map((recipe) => (
                    <Link href={`/recipes/${recipe.id}`} key={`${recipe.id}-${recipe.placeId}`}>
                      {recipe.coverImageUrl ? (
                        <div className="atlas-recipe-thumb">
                          <Image src={recipe.coverImageUrl} alt={recipe.title} fill sizes="84px" />
                        </div>
                      ) : (
                        <OpenRecipeImage
                          title={recipe.originalTitle}
                          countryCode={recipe.countryCode}
                          className="atlas-recipe-thumb"
                          alt={recipe.title}
                          showCredit={false}
                        />
                      )}
                      <div>
                        <span>{recipe.category || "Recette locale"}</span>
                        <strong>
                          <LocalizedRecipeTitle
                            originalTitle={recipe.originalTitle}
                            translations={recipe.titleTranslations}
                          />
                        </strong>
                        <small>Voir ingrédients + étapes complètes →</small>
                      </div>
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
        🖐 Tourner · 🤏 Zoomer · 👆 Pays → région → ville
      </div>

      <button type="button" className="earth-reset-button" onClick={resetWorld}>
        🌐 Revoir la Terre entière
      </button>
    </section>
  );
}
