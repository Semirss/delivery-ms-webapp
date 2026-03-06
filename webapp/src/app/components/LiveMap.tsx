"use client";

import { MapContainer, TileLayer, Marker, Popup, Polyline } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useEffect, useState } from 'react';

// Fix leaflet default icons not loading in React
const iconPerson = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

const iconDriver = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

type LiveMapProps = {
  driverLat?: number | null;
  driverLng?: number | null;
  pickupLat?: number | null;
  pickupLng?: number | null;
  dropoffLat?: number | null;
  dropoffLng?: number | null;
};

export default function LiveMap({ driverLat, driverLng, pickupLat, pickupLng, dropoffLat, dropoffLng }: LiveMapProps) {
  const defaultCenter: [number, number] = [9.005401, 38.763611]; // Addis Ababa default
  const center: [number, number] = driverLat && driverLng ? [driverLat, driverLng] : defaultCenter;

  const hasRoute = pickupLat && pickupLng && dropoffLat && dropoffLng;
  const polylinePositions: [number, number][] = hasRoute 
    ? [[pickupLat, pickupLng], [dropoffLat, dropoffLng]]
    : [];

  return (
    <div style={{ height: '400px', width: '100%' }} className="rounded-xl overflow-hidden border border-neutral-200">
      <MapContainer center={center} zoom={13} style={{ height: '100%', width: '100%' }}>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        
        {/* Driver Location */}
        {driverLat && driverLng && (
          <Marker position={[driverLat, driverLng]} icon={iconDriver}>
            <Popup>Driver Location</Popup>
          </Marker>
        )}

        {/* Pickup Location */}
        {pickupLat && pickupLng && (
          <Marker position={[pickupLat, pickupLng]} icon={iconPerson}>
            <Popup>Pickup</Popup>
          </Marker>
        )}

        {/* Dropoff Location */}
        {dropoffLat && dropoffLng && (
          <Marker position={[dropoffLat, dropoffLng]} icon={iconPerson}>
            <Popup>Dropoff</Popup>
          </Marker>
        )}

        {/* Basic Route Line */}
        {hasRoute && (
          <Polyline pathOptions={{ color: 'blue', weight: 4, opacity: 0.6 }} positions={polylinePositions} />
        )}
      </MapContainer>
    </div>
  );
}
