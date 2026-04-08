"use client";

import { useState, useRef, useEffect, useCallback } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { ArrowLeft, MapPin, CopyCheck, AlertCircle, ArrowRight, Loader2 } from "lucide-react";

const CONTACT_PHONE = "+251931323328";
const CONTACT_PHONE2 = "+251920202304";
const CONTACT_EMAIL = "Natnaeltegestuu@gmail.com";
const CONTACT_TELEGRAM = "motorbike_et";

// Pricing config
const PRICING = {
  Bike:  { base: 30, perKm: 50 },
  Motor: { base: 40, perKm: 60 },
};

// Comprehensive list of Addis Ababa neighborhoods / sub-cities / areas (300+)
const ADDIS_NEIGHBORHOODS = [
  // Sub-cities
  "Addis Ketema", "Akaki Kality", "Arada", "Bole", "Gulele",
  "Kirkos", "Kolfe Keranio", "Lideta", "Nifas Silk Lafto", "Yeka",
  "Lemi Kura",

  // Bole area
  "Bole Mikael", "Bole Michael", "Bole Rwanda", "Bole Atlas", "Bole Bulbula",
  "Bole Arabsa", "Bole 16", "Bole Medhanialem", "Bole Subcity", "Bole Airport",
  "Bole International Airport", "Old Airport", "CMC", "CMC Road", "CMC Michael",

  // Kazanchis / Piassa / Arada
  "Piassa", "Kazanchis", "Urael", "Arat Kilo", "Sidist Kilo", "Amist Kilo",
  "Abiot", "Afincho Ber", "Debre Damo", "Genet Hotel Area", "Haile Garment",
  "Ledeta", "Menilik Square", "Mercato Triangle", "Teklehaimanot",
  "Addis Ababa Stadium", "National Theatre", "Municipality Area",

  // Merkato & surroundings
  "Merkato", "Addis Merkato", "Gebre Guracha", "Shola Market", "Shola",
  "Kera", "Qera", "Gojam Berenda", "Kolfe", "Kolfe 01", "Kolfe Michael",
  "Autobus Tera", "Laghar", "Leghar", "Mexico", "Mexico Square",

  // Megenagna & surrounding
  "Megenagna", "Gerji", "Gerji Mebrat Hail", "Gerji Condominium",
  "Summit", "Summit Condominium", "Ayat", "Ayat Condominium",
  "Kotebe", "Kotebe Michael", "Kotebe Metro", "Kotebe College",
  "Yeka Michael", "Yeka Tafo", "Yeka Abado",

  // Sarbet / Gofa / Jemo
  "Sarbet", "Saris", "Saris Addis Sefer", "Gofa", "Gofa Sefer", "Gofa Mebrat",
  "Gofa Condominium", "Jemo", "Jemo 1", "Jemo 2", "Jemo 3",
  "Jemo Michael", "Mekanisa", "Mekanisa Abo", "Mekanisa Condominium",
  "Lebu", "Lebu Mebrat Hail", "Lebu Condominium", "Lebu Michael",
  "Nifas Silk", "Nifas Silk Condominium",

  // Kality / Akaki
  "Kality", "Kality Condominium", "Akaki", "Akaki Kality Industrial",
  "Gelan", "Gelan Condominium", "Gelan Industrial", "Akaki River",
  "Kilinto", "Dukem Road", "Bishoftu Road", "Mojo Road",

  // CMC / Koye / 44-Mazoria
  "Koye Feche", "Koye Condominium", "44 Mazoria", "Repi", "Repi Soap Factory",
  "Lafto", "Lafto Condominium", "Lafto 01", "Lafto Michael",

  // Tor Hailoch / Kazanchis belt
  "Tor Hailoch", "Tor Sefer", "Welo Sefer", "Wollo Sefer", "Lamberet",
  "Bambis", "Bethel", "Aware", "Aware Michael", "Beklo Bet",
  "Zenebework", "Wingate", "Shimedre Selam", "Qirqos",

  // Gulele / Entoto / Shiro Meda
  "Gulele", "Shiro Meda", "Entoto", "Entoto Park", "Entoto Mountain",
  "Mariam", "Kechene", "Kechene Medhanialem", "Abebaye", "Abissinia",
  "Lideta Condominium", "Lideta Michael", "Arat Kilo Student Area",

  // Old area / Ferensay / Imperial
  "Ferensay", "Ferensay Legasion", "Imperial", "Garibaldi", "Churchill Avenue",
  "Cherkos", "Meri", "Figa", "Goro", "Gotera", "Gotera Condominium",
  "Anbessa Sefer", "Dembel", "Dembel City Center",

  // Hospitals / Institutions
  "Tikur Anbessa", "Black Lion Hospital", "St. Paul Hospital", "ALERT Hospital",
  "ECA", "African Union", "UNECA", "Meles Zenawi Foundation",
  "Addis Ababa University", "Unity University", "Ethiopian Civil Service University",

  // Hotels / Landmarks
  "Hilton Hotel", "Sheraton", "Radisson Blu", "National Palace",
  "Meskel Square", "Maskel Square", "Stadium", "Abebe Bikila Stadium",
  "Martyrs Square", "Ras Hotel", "Jupiter Hotel", "Elilly Hotel",

  // Subcity specific woreda zones
  "Woreda 01", "Woreda 02", "Woreda 03", "Woreda 04", "Woreda 05",
  "Woreda 06", "Woreda 07", "Woreda 08", "Woreda 09", "Woreda 10",

  // Major roads as landmarks
  "Debre Zeit Road", "Jimma Road", "Ambo Road", "Debre Birhan Road",
  "Adama Road", "Welisso Road", "Shashamane Road", "Nekemte Road",

  // More residential/commercial pockets
  "Hana Mariam", "Hana Maria", "Liya Condominium", "Sunshine Condominium",
  "Total Area Bole", "Total Area CMC", "Doro Manekia", "Kality Prison",
  "Tulu Dimtu", "Beherawi Theatre", "Balcha Hospital", "Minilik Hospital",
  "Kidane Mihret", "Genet Amba", "Biruk Wenz", "Saris Abo", "Saris Mender",

  // Addis Ababa Ring Road areas
  "Ring Road", "Inner Ring Road", "Outer Ring Road", "4 Kilo", "6 Kilo",
  "Mexico Junction", "Bambis Junction", "Gotera Junction", "Ayat Junction",

  // Additional pockets
  "Bole Dembel", "Fiyel Bet", "Buna Temari", "Semit", "Semit Condominium",
  "Gurd Shola", "Gurd Shola Mall", "Gurd Shola Michael",
  "Lideta Market", "Saris Market", "Kera Market", "Shola Market",
  "Diplomatic Area", "Bole Diplomatic", "Old Airport Road",
  "Urael Church", "Meddhanialem", "Medhanialem", "Kidus Gabriel",
  "Debir Zeyit", "Yeka Condominium", "Ayat Real Estate", "Ayat 22",

  // Industrial/logistics zones
  "Lafto Industry", "Akaki Industry", "Megenagna Industry",
  "Bole Lemi", "Bole Lemi 2", "Bole Lemi Industry Park",

  // Farther edges still in Addis
  "Nifas Silk 21 Condominium", "Kaliti", "Kirkos Subcity",
  "Asko", "Asko Condominium", "Asko Mender", "Kolfe Condominium",
  "Lamberet Condominium", "Biruh Tesfa", "Biruh Tesfa Condominium",
  "Gemini Business Center", "Sunshine Real Estate", "Ayat City",
  "Entoto Observatory", "Entoto Natural Park",
  "Addis Ababa Science Museum", "Addis Ababa Train Station",
  "Light Rail Megenagna", "Light Rail Stadium", "Light Rail Mexico",
  "Teker", "Amanuel Hospital", "Yekatit 12 Hospital", "Zewditu Hospital",
  "Woldiya Sefer", "Godana Sefer", "Dereba", "Dereba Mender",
  "Finfine", "Finfine Condominium", "Meri Condominium",
];


