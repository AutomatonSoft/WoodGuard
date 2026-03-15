"use client";

import { useEffect, useEffectEvent, useRef } from "react";

type LeafletModule = typeof import("leaflet");
type LeafletMap = import("leaflet").Map;
type LeafletMarker = import("leaflet").Marker;

const DEFAULT_CENTER: [number, number] = [51.1657, 10.4515];
const DEFAULT_ZOOM = 5;
const FOCUSED_ZOOM = 12;

function createMarkerIcon(leaflet: LeafletModule) {
  return leaflet.divIcon({
    className: "mapPickerMarker",
    html: "<span></span>",
    iconSize: [22, 22],
    iconAnchor: [11, 11],
  });
}

export function MapPicker({
  latitude,
  longitude,
  onChange,
}: {
  latitude: number | null;
  longitude: number | null;
  onChange: (latitude: number, longitude: number) => void;
}) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const leafletRef = useRef<LeafletModule | null>(null);
  const mapRef = useRef<LeafletMap | null>(null);
  const markerRef = useRef<LeafletMarker | null>(null);
  const emitChange = useEffectEvent((nextLatitude: number, nextLongitude: number) => {
    onChange(nextLatitude, nextLongitude);
  });

  useEffect(() => {
    let disposed = false;

    void import("leaflet").then((leaflet) => {
      if (disposed || !containerRef.current || mapRef.current) {
        return;
      }

      leafletRef.current = leaflet;

      const hasCoordinates = latitude !== null && longitude !== null;
      const map = leaflet.map(containerRef.current, {
        center: hasCoordinates ? [latitude, longitude] : DEFAULT_CENTER,
        zoom: hasCoordinates ? FOCUSED_ZOOM : DEFAULT_ZOOM,
        scrollWheelZoom: true,
        zoomControl: false,
      });

      leaflet
        .tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
          attribution: "&copy; OpenStreetMap contributors",
        })
        .addTo(map);

      leaflet.control.zoom({ position: "bottomright" }).addTo(map);

      map.on("click", (event) => {
        const nextLatitude = Number(event.latlng.lat.toFixed(6));
        const nextLongitude = Number(event.latlng.lng.toFixed(6));
        const nextPoint = leaflet.latLng(nextLatitude, nextLongitude);

        if (markerRef.current) {
          markerRef.current.setLatLng(nextPoint);
        } else {
          markerRef.current = leaflet.marker(nextPoint, { icon: createMarkerIcon(leaflet) }).addTo(map);
        }

        map.panTo(nextPoint);
        emitChange(nextLatitude, nextLongitude);
      });

      if (hasCoordinates) {
        markerRef.current = leaflet
          .marker([latitude, longitude], { icon: createMarkerIcon(leaflet) })
          .addTo(map);
      }

      mapRef.current = map;
    });

    return () => {
      disposed = true;
      mapRef.current?.remove();
      markerRef.current = null;
      mapRef.current = null;
      leafletRef.current = null;
    };
  }, [emitChange]);

  useEffect(() => {
    if (!mapRef.current || !leafletRef.current || latitude === null || longitude === null) {
      return;
    }

    const nextPoint = leafletRef.current.latLng(latitude, longitude);
    if (markerRef.current) {
      markerRef.current.setLatLng(nextPoint);
    } else {
      markerRef.current = leafletRef.current.marker(nextPoint, { icon: createMarkerIcon(leafletRef.current) }).addTo(mapRef.current);
    }

    mapRef.current.setView(nextPoint, Math.max(mapRef.current.getZoom(), FOCUSED_ZOOM));
  }, [latitude, longitude]);

  return <div ref={containerRef} className="mapPickerCanvas" />;
}
