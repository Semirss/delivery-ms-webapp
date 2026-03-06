"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Image from "next/image";

export default function Home() {
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false); // Renamed from success
  const [error, setError] = useState("");
  const [name, setName] = useState(""); // New state
  const [phone, setPhone] = useState(""); // New state
  const [pickup, setPickup] = useState(""); // New state
  const [dropoff, setDropoff] = useState(""); // New state
  const [packageType, setPackageType] = useState("Documents"); // New state, with default
  const [vehicleCategory, setVehicleCategory] = useState("Bike"); // Renamed from category
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!packageType || !pickup || !dropoff || !phone) {
       setError("Please fill out all fields.");
       return;
    }

    setLoading(true);
    setError("");

    try {
      // 1. Convert address string to Lat/Lng using Nominatim
      let pickupLat = null, pickupLng = null;
      let dropoffLat = null, dropoffLng = null;

      try {
          const pickupRes = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(pickup)}`);
          const pickupData = await pickupRes.json();
          if (pickupData && pickupData.length > 0) {
              pickupLat = parseFloat(pickupData[0].lat);
              pickupLng = parseFloat(pickupData[0].lon);
          }

          const dropoffRes = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(dropoff)}`);
          const dropoffData = await dropoffRes.json();
          if (dropoffData && dropoffData.length > 0) {
              dropoffLat = parseFloat(dropoffData[0].lat);
              dropoffLng = parseFloat(dropoffData[0].lon);
          }
      } catch (err) {
          console.warn("Geocoding failed, coordinates will be null", err);
      }

      // 2. Submit Delivery
      const res = await fetch("/api/deliveries", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
           customer_name: name || "Guest",
           customer_phone: phone,
           pickup_location: pickup,
           dropoff_location: dropoff,
           package_type: packageType,
           vehicle_category: vehicleCategory,
           pickup_lat: pickupLat,
           pickup_lng: pickupLng,
           dropoff_lat: dropoffLat,
           dropoff_lng: dropoffLng
        })
      });

      if (!res.ok) throw new Error("Failed to submit delivery.");
      
      setSubmitted(true);
      // Reset form fields after successful submission
      setName("");
      setPhone("");
      setPickup("");
      setDropoff("");
      setPackageType("Documents");
      setVehicleCategory("Bike");
      
      setTimeout(() => setSubmitted(false), 5000); // Optional: hide success message after a delay
    } catch (err: any) {
      setError(err.message || "An unexpected error occurred.");
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-neutral-900 font-sans text-neutral-100 flex flex-col justify-between selection:bg-blue-500/30">
      
      <header className="px-6 py-6 border-b border-neutral-800/50 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-6xl mx-auto flex items-center justify-center">
           <div className="flex items-center space-x-3">
             <div className="h-12 w-12 rounded-xl flex items-center justify-center overflow-hidden shadow-lg shadow-blue-500/30">
                <Image src="/logo1.jpg" alt="Motorbike Logo" width={48} height={48} className="object-cover" />
             </div>
             <h1 className="text-xl font-extrabold tracking-tight text-white capitalize">Motorbike</h1>
           </div>
        </div>
      </header>

      <main className="flex-1 flex flex-col justify-center py-12 px-4 sm:px-6 relative overflow-hidden">
        {/* Background glow effects */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-blue-600/20 rounded-full blur-[120px] pointer-events-none -z-10"></div>
        <div className="absolute top-0 right-[-10%] w-[400px] h-[400px] bg-emerald-500/10 rounded-full blur-[100px] pointer-events-none -z-10"></div>

        <div className="max-w-md mx-auto w-full items-center">

           {/* Right Form */}
           <div className="bg-neutral-800/80 text-center  backdrop-blur-xl border border-neutral-700/50 p-8 rounded-[2rem] shadow-2xl relative z-10 w-full max-w-md mx-auto">
                          <div className="inline-flex items-center space-x-2 bg-neutral-800/50 backdrop-blur-md border border-neutral-700/50 rounded-full px-8  py-1.5 shadow-sm text-sm font-bold text-blue-400">
                 <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse"></span>
                 <span>Now accepting requests</span>
              </div>
             <div className="text-center mb-6">
                <h3 className="text-xl font-extrabold pt-4 text-white">Book a Courier</h3>
                <p className="text-sm font-medium text-neutral-400 mt-1">Fill the details below</p>
             </div>

             {submitted && (
               <div className="mb-6 bg-emerald-500/10 border border-emerald-500/30 p-4 rounded-xl text-center shadow-inner">
                 <span className="text-3xl block mb-2">🎉</span>
                 <p className="font-extrabold text-emerald-400">Request Dispatched!</p>
                 <p className="text-xs text-emerald-500/80 mt-1 font-medium">We will assign a driver to you shortly. A driver will contact you for the delivery fee.</p>
               </div>
             )}
             
             {error && (
               <div className="mb-6 bg-rose-500/10 border border-rose-500/30 p-4 rounded-xl text-center shadow-inner animate-in fade-in">
                 <span className="text-3xl block mb-2">⚠️</span>
                 <p className="font-extrabold text-rose-400">Request Failed</p>
                 <p className="text-xs text-rose-500/80 mt-1 font-medium">{error}</p>
               </div>
             )}

             <form className="space-y-5" onSubmit={handleSubmit}>
               <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-neutral-400 mb-1.5 ml-1 uppercase tracking-wider">Your Name</label>
                    <input required type="text" name="customer_name" value={name} onChange={(e) => setName(e.target.value)} className="block w-full border border-neutral-700 rounded-xl shadow-sm p-3.5 bg-neutral-900/50 text-white placeholder-neutral-600 focus:ring-blue-500 focus:border-blue-500 sm:text-sm font-medium transition-all" placeholder="John Doe" />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-neutral-400 mb-1.5 ml-1 uppercase tracking-wider">Phone</label>
                    <input required type="tel" name="customer_phone" value={phone} onChange={(e) => setPhone(e.target.value)} className="block w-full border border-neutral-700 rounded-xl shadow-sm p-3.5 bg-neutral-900/50 text-white placeholder-neutral-600 focus:ring-blue-500 focus:border-blue-500 sm:text-sm font-medium transition-all" placeholder="089..." />
                  </div>
               </div>
               
               <div className="relative pl-7 space-y-4 before:absolute before:inset-y-0 before:left-[11px] before:w-0.5 before:bg-neutral-700 before:z-0 py-2">
                   <div className="relative z-10 flex items-center">
                     <span className="absolute -left-[30px] flex items-center justify-center w-6 h-6 bg-blue-500/20 text-blue-400 rounded-full text-[10px] ring-4 ring-neutral-800">🟢</span>
                     <div className="w-full">
                       <input required type="text" name="pickup_location" value={pickup} onChange={(e) => setPickup(e.target.value)} className="block w-full border border-neutral-700 rounded-xl shadow-sm px-4 py-3 bg-neutral-900/50 text-white placeholder-neutral-600 focus:ring-blue-500 focus:border-blue-500 sm:text-sm font-medium transition-all" placeholder="Pickup Address" />
                     </div>
                  </div>
                  <div className="relative z-10 flex items-center">
                     <span className="absolute -left-[30px] flex items-center justify-center w-6 h-6 bg-rose-500/20 text-rose-400 rounded-full text-[10px] ring-4 ring-neutral-800">📍</span>
                     <div className="w-full">
                       <input required type="text" name="dropoff_location" value={dropoff} onChange={(e) => setDropoff(e.target.value)} className="block w-full border border-neutral-700 rounded-xl shadow-sm px-4 py-3 bg-neutral-900/50 text-white placeholder-neutral-600 focus:ring-blue-500 focus:border-blue-500 sm:text-sm font-medium transition-all" placeholder="Drop-off Address" />
                     </div>
                  </div>
               </div>

               <div>
                 <label className="block text-xs font-bold text-neutral-400 mb-1.5 ml-1 uppercase tracking-wider">Package Details</label>
                 <select required name="package_type" value={packageType} onChange={(e) => setPackageType(e.target.value)} className="block w-full border border-neutral-700 rounded-xl shadow-sm p-3.5 bg-neutral-900/50 text-white focus:ring-blue-500 focus:border-blue-500 sm:text-sm font-medium transition-all">
                   <option value="Documents">Documents</option>
                   <option value="Small Box">Small Box</option>
                   <option value="Food/Groceries">Food / Groceries</option>
                   <option value="Electronics">Electronics</option>
                   <option value="Other">Other</option>
                 </select>
               </div>
               
               <div>
                 <label className="block text-xs font-bold text-neutral-400 mb-1.5 ml-1 uppercase tracking-wider">Vehicle Category</label>
                 <select required name="vehicle_category" value={vehicleCategory} onChange={(e) => setVehicleCategory(e.target.value)} className="block w-full border border-neutral-700 rounded-xl shadow-sm p-3.5 bg-neutral-900/50 text-white focus:ring-blue-500 focus:border-blue-500 sm:text-sm font-medium transition-all">
                   <option value="Bike">Bike</option>
                   <option value="Motor">Motor</option>
                 </select>
               </div>

               <div className="bg-neutral-900/50 border border-neutral-700/50 p-4 rounded-xl flex items-center justify-center space-x-3 shadow-inner">
                  <span className="text-2xl">{vehicleCategory === 'Bike' ? '🚲' : '🏍️'}</span>
                  <div>
                    <p className="text-xs font-bold text-neutral-400 uppercase tracking-widest">Estimated Price</p>
                    <p className="font-extrabold text-lg text-emerald-400">
                      {vehicleCategory === 'Bike' ? '200 - 600 Birr' : '350 - 800 Birr'}
                    </p>
                  </div>
               </div>
               
               <button disabled={loading} type="submit" className="w-full mt-2 py-4 px-4 rounded-xl shadow-xl shadow-blue-500/20 text-sm font-extrabold text-white bg-blue-600 hover:bg-blue-500 disabled:opacity-50 transition-all flex items-center justify-center group overflow-hidden relative">
                 <span className="relative z-10">{loading ? 'Dispatching...' : 'Request Courier Now'}</span>
                 <div className="absolute inset-0 h-full w-full bg-gradient-to-r from-blue-600 to-indigo-500 opacity-0 group-hover:opacity-100 transition-opacity"></div>
                 <span className="relative z-10 ml-2 group-hover:translate-x-1 transition-transform">→</span>
               </button>
             </form>
           </div>
        </div>
      </main>

      <footer className="py-6 text-center text-xs font-bold text-neutral-500 uppercase tracking-widest relative z-10">
        Motorbike © 2026. Made for efficiency.
      </footer>
    </div>
  );
}
