"use client";

import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useEffect, useRef } from 'react';

// Custom motorcycle icon for drivers
const createDriverIcon = (isOnline: boolean) => new L.DivIcon({
  className: '',
  html: `<div style="
    background: ${isOnline ? '#10b981' : '#9ca3af'};
    border: 3px solid white;
    border-radius: 50% 50% 50% 0;
    width: 28px; height: 28px;
    transform: rotate(-45deg);
    box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    display: flex; align-items: center; justify-content: center;
  "><span style="transform: rotate(45deg); font-size: 13px; display: block; text-align: center; line-height: 22px;">🏍️</span></div>`,
  iconSize: [28, 28],
  iconAnchor: [14, 28],
  popupAnchor: [0, -30],
});

const pickupIcon = new L.DivIcon({
  className: '',
  html: `<div style="
    background: #3b82f6; border: 3px solid white; border-radius: 50%;
    width: 22px; height: 22px; box-shadow: 0 2px 6px rgba(0,0,0,0.3);
    display: flex; align-items: center; justify-content: center;
    font-size: 11px;
  ">🟢</div>`,
  iconSize: [22, 22],
  iconAnchor: [11, 11],
  popupAnchor: [0, -12],
});

type DriverMarker = {
  id: string;
  name: string;
  status: string;
  vehicle_type?: string;
  current_lat?: number | null;
  current_lng?: number | null;
};

type AllDriversMapProps = {
  drivers: DriverMarker[];
  pickupLat?: number | null;
  pickupLng?: number | null;
  pickupLabel?: string;
};

// Helper to fly map when pickup changes
function MapFlyTo({ lat, lng }: { lat?: number | null; lng?: number | null }) {
  const map = useMap();
  const prev = useRef<string>('');
  useEffect(() => {
    const key = `${lat},${lng}`;
    if (lat && lng && key !== prev.current) {
      prev.current = key;
      map.flyTo([lat, lng], 14, { animate: true, duration: 1.2 });
    }
  }, [lat, lng, map]);
  return null;
}

export default function AllDriversMap({ drivers, pickupLat, pickupLng, pickupLabel }: AllDriversMapProps) {
  const defaultCenter: [number, number] = [9.005401, 38.763611]; // Addis Ababa

  const driversWithLocation = drivers.filter(d => d.current_lat && d.current_lng);

  // Determine map center: pickup location if present, else first driver, else default
  const center: [number, number] =
    (pickupLat && pickupLng) ? [pickupLat, pickupLng] :
    (driversWithLocation.length > 0 ? [driversWithLocation[0].current_lat!, driversWithLocation[0].current_lng!] :
    defaultCenter);

  return (
    <div style={{ height: '100%', width: '100%' }} className="rounded-xl overflow-hidden">
      <MapContainer center={center} zoom={13} style={{ height: '100%', width: '100%' }} zoomControl={true}>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {pickupLat && pickupLng && (
          <>
            <MapFlyTo lat={pickupLat} lng={pickupLng} />
            <Marker position={[pickupLat, pickupLng]} icon={pickupIcon}>
              <Popup>
                <div className="font-bold text-blue-700">📦 Pickup Point</div>
                <div className="text-xs text-neutral-600 mt-1">{pickupLabel || 'Delivery pickup'}</div>
              </Popup>
            </Marker>
          </>
        )}

        {driversWithLocation.map(driver => (
          <Marker
            key={driver.id}
            position={[driver.current_lat!, driver.current_lng!]}
            icon={createDriverIcon(driver.status === 'Online')}
          >
            <Popup>
              <div style={{ minWidth: '140px' }}>
                <div className="font-extrabold text-neutral-900">{driver.name}</div>
                <div className="text-xs mt-1 flex items-center space-x-1">
                  <span className={`inline-block w-2 h-2 rounded-full ${driver.status === 'Online' ? 'bg-emerald-500' : 'bg-neutral-400'}`} />
                  <span className={driver.status === 'Online' ? 'text-emerald-600 font-bold' : 'text-neutral-500'}>{driver.status}</span>
                </div>
                <div className="text-xs text-neutral-400 mt-1">{driver.vehicle_type === 'Motor' ? '🏍️ Motor' : '🚲 Bike'}</div>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}
