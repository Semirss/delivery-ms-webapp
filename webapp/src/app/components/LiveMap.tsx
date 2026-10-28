"use client";

import { MapContainer, TileLayer, Marker, Popup, Polyline, Circle, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useEffect, useState } from 'react';
import { gpsQuality } from '@/lib/driver-operations';

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
  driverStatus?: string;
  observedAt?: string | null;
  accuracy?: number | null;
};

function FollowDriver({ lat, lng }: { lat?: number | null; lng?: number | null }) {
  const map = useMap();
  useEffect(() => { if (lat != null && lng != null && Number.isFinite(lat) && Number.isFinite(lng)) map.panTo([lat,lng]); },[lat,lng,map]);
  return null;
}

export default function LiveMap({ driverLat, driverLng, pickupLat, pickupLng, dropoffLat, dropoffLng, driverStatus, observedAt, accuracy }: LiveMapProps) {
  const defaultCenter: [number, number] = [9.005401, 38.763611]; // Addis Ababa default
  const valid = (lat?: number | null,lng?: number | null) => lat != null && lng != null && Number.isFinite(lat) && Number.isFinite(lng) && Math.abs(lat)<=90 && Math.abs(lng)<=180;
  const hasDriver = valid(driverLat,driverLng);
  const center: [number, number] = hasDriver ? [driverLat!, driverLng!] : valid(pickupLat,pickupLng) ? [pickupLat!,pickupLng!] : defaultCenter;
  const [now,setNow] = useState(Date.now());
  useEffect(() => { const timer=setInterval(() => setNow(Date.now()),10000); return () => clearInterval(timer); },[]);
  const quality = gpsQuality({status:driverStatus,current_lat:driverLat,current_lng:driverLng,last_location_update:observedAt,location_accuracy_m:accuracy},now);

  const hasRoute = valid(pickupLat,pickupLng) && valid(dropoffLat,dropoffLng);
  const polylinePositions: [number, number][] = hasRoute 
    ? [[pickupLat!, pickupLng!], [dropoffLat!, dropoffLng!]]
    : [];

  return (
    <div className="rounded-xl overflow-hidden border border-neutral-200">
      <p className="bg-white px-3 py-2 text-xs font-medium text-neutral-600">Driver GPS: {hasDriver ? quality : 'no fix'} · {observedAt ? `Fix captured ${new Date(observedAt).toLocaleTimeString()}` : 'Fix time unknown'} · Accuracy {accuracy == null ? 'unknown' : `±${Math.round(accuracy)} m`}. Lines connect stops directly.</p>
      <div style={{height:400,width:'100%'}}>
      <MapContainer center={center} zoom={13} style={{ height: '100%', width: '100%' }}>
        <FollowDriver lat={hasDriver ? driverLat : null} lng={hasDriver ? driverLng : null}/>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        
        {/* Driver Location */}
        {hasDriver && accuracy != null && accuracy > 0 && accuracy <= 1000 && <Circle center={[driverLat!,driverLng!]} radius={accuracy} pathOptions={{color:quality === 'live' ? '#10b981' : '#9ca3af',weight:1,fillOpacity:0.1}}/>}
        {hasDriver && (
          <Marker position={[driverLat!, driverLng!]} icon={iconDriver}>
            <Popup>Driver position · {quality} · {driverLat?.toFixed(6)}, {driverLng?.toFixed(6)}</Popup>
          </Marker>
        )}

        {/* Pickup Location */}
        {valid(pickupLat,pickupLng) && (
          <Marker position={[pickupLat!, pickupLng!]} icon={iconPerson}>
            <Popup>Pickup</Popup>
          </Marker>
        )}

        {/* Dropoff Location */}
        {valid(dropoffLat,dropoffLng) && (
          <Marker position={[dropoffLat!, dropoffLng!]} icon={iconPerson}>
            <Popup>Dropoff</Popup>
          </Marker>
        )}

        {/* Basic Route Line */}
        {hasRoute && (
          <Polyline pathOptions={{ color: 'blue', weight: 4, opacity: 0.6 }} positions={polylinePositions} />
        )}
      </MapContainer>
      </div>
    </div>
  );
}
