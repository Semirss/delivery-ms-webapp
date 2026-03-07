"use client";

import { useState, useRef, useEffect } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";

// ── Contact details ──
const CONTACT_PHONE = "+251931323328";
const CONTACT_PHONE2 = "+251920202304";
const CONTACT_EMAIL = "Natnaeltegestuu@gmail.com";
const CONTACT_TELEGRAM = "motorbike_et";

export default function Home() {
  const [contactOpen, setContactOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState("");
  const [packageType, setPackageType] = useState("Documents");
  const [vehicleCategory, setVehicleCategory] = useState("Bike");

  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const topRef = useRef<HTMLDivElement>(null);

  // Telegram Mini App expand
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

        const pickupRes = await fetch(
          `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(pickupStr)}`
        );
        const pickupData = await pickupRes.json();

        if (pickupData?.length) {
          pickupLat = parseFloat(pickupData[0].lat);
          pickupLng = parseFloat(pickupData[0].lon);
        }

        const dropoffRes = await fetch(
          `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(dropoffStr)}`
        );
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
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          ...data,
          pickup_lat: pickupLat,
          pickup_lng: pickupLng,
          dropoff_lat: dropoffLat,
          dropoff_lng: dropoffLng
        })
      });

      if (!res.ok) throw new Error("Failed to submit delivery.");

      setSubmitted(true);
      formRef.current?.reset();
      setVehicleCategory("Bike");

      setTimeout(() => {
        topRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
      }, 100);

      setTimeout(() => setSubmitted(false), 5000);
    } catch (err: any) {
      setError(err.message || "Unexpected error occurred.");
      
      setTimeout(() => {
        topRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
      }, 100);
    }

    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-100 flex flex-col justify-between font-sans selection:bg-blue-500/30">

      {/* Header */}
      <header className="px-6 py-5 border-b border-neutral-800/50 bg-neutral-900/80 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-6xl mx-auto flex justify-center items-center">
          <div className="flex items-center space-x-3">
            <div className="h-10 w-10 rounded-xl overflow-hidden shadow-lg shadow-blue-500/20">
              <Image src="/logo1.jpg" alt="Motorbike Logo" width={40} height={40} className="object-cover" />
            </div>
            <h1 className="text-2xl font-black tracking-tight bg-gradient-to-br from-white to-neutral-400 bg-clip-text text-transparent">
              MotoBike
            </h1>
          </div>
        </div>
      </header>

      {/* Main */}
      <main className="flex-1 flex justify-center items-center px-4 py-8 relative">
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-full max-w-lg h-96 bg-blue-600/10 blur-[100px] rounded-full pointer-events-none" />

        <div 
          ref={topRef} 
          className="bg-neutral-900/80 backdrop-blur-xl border border-neutral-800 p-6 sm:p-8 rounded-3xl w-full max-w-md shadow-2xl relative z-10 scroll-mt-24"
        >
          <h3 className="text-2xl font-bold text-center mb-8 tracking-tight">
            Book a Courier
          </h3>

          {submitted && (
            <div className="bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 p-4 rounded-2xl mb-6 text-center font-medium animate-in fade-in slide-in-from-top-4">
              🎉 Request Sent Successfully!
            </div>
          )}

          {error && (
            <div className="bg-red-500/10 border border-red-500/30 text-red-400 p-4 rounded-2xl mb-6 text-center font-medium animate-in fade-in slide-in-from-top-4">
              {error}
            </div>
          )}

          <form ref={formRef} onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-3">
              <input
                name="customer_name"
                required
                placeholder="Your Name"
                className="w-full p-4 rounded-xl bg-neutral-950/50 border border-neutral-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all outline-none placeholder:text-neutral-500"
              />
              <input
                name="customer_phone"
                required
                placeholder="Phone Number"
                type="tel"
                className="w-full p-4 rounded-xl bg-neutral-950/50 border border-neutral-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all outline-none placeholder:text-neutral-500"
              />
              <input
                name="pickup_location"
                required
                placeholder="Pickup Address"
                className="w-full p-4 rounded-xl bg-neutral-950/50 border border-neutral-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all outline-none placeholder:text-neutral-500"
              />
              <input
                name="dropoff_location"
                required
                placeholder="Drop-off Address"
                className="w-full p-4 rounded-xl bg-neutral-950/50 border border-neutral-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all outline-none placeholder:text-neutral-500"
              />
            </div>

            <div className="grid grid-cols-2 gap-3 pt-2">
              <select
                name="package_type"
                className="w-full p-4 rounded-xl bg-neutral-950/50 border border-neutral-800 focus:border-blue-500 transition-all outline-none appearance-none"
              >
                <option>Documents</option>
                <option>Small Box</option>
                <option>Food/Groceries</option>
                <option>Electronics</option>
                <option>Other</option>
              </select>

              <select
                name="vehicle_category"
                value={vehicleCategory}
                onChange={(e) => setVehicleCategory(e.target.value)}
                className="w-full p-4 rounded-xl bg-neutral-950/50 border border-neutral-800 focus:border-blue-500 transition-all outline-none appearance-none"
              >
                <option value="Bike">Bike</option>
                <option value="Motor">Motor</option>
              </select>
            </div>

            <div
              className={`mt-2 p-4 rounded-2xl border transition-all duration-500 flex items-center justify-between ${
                vehicleCategory === "Bike"
                  ? "bg-blue-500/10 border-blue-500/30 shadow-[0_0_15px_rgba(59,130,246,0.1)]"
                  : "bg-purple-500/10 border-purple-500/30 shadow-[0_0_15px_rgba(168,85,247,0.1)]"
              }`}
            >
              <div className="flex items-center space-x-4">
                <span className="text-3xl filter drop-shadow-md">
                  {vehicleCategory === "Bike" ? "🚲" : "🏍️"}
                </span>
                <div className="flex flex-col">
                  <span className="text-xs font-medium text-neutral-400 uppercase tracking-wider">
                    Estimated Price
                  </span>
                  <span className="text-lg font-bold text-white">
                    {vehicleCategory === "Bike" ? "200 - 600 Birr" : "350 - 800 Birr"}
                  </span>
                </div>
              </div>
              <div
                className={`px-3 py-1 rounded-full text-xs font-bold ${
                  vehicleCategory === "Bike"
                    ? "bg-blue-500/20 text-blue-400"
                    : "bg-purple-500/20 text-purple-400"
                }`}
              >
                {vehicleCategory}
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full mt-6 py-4 bg-white text-neutral-950 hover:bg-neutral-200 focus:ring-4 focus:ring-white/20 active:scale-[0.98] transition-all rounded-xl font-bold text-lg disabled:opacity-70 disabled:active:scale-100"
            >
              {loading ? "Dispatching..." : "Request Courier Now"}
            </button>
          </form>
        </div>
      </main>

      <footer className="text-center py-6 text-xs font-medium text-neutral-600">
        MotoBike © 2026
      </footer>

      {/* Upward-Popping Contact FAB */}
      <div className="fixed bottom-6 right-6 z-50 flex flex-col items-end">
        <div
          className={`flex flex-col gap-3 mb-4 transition-all duration-300 origin-bottom ${
            contactOpen
              ? "opacity-100 scale-100 translate-y-0"
              : "opacity-0 scale-75 translate-y-10 pointer-events-none"
          }`}
        >
          {/* Telegram */}
          <button
            onClick={() => {
              if (typeof window !== "undefined") {
                const tg = (window as any).Telegram?.WebApp;
                const url = `https://t.me/${CONTACT_TELEGRAM}`;
                if (tg && tg.openTelegramLink) {
                  tg.openTelegramLink(url);
                } else {
                  window.open(url, "_blank");
                }
              }
            }}
            className="flex items-center justify-center w-12 h-12 bg-[#229ED9] hover:bg-[#1f8ec2] shadow-lg rounded-full text-white transition-transform hover:scale-110"
            aria-label="Telegram"
          >
            <svg className="w-5 h-5 ml-[-2px]" fill="currentColor" viewBox="0 0 24 24">
              <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.664 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/>
            </svg>
          </button>

          {/* Email - Fixed with target="_blank" */}
          <a
            href={`mailto:${CONTACT_EMAIL}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center w-12 h-12 bg-indigo-500 hover:bg-indigo-400 shadow-lg rounded-full text-white transition-transform hover:scale-110"
            aria-label="Email"
          >
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
            </svg>
          </a>

          {/* Phone 2 - Fixed with target="_blank" */}
          <a
            href={`tel:${CONTACT_PHONE2}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center w-12 h-12 bg-emerald-500 hover:bg-emerald-400 shadow-lg rounded-full text-white transition-transform hover:scale-110"
            aria-label="Call Alternative"
          >
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-2.896-1.596-5.48-4.18-7.076-7.076l1.293-.97c.362-.271.527-.733.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z" />
            </svg>
          </a>

          {/* Phone 1 - Fixed with target="_blank" */}
          <a
            href={`tel:${CONTACT_PHONE}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center w-12 h-12 bg-blue-500 hover:bg-blue-400 shadow-lg rounded-full text-white transition-transform hover:scale-110"
            aria-label="Call Main"
          >
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-2.896-1.596-5.48-4.18-7.076-7.076l1.293-.97c.362-.271.527-.733.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z" />
            </svg>
          </a>
        </div>

        {/* Main Toggle Button */}
        <button
          onClick={() => setContactOpen(!contactOpen)}
          className={`flex items-center justify-center w-16 h-16 rounded-full text-white shadow-xl transition-all duration-300 ${
            contactOpen ? "bg-neutral-700 rotate-45" : "bg-blue-600 hover:bg-blue-500"
          }`}
          aria-label="Contact Us"
        >
          {contactOpen ? (
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-6 h-6">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
          ) : (
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-7 h-7">
              <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z" />
            </svg>
          )}
        </button>
      </div>

    </div>
  );
}