"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import type { Map as MapLibreMap, Marker } from "maplibre-gl";
import { culinaryPlaces, levelLabels, type CulinaryPlace } from "@/lib/culinary-places";

const STYLE_URL = "https://tiles.openfreemap.org/styles/liberty";

export function CulinaryGlobe() {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<MapLibreMap | null>(null);
  const markersRef = useRef<Marker[]>([]);
  const [selected, setSelected] = useState<CulinaryPlace>(culinaryPlaces[3]);
  const [query, setQuery] = useState("");
  const [mapState, setMapState] = useState<"loading" | "ready" | "error">("loading");

  const filteredPlaces = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase("fr");
    if (!normalized) return culinaryPlaces;
    return culinaryPlaces.filter((place) =>
      [place.name, place.country, place.parent, ...place.examples]
        .join(" ")
        .toLocaleLowerCase("fr")
        .includes(normalized),
    );
  }, [query]);

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

          for (const place of culinaryPlaces) {
            const markerButton = document.createElement("button");
            markerButton.type = "button";
            markerButton.className = "culinary-map-marker";
            markerButton.setAttribute("aria-label", `Explorer ${place.name}, ${place.country}`);
            markerButton.title = `${place.name} · ${place.country}`;
            markerButton.innerHTML = "<span>🍴</span>";

            markerButton.addEventListener("click", () => {
              setSelected(place);
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
  }, []);

  function focusPlace(place: CulinaryPlace) {
    setSelected(place);
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
            puis découvrez les recettes associées à ce lieu.
          </p>
        </div>
        <Link className="ghost-button" href="/">← Accueil</Link>
      </div>

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
              Le globe 3D n’est pas disponible sur cet appareil. Utilisez la liste des lieux pour explorer.
            </div>
          )}
          <div className="atlas-map-hint">
            <strong>Astuce :</strong> pincez pour zoomer, glissez pour tourner le globe et touchez 🍴 pour ouvrir un lieu.
          </div>
        </div>

        <aside className="atlas-detail" aria-live="polite">
          <div className="place-level">{levelLabels[selected.level]}</div>
          <h2>{selected.name}</h2>
          <p className="place-parent">{selected.parent} · {selected.country}</p>
          <p>{selected.summary}</p>
          <div className="place-examples">
            <span>À explorer</span>
            {selected.examples.map((example) => (
              <button type="button" key={example}>{example}</button>
            ))}
          </div>
          <div className="atlas-note">
            Les lieux servent de filtres géographiques. Les recettes seront reliées au niveau le plus précis documenté
            et pourront aussi remonter vers leur région et leur pays.
          </div>
        </aside>
      </div>

      <div className="place-browser">
        <div className="section-heading">
          <div>
            <span className="eyebrow">Lieux disponibles dans la démo</span>
            <h2>Du pays jusqu’à la ville</h2>
          </div>
          <span>{filteredPlaces.length} lieu{filteredPlaces.length > 1 ? "x" : ""}</span>
        </div>
        <div className="place-grid">
          {filteredPlaces.map((place) => (
            <button
              type="button"
              key={place.id}
              className={`place-card ${selected.id === place.id ? "active" : ""}`}
              onClick={() => focusPlace(place)}
            >
              <span className="place-card-level">{levelLabels[place.level]}</span>
              <strong>{place.name}</strong>
              <small>{place.parent} · {place.country}</small>
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
