"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import dynamic from 'next/dynamic';

const LiveMap = dynamic(() => import('../components/LiveMap'), { ssr: false });

type TrackedDelivery = {
  id: string;
  status: string;
  pickup_location: string;
  dropoff_location: string;
  pickup_lat: number | null;
  pickup_lng: number | null;
  dropoff_lat: number | null;
  dropoff_lng: number | null;
  driver?: {
     name: string;
     phone: string;
     vehicle_type: string;
     current_lat: number | null;
     current_lng: number | null;
  };
};

export default function TrackPage() {
  const [phoneNumber, setPhoneNumber] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [deliveries, setDeliveries] = useState<TrackedDelivery[]>([]);
  const [activeDelivery, setActiveDelivery] = useState<TrackedDelivery | null>(null);

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setDeliveries([]);
    setActiveDelivery(null);

    try {
      // In a real scenario, you'd create an endpoint like `/api/deliveries/track` that looks up by phone number.
      // For this MVP, we can reuse the generic fetch if we implement phone lookup, but it's cleaner to just fetch all and filter client side
      // or implement the specific route. Let's assume we create `/api/deliveries/search?phone=X`.
      const res = await fetch(`/api/deliveries?customer_phone=${encodeURIComponent(phoneNumber)}`);
      if (!res.ok) throw new Error("Could not fetch deliveries.");
      
      const data = await res.json();
      if (!Array.isArray(data) || data.length === 0) {
         setError("No deliveries found for this phone number.");
      } else {
         // Sort by created_at descending implicitly assuming the API returns them ordered, or do it here
         setDeliveries(data);
         if (data.length === 1) setActiveDelivery(data[0]);
      }
    } catch (err: any) {
      setError(err.message || "An error occurred during search.");
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-neutral-50 flex flex-col font-sans">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-md border-b border-neutral-200 sticky top-0 z-50">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-20 items-center">
            <Link href="/" className="flex items-center space-x-3 group">
              <div className="relative h-12 w-12 rounded-[1rem] overflow-hidden shadow-lg shadow-blue-500/20 group-hover:scale-105 transition-transform duration-300">
                <Image src="/logo.jpg" alt="Motorbike Dispatch" fill className="object-cover" />
              </div>
              <span className="font-extrabold text-xl tracking-tight text-neutral-900">
                Motor<span className="text-blue-600">bike</span>
              </span>
            </Link>
          </div>
        </div>
      </header>

      <main className="flex-1 w-full max-w-4xl mx-auto px-4 py-8 md:py-12 space-y-8">
         <div className="text-center space-y-3">
             <h1 className="text-3xl md:text-5xl font-extrabold text-neutral-900 tracking-tight">Track Your Package</h1>
             <p className="text-neutral-500 font-medium">Enter your phone number to see live delivery updates.</p>
         </div>
         
         {/* Search Box */}
         <div className="bg-white p-6 md:p-8 flex flex-col md:flex-row gap-4 rounded-[2rem] shadow-xl shadow-blue-900/5 hover:shadow-2xl transition-all border border-neutral-100">
             <form onSubmit={handleSearch} className="w-full flex flex-col md:flex-row gap-4">
                 <div className="flex-1 relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-xl">📱</span>
                    <input 
                       type="tel"
                       placeholder="e.g., +251 911 234 567"
                       className="w-full pl-12 pr-4 py-4 md:py-5 border-2 border-neutral-200 rounded-2xl focus:border-blue-600 focus:ring-0 text-lg font-bold bg-neutral-50 placeholder-neutral-400 transition-colors"
                       value={phoneNumber}
                       onChange={(e) => setPhoneNumber(e.target.value)}
                       required
                    />
                 </div>
                 <button 
                    type="submit" 
                    disabled={loading || !phoneNumber}
                    className="md:w-auto w-full px-8 py-4 md:py-5 bg-blue-600 text-white font-extrabold text-lg rounded-2xl shadow-lg shadow-blue-500/30 hover:bg-blue-700 hover:shadow-blue-500/50 hover:-translate-y-0.5 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2 shrink-0"
                 >
                    {loading ? (
                        <div className="w-6 h-6 border-4 border-white border-t-transparent rounded-full animate-spin" />
                    ) : (
                        <><span>🔍</span><span>Track</span></>
                    )}
                 </button>
             </form>
         </div>

         {error && (
             <div className="bg-red-50 text-red-600 font-bold p-4 rounded-xl text-center border border-red-200">
                 {error}
             </div>
         )}

         {/* Results */}
         {deliveries.length > 0 && !activeDelivery && (
             <div className="space-y-4">
                 <h3 className="font-extrabold text-xl text-neutral-800">Your Deliveries</h3>
                 {deliveries.map((delivery) => (
                     <button 
                        key={delivery.id} 
                        onClick={() => setActiveDelivery(delivery)}
                        className="w-full text-left bg-white p-5 rounded-2xl border border-neutral-200 shadow-sm hover:shadow-md transition-all flex items-center justify-between group"
                     >
                         <div>
                             <p className="font-bold text-neutral-900 text-lg group-hover:text-blue-600 transition-colors">{delivery.pickup_location.split(',')[0]} → {delivery.dropoff_location.split(',')[0]}</p>
                             <p className="text-sm font-medium text-neutral-500 mt-1">Status: <span className="font-bold text-neutral-700">{delivery.status}</span></p>
                         </div>
                         <span className="text-2xl opacity-50 group-hover:opacity-100 group-hover:translate-x-1 transition-all">➔</span>
                     </button>
                 ))}
             </div>
         )}

         {/* Tracking Map View */}
         {activeDelivery && (
             <div className="bg-white rounded-[2rem] border border-neutral-200 shadow-lg overflow-hidden flex flex-col">
                 <div className="p-6 md:p-8 bg-neutral-900 text-white flex justify-between items-start md:items-center flex-col md:flex-row gap-4">
                      <div>
                          <button onClick={() => setActiveDelivery(null)} className="text-neutral-400 hover:text-white font-bold text-sm mb-3 flex items-center space-x-1 transition-colors">
                              <span>←</span><span>Back to list</span>
                          </button>
                          <h2 className="text-2xl font-extrabold tracking-tight">Delivery Status</h2>
                          <div className="mt-2 inline-flex items-center px-3 py-1 rounded-full text-sm font-bold bg-white/10 border border-white/20">
                             {activeDelivery.status === 'Pending' ? '⏳ Finding Driver...' : 
                              activeDelivery.status === 'Assigned' ? '⚡ Driver Assigned' :
                              activeDelivery.status === 'Picked Up' ? '🚲 On the Way' : '🏁 Delivered'}
                          </div>
                      </div>
                      
                      {activeDelivery.driver && (['Assigned', 'Picked Up'].includes(activeDelivery.status)) && (
                          <div className="bg-white/10 p-4 rounded-2xl border border-white/10 md:text-right w-full md:w-auto">
                              <p className="text-xs uppercase font-bold text-neutral-400 tracking-wider">Your Driver</p>
                              <p className="font-extrabold text-lg mt-0.5 flex items-center md:justify-end">
                                 {activeDelivery.driver.vehicle_type === 'Motor' ? '🏍️' : '🚲'} 
                                 <span className="ml-2">{activeDelivery.driver.name}</span>
                              </p>
                              <a href={`tel:${activeDelivery.driver.phone}`} className="inline-block mt-2 text-blue-400 hover:text-blue-300 font-bold text-sm transition-colors flex items-center md:justify-end">
                                 📞 Call Driver
                              </a>
                          </div>
                      )}
                 </div>

                 {/* The Map */}
                 <div className="w-full bg-neutral-100 border-t border-neutral-200">
                     <LiveMap 
                         driverLat={activeDelivery.driver?.current_lat}
                         driverLng={activeDelivery.driver?.current_lng}
                         pickupLat={activeDelivery.pickup_lat}
                         pickupLng={activeDelivery.pickup_lng}
                         dropoffLat={activeDelivery.dropoff_lat}
                         dropoffLng={activeDelivery.dropoff_lng}
                     />
                 </div>
                 
                 <div className="p-6 md:p-8 bg-white grid grid-cols-1 md:grid-cols-2 gap-6">
                     <div className="space-y-2">
                        <p className="text-xs uppercase font-bold text-neutral-400">Pickup Origin</p>
                        <p className="font-bold text-neutral-800 pl-4 border-l-2 border-blue-500">{activeDelivery.pickup_location}</p>
                     </div>
                     <div className="space-y-2">
                        <p className="text-xs uppercase font-bold text-neutral-400">Dropoff Destination</p>
                        <p className="font-bold text-neutral-800 pl-4 border-l-2 border-red-500">{activeDelivery.dropoff_location}</p>
                     </div>
                 </div>
             </div>
         )}

      </main>
    </div>
  );
}
