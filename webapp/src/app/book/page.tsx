"use client";

import { useState, useRef, useEffect } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { ArrowLeft, MapPin, Bike, CopyCheck, AlertCircle, ArrowRight } from "lucide-react";

const CONTACT_PHONE = "+251931323328";
const CONTACT_PHONE2 = "+251920202304";
const CONTACT_EMAIL = "Natnaeltegestuu@gmail.com";
const CONTACT_TELEGRAM = "motorbike_et";

export default function Book() {
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState("");
  const [vehicleCategory, setVehicleCategory] = useState("Bike");

  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const topRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (typeof window !== "undefined" && (window as any).Telegram?.WebApp) {
      (window as any).Telegram.WebApp.expand();
    }
  }, []);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (loading) return;

    setLoading(true);
    setError("");

    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData.entries());

    if (!data.customer_name || !data.customer_phone || !data.pickup_location || !data.dropoff_location) {
      setError("Please fill out all fields.");
      setLoading(false);
      return;
    }

    try {
      let pickupLat = null;
      let pickupLng = null;
      let dropoffLat = null;
      let dropoffLng = null;

      try {
        const pickupStr = data.pickup_location as string;
        const dropoffStr = data.dropoff_location as string;

        const pickupRes = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(pickupStr)}`);
        const pickupData = await pickupRes.json();
        if (pickupData?.length) {
          pickupLat = parseFloat(pickupData[0].lat);
          pickupLng = parseFloat(pickupData[0].lon);
        }

        const dropoffRes = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(dropoffStr)}`);
        const dropoffData = await dropoffRes.json();
        if (dropoffData?.length) {
          dropoffLat = parseFloat(dropoffData[0].lat);
          dropoffLng = parseFloat(dropoffData[0].lon);
        }
      } catch (err) {
        console.warn("Geocoding failed", err);
      }

      const res = await fetch("/api/deliveries", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...data,
          pickup_lat: pickupLat, pickup_lng: pickupLng,
          dropoff_lat: dropoffLat, dropoff_lng: dropoffLng
        })
      });

      if (!res.ok) throw new Error("Failed to submit delivery.");

      setSubmitted(true);
      formRef.current?.reset();
      setVehicleCategory("Bike");
      setTimeout(() => topRef.current?.scrollIntoView({ behavior: "smooth", block: "start" }), 100);
      setTimeout(() => setSubmitted(false), 5000);
    } catch (err: any) {
      setError(err.message || "Unexpected error occurred.");
      setTimeout(() => topRef.current?.scrollIntoView({ behavior: "smooth", block: "start" }), 100);
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-[#ebf0ee] text-neutral-900 flex flex-col font-sans selection:bg-purple-200">
      
      {/* Background Orbs */}
      <div className="fixed top-[10%] -left-[10%] w-[50%] h-[50%] bg-[#d3ede4]/60 blur-[130px] rounded-full pointer-events-none" />
      <div className="fixed bottom-[10%] -right-[10%] w-[60%] h-[60%] bg-[#e3eaff]/60 blur-[130px] rounded-full pointer-events-none" />

      {/* Header */}
      <header className="px-6 md:px-10 py-6 sticky top-0 z-40 bg-[#ebf0ee]/50 backdrop-blur-2xl border-b border-black/5">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <button onClick={() => router.push("/")} className="hover:bg-white/50 p-3 rounded-full transition-colors flex items-center space-x-2 text-sm font-semibold">
            <ArrowLeft className="w-5 h-5" />
            <span className="hidden sm:block">Back</span>
          </button>
          
          <div className="flex items-center space-x-3 cursor-pointer" onClick={() => router.push("/")}>
            <div className="h-10 w-10 rounded-xl overflow-hidden shadow-sm">
              <Image src="/favlogo1.png" alt="MotoBike Logo" width={40} height={40} className="object-cover" />
            </div>
            <h1 className="text-xl font-bold tracking-tight text-neutral-900">MotoBike</h1>
          </div>
          
          <div className="w-16" /> {/* Spacer */}
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex justify-center items-center px-4  relative z-10 w-full">
        <div 
          ref={topRef} 
          className=" p-8 sm:p-10 rounded-[2.5rem] w-full max-w-[500px] shadow-[0_20px_50px_rgba(0,0,0,0.04)] scroll-mt-32"
        >
          <div className="mb-10 text-center space-y-2">
            <h2 className="text-4xl font-medium tracking-tight text-neutral-900">Book Courier</h2>
            <p className="text-neutral-500 text-base">Enter details for rapid delivery</p>
          </div>

          {submitted && (
            <div className="bg-emerald-50 border border-emerald-100/50 text-emerald-700 p-5 rounded-3xl mb-8 flex items-center space-x-4 animate-in fade-in slide-in-from-top-4 shadow-sm">
              <div className="bg-emerald-100 p-2 rounded-full"><CopyCheck className="w-5 h-5 text-emerald-600" /></div>
              <span className="font-semibold text-sm">Request Sent Successfully!</span>
            </div>
          )}

          {error && (
            <div className="bg-red-50 border border-red-100/50 text-red-700 p-5 rounded-3xl mb-8 flex items-center space-x-4 animate-in fade-in slide-in-from-top-4 shadow-sm">
              <div className="bg-red-100 p-2 rounded-full"><AlertCircle className="w-5 h-5 text-red-600" /></div>
              <span className="font-semibold text-sm">{error}</span>
            </div>
          )}

          <form ref={formRef} onSubmit={handleSubmit} className="space-y-5">
            <div className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <input
                  name="customer_name" required placeholder="Full Name"
                  className="w-full px-5 py-4 rounded-2xl bg-[#f0f2f5] border-2 border-transparent focus:bg-white focus:border-black/10 focus:ring-4 focus:ring-black/5 transition-all outline-none text-neutral-900 font-medium placeholder:text-neutral-500 placeholder:font-normal"
                />
                <input
                  name="customer_phone" required placeholder="Phone Number" type="tel"
                  className="w-full px-5 py-4 rounded-2xl bg-[#f0f2f5] border-2 border-transparent focus:bg-white focus:border-black/10 focus:ring-4 focus:ring-black/5 transition-all outline-none text-neutral-900 font-medium placeholder:text-neutral-500 placeholder:font-normal"
                />
              </div>

              <div className="relative group">
                <div className="absolute left-5 top-1/2 -translate-y-1/2 flex flex-col items-center justify-center space-y-1">
                 <div className="w-3 h-3 border-2 border-blue-500 rounded-full" />
                 <div className="w-0.5 h-6 bg-neutral-300 rounded-full" />
                 <MapPin className="w-4 h-4 text-emerald-500 fill-emerald-100" />
                </div>
                <div className="space-y-3">
                  <input
                    name="pickup_location" required placeholder="Pickup Address"
                    className="w-full pl-12 pr-5 py-4 rounded-2xl bg-[#f0f2f5] border-2 border-transparent focus:bg-white focus:border-black/10 focus:ring-4 focus:ring-black/5 transition-all outline-none text-neutral-900 font-medium placeholder:text-neutral-500 placeholder:font-normal shadow-sm"
                  />
                  <input
                    name="dropoff_location" required placeholder="Drop-off Address"
                    className="w-full pl-12 pr-5 py-4 rounded-2xl bg-[#f0f2f5] border-2 border-transparent focus:bg-white focus:border-black/10 focus:ring-4 focus:ring-black/5 transition-all outline-none text-neutral-900 font-medium placeholder:text-neutral-500 placeholder:font-normal shadow-sm"
                  />
                </div>
              </div>

              <select
                name="package_type"
                className="w-full px-5 py-4 rounded-2xl bg-[#f0f2f5] border-2 border-transparent focus:bg-white focus:border-black/10 focus:ring-4 focus:ring-black/5 transition-all outline-none text-neutral-900 font-medium appearance-none shadow-sm cursor-pointer"
              >
                <option>Documents</option>
                <option>Small Box</option>
                <option>Food/Groceries</option>
                <option>Electronics</option>
                <option>Other</option>
              </select>
            </div>

            <div className="pt-2">
              <input type="hidden" name="vehicle_category" value={vehicleCategory} />
              <p className="text-sm font-semibold text-neutral-400 mb-3 px-1">Vehicle Type</p>
              <div className="grid grid-cols-2 gap-3">
                <div 
                  onClick={() => setVehicleCategory("Bike")}
                  className={`cursor-pointer p-4 rounded-2xl border-2 transition-all duration-300 flex flex-col items-center justify-center text-center space-y-2 ${
                    vehicleCategory === "Bike"
                      ? "bg-white border-black text-black shadow-lg shadow-black/5"
                      : "bg-[#f0f2f5] border-transparent text-neutral-500 hover:bg-[#e4e7ea]"
                  }`}
                >
                  <span className="text-3xl filter drop-shadow-sm">🚲</span>
                  <div className="flex flex-col">
                    <span className="text-sm font-bold">Bike</span>
                    <span className="text-xs font-semibold opacity-70">200-600 Br</span>
                  </div>
                </div>

                <div 
                  onClick={() => setVehicleCategory("Motor")}
                  className={`cursor-pointer p-4 rounded-2xl border-2 transition-all duration-300 flex flex-col items-center justify-center text-center space-y-2 ${
                    vehicleCategory === "Motor"
                      ? "bg-white border-black text-black shadow-lg shadow-black/5"
                      : "bg-[#f0f2f5] border-transparent text-neutral-500 hover:bg-[#e4e7ea]"
                  }`}
                >
                  <span className="text-3xl filter drop-shadow-sm">🏍️</span>
                  <div className="flex flex-col">
                    <span className="text-sm font-bold">Motorbike</span>
                    <span className="text-xs font-semibold opacity-70">350-800 Br</span>
                  </div>
                </div>
              </div>
            </div>

            <button
              type="submit" disabled={loading}
              className="w-full mt-6 py-5 bg-black text-white hover:bg-neutral-800 active:scale-[0.98] transition-all rounded-2xl font-bold text-lg disabled:opacity-70 flex items-center justify-center space-x-2 shadow-[0_10px_30px_rgba(0,0,0,0.15)] group"
            >
              <span>{loading ? "Dispatching Rider..." : "Request Vehicle Now"}</span>
              {!loading && <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />}
            </button>
          </form>
        </div>
      </main>

    </div>
  );
}