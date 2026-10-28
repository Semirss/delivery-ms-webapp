"use client";

import { MapContainer, TileLayer, Marker, Popup, Circle, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { Fragment, useEffect, useRef, useState } from 'react';
import { gpsQuality } from '@/lib/driver-operations';

const createDriverIcon = (isOnline: boolean) => new L.DivIcon({
  className: '',
  html: `<div style="
    background: ${isOnline ? '#10b981' : '#9ca3af'};
    border: 3px solid white;
    border-radius: 50% 50% 50% 0;
    width: 32px; height: 32px;
    transform: rotate(-45deg);
    box-shadow: 0 2px 8px rgba(0,0,0,0.35);
    display: flex; align-items: center; justify-content: center;
  "><span style="transform: rotate(45deg); font-size: 15px; display: block; text-align: center; line-height: 26px;">🏍️</span></div>`,
  iconSize: [32, 32],
  iconAnchor: [16, 32],
  popupAnchor: [0, -36],
});

const pickupIcon = new L.DivIcon({
  className: '',
  html: `<div style="
    background: #3b82f6; border: 3px solid white; border-radius: 50%;
    width: 24px; height: 24px; box-shadow: 0 2px 6px rgba(0,0,0,0.3);
    display: flex; align-items: center; justify-content: center; font-size: 12px;
  ">🟢</div>`,
  iconSize: [24, 24],
  iconAnchor: [12, 12],
  popupAnchor: [0, -14],
});

type DriverMarker = {
  id: string;
  name: string;
  status: string;
  vehicle_type?: string;
  current_lat?: number | null;
  current_lng?: number | null;
  last_location_update?: string | null;
  location_accuracy_m?: number | null;
  location_heading?: number | null;
  location_speed_mps?: number | null;
  working_radius_km?: number | null;
};

type AllDriversMapProps = {
  drivers: DriverMarker[];
  pickupLat?: number | null;
  pickupLng?: number | null;
  pickupLabel?: string;
};

// Internal component — can call useMap() safely inside MapContainer
function MapController({
  flyTarget,
}: {
  flyTarget: [number, number] | null;
}) {
  const map = useMap();
  const prev = useRef<string>('');

  useEffect(() => {
    if (!flyTarget) return;
    const key = flyTarget.join(',');
    if (key !== prev.current) {
      prev.current = key;
      map.flyTo(flyTarget, 15, { animate: true, duration: 1.0 });
    }
  }, [flyTarget, map]);

  return null;
}

export default function AllDriversMap({ drivers, pickupLat, pickupLng, pickupLabel }: AllDriversMapProps) {
  const defaultCenter: [number, number] = [9.005401, 38.763611];
  const driversWithLocation = drivers.filter(d => d.current_lat != null && d.current_lng != null &&
    Number.isFinite(d.current_lat) && Number.isFinite(d.current_lng) && Math.abs(d.current_lat) <= 90 && Math.abs(d.current_lng) <= 180);
  const [now,setNow] = useState(Date.now());
  useEffect(() => { const timer = setInterval(() => setNow(Date.now()), 10000); return () => clearInterval(timer); },[]);
  const hasPickup = pickupLat != null && pickupLng != null && Number.isFinite(pickupLat) && Number.isFinite(pickupLng);
  const ageLabel = (driver: DriverMarker) => {
    const time = Date.parse(driver.last_location_update ?? '');
    if (!Number.isFinite(time)) return 'Fix time unknown';
    const seconds = Math.max(0, Math.floor((now-time)/1000));
    return seconds < 60 ? `${seconds}s ago` : `${Math.floor(seconds/60)}m ago`;
  };

  // flyTarget is set when user clicks a legend card — map will fly there
  const [flyTarget, setFlyTarget] = useState<[number, number] | null>(null);

  const center: [number, number] =
    hasPickup ? [pickupLat!, pickupLng!] :
    (driversWithLocation.length > 0
      ? [driversWithLocation[0].current_lat!, driversWithLocation[0].current_lng!]
      : defaultCenter);

  // When pickup changes, fly to it
  useEffect(() => {
    if (pickupLat != null && pickupLng != null) {
      setFlyTarget([pickupLat, pickupLng]);
    }
  }, [pickupLat, pickupLng]);

  return (
    <div style={{ height: '100%', width: '100%', display: 'flex', flexDirection: 'column' }}>
      <p className="pb-2 text-xs font-medium text-neutral-600">Green = fresh location within 200 m. Gray markers show last known positions. Accuracy circles show reported uncertainty. {drivers.length - driversWithLocation.length} drivers have no location fix.</p>
      {/* Map */}
      <div style={{ flex: 1, minHeight: 0 }} className="rounded-xl overflow-hidden">
        <MapContainer center={center} zoom={13} style={{ height: '100%', width: '100%' }} zoomControl={true}>
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          <MapController flyTarget={flyTarget} />

          {hasPickup && (
            <Marker position={[pickupLat!, pickupLng!]} icon={pickupIcon}>
              <Popup>
                <div style={{ minWidth: '130px' }}>
                  <div className="font-bold text-blue-700">📦 Pickup Point</div>
                  <div className="text-xs text-neutral-600 mt-1">{pickupLabel || 'Delivery pickup'}</div>
                </div>
              </Popup>
            </Marker>
          )}

          {driversWithLocation.map(driver => (
            <Fragment key={driver.id}>
            {driver.location_accuracy_m != null && Number.isFinite(driver.location_accuracy_m) && driver.location_accuracy_m > 0 && driver.location_accuracy_m <= 1000 &&
              <Circle center={[driver.current_lat!,driver.current_lng!]} radius={driver.location_accuracy_m}
                pathOptions={{color:gpsQuality(driver,now) === 'live' ? '#10b981' : '#9ca3af',weight:1,fillOpacity:0.1}}/>}
            <Marker
              key={driver.id}
              position={[driver.current_lat!, driver.current_lng!]}
              icon={createDriverIcon(gpsQuality(driver,now) === 'live')}
            >
              <Popup>
                <div style={{ minWidth: '140px' }}>
                  <div className="font-extrabold text-neutral-900">{driver.name}</div>
                  <p className="text-xs font-bold mt-1">GPS: {gpsQuality(driver,now)} · {ageLabel(driver)}</p>
                  <p className="text-xs">Accuracy: {driver.location_accuracy_m == null ? 'unknown' : `±${Math.round(driver.location_accuracy_m)} m`}</p>
                  <p className="text-xs">{driver.current_lat?.toFixed(6)}, {driver.current_lng?.toFixed(6)}</p>
                  <p className="text-xs">Working radius: {driver.working_radius_km ?? 5} km</p>
                  <div className="text-xs mt-1 flex items-center space-x-1">
                    <span className={`inline-block w-2 h-2 rounded-full ${driver.status === 'Online' ? 'bg-emerald-500' : 'bg-neutral-400'}`} />
                    <span className={driver.status === 'Online' ? 'text-emerald-600 font-bold' : 'text-neutral-500'}>{driver.status}</span>
                  </div>
                  <div className="text-xs text-neutral-400 mt-1">{driver.vehicle_type === 'Motor' ? '🏍️ Motor' : '🚲 Bike'}</div>
                </div>
              </Popup>
            </Marker>
            </Fragment>
          ))}
        </MapContainer>
      </div>

      {/* Driver legend — click to fly to driver */}
      {driversWithLocation.length > 0 && (
        <div className="flex flex-wrap gap-2 pt-3">
          {driversWithLocation.map(d => (
            <button
              key={d.id}
              onClick={() => setFlyTarget([d.current_lat!, d.current_lng!])}
              className="flex items-center space-x-2 bg-white border border-neutral-200 hover:border-blue-400 hover:bg-blue-50 rounded-xl px-3 py-2 transition-all shadow-sm group"
              title={`Fly to ${d.name}`}
            >
              <span className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${gpsQuality(d,now) === 'live' ? 'bg-emerald-500' : 'bg-neutral-300'}`} />
              <span className="font-bold text-xs text-neutral-800 group-hover:text-blue-700">{d.name}</span>
              <span className="text-[10px] text-neutral-500">{gpsQuality(d,now)} · {ageLabel(d)}</span>
              <span className="text-[10px] text-neutral-400">{d.vehicle_type === 'Motor' ? '🏍️' : '🚲'}</span>
              <span className="text-[10px] text-blue-400 font-bold group-hover:text-blue-600">→ locate</span>
            </button>
          ))}
        </div>
      )}

      {driversWithLocation.length === 0 && (
        <div className="text-center text-neutral-400 text-sm font-medium py-3">
          No drivers have shared their location yet.
        </div>
      )}
    </div>
  );
}