// ── LocationInput Component ────────────────────────────────────────────────
function LocationInput({
  name, placeholder, value, onChange, icon
}: {
  name: string;
  placeholder: string;
  value: string;
  onChange: (v: string) => void;
  icon: React.ReactNode;
}) {
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [open, setOpen] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const v = e.target.value;
    onChange(v);
    if (v.trim().length >= 1) {
      const filtered = ADDIS_NEIGHBORHOODS.filter(n =>
        n.toLowerCase().includes(v.toLowerCase())
      ).slice(0, 7);
      setSuggestions(filtered);
      setOpen(filtered.length > 0);
    } else {
      setSuggestions([]);
      setOpen(false);
    }
  };

  const handleSelect = (neighborhood: string) => {
    onChange(neighborhood);
    setSuggestions([]);
    setOpen(false);
  };

  return (
    <div ref={containerRef} className="relative">
      <div className="relative">
        <div className="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none z-10">
          {icon}
        </div>
        <input
          ref={inputRef}
          name={name}
          required
          autoComplete="off"
          placeholder={placeholder}
          value={value}
          onChange={handleChange}
          onFocus={() => {
            if (suggestions.length > 0) setOpen(true);
          }}
          className="w-full pl-11 pr-5 py-4 rounded-2xl bg-[#f0f2f5] border-2 border-transparent focus:bg-white focus:border-black/10 focus:ring-4 focus:ring-black/5 transition-all outline-none text-neutral-900 font-medium placeholder:text-neutral-500 placeholder:font-normal shadow-sm"
        />
      </div>

      {/* Suggestions Dropdown */}
      {open && suggestions.length > 0 && (
        <div className="absolute left-0 right-0 top-full mt-1.5 bg-white rounded-2xl shadow-[0_8px_30px_rgba(0,0,0,0.10)] border border-neutral-100 z-50 overflow-hidden">
          {suggestions.map((s, i) => (
            <button
              key={s}
              type="button"
              onMouseDown={() => handleSelect(s)}
              className={`w-full flex items-center space-x-3 px-4 py-3 text-left text-sm font-medium text-neutral-800 hover:bg-neutral-50 transition-colors ${i !== suggestions.length - 1 ? "border-b border-neutral-50" : ""}`}
            >
              <MapPin className="w-4 h-4 text-neutral-400 flex-shrink-0" />
              <span>{s}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// ── Distance calculation via OSRM (real road distances from OSM) ──────────
async function getRoadDistanceKm(
  pickupText: string,
  dropoffText: string
): Promise<number | null> {
  try {
    // Smart geocode: try with "Addis Ababa, Ethiopia" suffix first,
    // then fall back to a plain OSM search so unknown neighborhoods still work.
    const geocode = async (q: string) => {
      const headers = { "User-Agent": "MotoBikeDelivery/1.0" };

      // 1st attempt: neighbourhood + city context
      const r1 = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(q + ", Addis Ababa, Ethiopia")}`,
        { headers }
      );
      const d1 = await r1.json();
      if (d1?.length) return { lat: parseFloat(d1[0].lat), lng: parseFloat(d1[0].lon) };

      // 2nd attempt: plain global search (handles custom / unknown areas)
      const r2 = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(q + ", Ethiopia")}`,
        { headers }
      );
      const d2 = await r2.json();
      if (d2?.length) return { lat: parseFloat(d2[0].lat), lng: parseFloat(d2[0].lon) };

      return null;
    };

    const [pickup, dropoff] = await Promise.all([
      geocode(pickupText),
      geocode(dropoffText),
    ]);

    if (!pickup || !dropoff) return null;

    // Get road distance from OSRM
    const osrmUrl = `https://router.project-osrm.org/route/v1/driving/${pickup.lng},${pickup.lat};${dropoff.lng},${dropoff.lat}?overview=false`;
    const osrmRes = await fetch(osrmUrl);
    const osrmData = await osrmRes.json();

    if (osrmData?.routes?.[0]?.distance) {
      return osrmData.routes[0].distance / 1000; // meters → km
    }
    return null;
  } catch {
    return null;
  }
}

function calcPrice(km: number, vehicle: "Bike" | "Motor"): number {
  const { base, perKm } = PRICING[vehicle];
  const raw = base + km * perKm;
  return Math.round(raw / 10) * 10; // round to nearest 10
}

// ── Main Component ─────────────────────────────────────────────────────────
export default function Book() {
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState("");
  const [vehicleCategory, setVehicleCategory] = useState<"Bike" | "Motor">("Bike");

  const [pickupValue, setPickupValue] = useState("");
  const [dropoffValue, setDropoffValue] = useState("");

  const [distanceKm, setDistanceKm] = useState<number | null>(null);
  const [priceEstimate, setPriceEstimate] = useState<number | null>(null);
  const [priceLoading, setPriceLoading] = useState(false);

  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const topRef = useRef<HTMLDivElement>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (typeof window !== "undefined" && (window as any).Telegram?.WebApp) {
      (window as any).Telegram.WebApp.expand();
    }
  }, []);

  // Recalculate price whenever pickup, dropoff, or vehicle changes
  useEffect(() => {
    if (!pickupValue.trim() || !dropoffValue.trim()) {
      setDistanceKm(null);
      setPriceEstimate(null);
      return;
    }

    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(async () => {
      setPriceLoading(true);
      const km = await getRoadDistanceKm(pickupValue, dropoffValue);
      if (km !== null) {
        setDistanceKm(km);
        setPriceEstimate(calcPrice(km, vehicleCategory));
      } else {
        setDistanceKm(null);
        setPriceEstimate(null);
      }
      setPriceLoading(false);
    }, 900);

    return () => { if (debounceRef.current) clearTimeout(debounceRef.current); };
  }, [pickupValue, dropoffValue, vehicleCategory]);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (loading) return;

    if (!pickupValue.trim() || !dropoffValue.trim()) {
      setError("Please fill out all fields.");
      return;
    }

    setLoading(true);
    setError("");

    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData.entries());

    // Use live price estimate as a number (DB-compatible)
    const feeValue = priceEstimate ?? null;

    try {
      let pickupLat = null, pickupLng = null, dropoffLat = null, dropoffLng = null;
      try {
        const geocode = async (q: string) => {
          const res = await fetch(
            `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(q + ", Addis Ababa, Ethiopia")}`,
            { headers: { "User-Agent": "MotoBikeDelivery/1.0" } }
          );
          return await res.json();
        };
        const [pd, dd] = await Promise.all([geocode(pickupValue), geocode(dropoffValue)]);
        if (pd?.length) { pickupLat = parseFloat(pd[0].lat); pickupLng = parseFloat(pd[0].lon); }
        if (dd?.length) { dropoffLat = parseFloat(dd[0].lat); dropoffLng = parseFloat(dd[0].lon); }
      } catch {}

      const res = await fetch("/api/deliveries", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          customer_name: data.customer_name,
          customer_phone: data.customer_phone,
          pickup_location: pickupValue,
          dropoff_location: dropoffValue,
          package_type: data.package_type,
          vehicle_category: vehicleCategory,
          delivery_fee: feeValue,
          pickup_lat: pickupLat, pickup_lng: pickupLng,
          dropoff_lat: dropoffLat, dropoff_lng: dropoffLng,
        })
      });

      if (!res.ok) {
        let errMsg = "Failed to submit delivery.";
        try { const errData = await res.json(); errMsg = errData.error || errMsg; } catch {}
        throw new Error(errMsg);
      }

      setSubmitted(true);
      formRef.current?.reset();
      setPickupValue("");
      setDropoffValue("");
      setVehicleCategory("Bike");
      setDistanceKm(null);
      setPriceEstimate(null);
      setTimeout(() => topRef.current?.scrollIntoView({ behavior: "smooth", block: "start" }), 100);
      setTimeout(() => setSubmitted(false), 5000);
    } catch (err: any) {
      setError(err.message || "Unexpected error occurred.");
      setTimeout(() => topRef.current?.scrollIntoView({ behavior: "smooth", block: "start" }), 100);
    }
    setLoading(false);
  };

  const { base, perKm } = PRICING[vehicleCategory];

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
          
          <div className="w-16" />
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex justify-center items-start px-4 py-8 relative z-10 w-full">
        <div 
          ref={topRef} 
          className="p-8 sm:p-10 rounded-[2.5rem] w-full max-w-[520px] shadow-[0_20px_50px_rgba(0,0,0,0.04)] scroll-mt-32"
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

              {/* Address Inputs with Neighborhood Autocomplete */}
              <div className="space-y-3 relative">
                {/* Route line decoration */}
                <div className="absolute left-[1.05rem] top-[3.4rem] bottom-[3.4rem] w-0.5 bg-neutral-300 rounded-full z-0 pointer-events-none" />

                <LocationInput
                  name="pickup_location"
                  placeholder="Pickup Neighborhood (e.g. Bole)"
                  value={pickupValue}
                  onChange={setPickupValue}
                  icon={<div className="w-3 h-3 border-2 border-blue-500 rounded-full bg-white" />}
                />
                <LocationInput
                  name="dropoff_location"
                  placeholder="Drop-off Neighborhood (e.g. Piassa)"
                  value={dropoffValue}
                  onChange={setDropoffValue}
                  icon={<MapPin className="w-4 h-4 text-emerald-500 fill-emerald-100" />}
                />
              </div>

              {/* Live Price Estimate Card */}
              {(priceLoading || priceEstimate !== null) && (
                <div className={`bg-white border rounded-2xl p-4 transition-all shadow-sm ${priceEstimate ? 'border-emerald-100' : 'border-neutral-100'}`}>
                  {priceLoading ? (
                    <div className="flex items-center space-x-3 text-neutral-500">
                      <Loader2 className="w-4 h-4 animate-spin" />
                      <span className="text-sm font-medium">Calculating distance...</span>
                    </div>
                  ) : priceEstimate !== null && distanceKm !== null ? (
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-xs font-bold text-neutral-400 uppercase tracking-wider">Estimated Price</p>
                        <p className="text-2xl font-bold text-neutral-900 mt-0.5">
                          {priceEstimate} <span className="text-base font-semibold text-neutral-500">Birr</span>
                        </p>
                        <p className="text-xs text-neutral-400 mt-1">
                          {distanceKm.toFixed(1)} km · {base} base + {distanceKm.toFixed(1)} × {perKm} Birr/km
                        </p>
                      </div>
                      <div className="flex flex-col items-end text-right">
                        <div className="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center text-xl mb-1">
                          {vehicleCategory === "Bike" ? "🚲" : "🏍️"}
                        </div>
                        <p className="text-[10px] font-bold text-neutral-400">Real road distance</p>
                      </div>
                    </div>
                  ) : null}
                </div>
              )}

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

            {/* Vehicle Type */}
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
                    <span className="text-xs font-semibold opacity-70">30 + 50/km Birr</span>
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
                    <span className="text-xs font-semibold opacity-70">40 + 60/km Birr</span>
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

            <p className="text-center text-xs text-neutral-400 pt-1">
              Final price confirmed by rider · {base} Birr base + {perKm} Birr/km for {vehicleCategory}
            </p>
          </form>
        </div>
      </main>
    </div>
  );
}
