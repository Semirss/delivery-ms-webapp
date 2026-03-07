"use client";

import { useState, useRef, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Image from "next/image";

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

      setTimeout(() => setSubmitted(false), 5000);

    } catch (err: any) {
      setError(err.message || "Unexpected error occurred.");
    }

    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-neutral-900 text-neutral-100 flex flex-col justify-between">

      {/* Header */}
      <header className="px-6 py-6 border-b border-neutral-800 sticky top-0 z-50">
        <div className="max-w-6xl mx-auto flex justify-center items-center">
          <div className="flex items-center space-x-3">
            <div className="h-12 w-12 rounded-xl overflow-hidden">
              <Image src="/logo1.jpg" alt="Motorbike Logo" width={48} height={48} />
            </div>
            <h1 className="text-xl font-extrabold">MotoBike</h1>
          </div>
        </div>
      </header>

      {/* Main */}
      <main className="flex-1 flex justify-center items-center px-4 py-12">

        <div className="bg-neutral-800 border border-neutral-700 p-8 rounded-3xl w-full max-w-md">

          <h3 className="text-xl font-bold text-center mb-6">
            Book a Courier
          </h3>

          {submitted && (
            <div className="bg-green-500/10 border border-green-500/30 p-4 rounded-xl mb-4 text-center">
              🎉 Request Sent!
            </div>
          )}

          {error && (
            <div className="bg-red-500/10 border border-red-500/30 p-4 rounded-xl mb-4 text-center">
              {error}
            </div>
          )}

          <form ref={formRef} onSubmit={handleSubmit} className="space-y-4">

            <input
              name="customer_name"
              required
              placeholder="Your Name"
              className="w-full p-3 rounded-lg bg-neutral-900 border border-neutral-700"
            />

            <input
              name="customer_phone"
              required
              placeholder="Phone"
              className="w-full p-3 rounded-lg bg-neutral-900 border border-neutral-700"
            />

            <input
              name="pickup_location"
              required
              placeholder="Pickup Address"
              className="w-full p-3 rounded-lg bg-neutral-900 border border-neutral-700"
            />

            <input
              name="dropoff_location"
              required
              placeholder="Drop-off Address"
              className="w-full p-3 rounded-lg bg-neutral-900 border border-neutral-700"
            />

            <select
              name="package_type"
              className="w-full p-3 rounded-lg bg-neutral-900 border border-neutral-700"
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
              className="w-full p-3 rounded-lg bg-neutral-900 border border-neutral-700"
            >
              <option value="Bike">Bike</option>
              <option value="Motor">Motor</option>
            </select>

            <div className="text-center text-green-400 font-bold">
              {vehicleCategory === "Bike" ? "200 - 600 Birr" : "350 - 800 Birr"}
            </div>

            {/* FIXED BUTTON */}
            <button
              type="button"
              disabled={loading}
              onClick={() => formRef.current?.requestSubmit()}
              className="w-full py-4 bg-blue-600 hover:bg-blue-500 rounded-xl font-bold"
            >
              {loading ? "Dispatching..." : "Request Courier Now"}
            </button>

          </form>
        </div>
      </main>

      {/* Footer */}
      <footer className="text-center py-6 text-xs text-neutral-500">
        MotoBike © 2026
      </footer>

      {/* Contact FAB */}
      <div className="fixed bottom-5 right-5">

        <button
          onClick={() => setContactOpen(!contactOpen)}
          className="w-14 h-14 bg-blue-600 rounded-full text-white text-xl"
        >
          ☎
        </button>

        {contactOpen && (
          <div className="flex flex-col gap-2 mt-2 items-end">

            <a
              href={`tel:${CONTACT_PHONE}`}
              className="bg-green-500 p-3 rounded-full"
            >
              📞
            </a>

            <a
              href={`tel:${CONTACT_PHONE2}`}
              className="bg-teal-500 p-3 rounded-full"
            >
              📞
            </a>

            <a
              href={`mailto:${CONTACT_EMAIL}`}
              className="bg-blue-500 p-3 rounded-full"
            >
              ✉
            </a>

          </div>
        )}
      </div>

    </div>
  );
}