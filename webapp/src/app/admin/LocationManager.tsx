"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";
import { MapPin, Plus, RefreshCw, Search } from "lucide-react";

type LocationRow = {
  id: string;
  name: string;
  aliases: string[];
  latitude: number;
  longitude: number;
  source: string;
  google_place_id?: string | null;
  is_active: boolean;
};

const emptyForm = { name: "", aliases: "", latitude: "", longitude: "" };

export default function LocationManager() {
  const [locations, setLocations] = useState<LocationRow[]>([]);
  const [query, setQuery] = useState("");
  const [form, setForm] = useState(emptyForm);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [message, setMessage] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch(`/api/admin/locations?q=${encodeURIComponent(query)}`, {
        cache: "no-store",
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "Could not load locations.");
      setLocations(payload.locations || []);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Could not load locations.");
    } finally {
      setLoading(false);
    }
  }, [query]);

  useEffect(() => {
    const timer = window.setTimeout(load, 250);
    return () => window.clearTimeout(timer);
  }, [load]);

  async function addLocation(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setMessage("");
    try {
      const response = await fetch("/api/admin/locations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "Could not save location.");
      setForm(emptyForm);
      setMessage("Neighborhood saved. Client and web search can use it immediately.");
      await load();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Could not save location.");
    } finally {
      setSaving(false);
    }
  }

  async function sync(validateGoogle: boolean) {
    setSyncing(true);
    setMessage("Discovering mapped Addis Ababa neighborhoods…");
    try {
      const response = await fetch("/api/admin/locations/sync", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ validate_google: validateGoogle, google_limit: 100 }),
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "Location sync failed.");
      const validation = validateGoogle
        ? ` ${payload.google_validated} Google Place IDs added.`
        : "";
      setMessage(`${payload.synced} OpenStreetMap locations synced.${validation}`);
      await load();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Location sync failed.");
    } finally {
      setSyncing(false);
    }
  }

  async function toggle(location: LocationRow) {
    const response = await fetch(`/api/admin/locations/${location.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ is_active: !location.is_active }),
    });
    if (response.ok) await load();
  }

  return (
    <div className="space-y-6">
      <div className="rounded-3xl bg-white border border-neutral-200 p-6 shadow-sm">
        <div className="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
          <div>
            <h3 className="text-xl font-extrabold text-neutral-900">Addis Ababa location catalog</h3>
            <p className="text-sm text-neutral-500 mt-1 max-w-2xl">
              One Supabase catalog powers both the client app and web booking. OSM coordinates are stored permanently; Google validation stores only permitted Place IDs.
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button disabled={syncing} onClick={() => sync(false)} className="px-4 py-2.5 rounded-xl bg-neutral-900 text-white font-bold disabled:opacity-50 flex items-center gap-2">
              <RefreshCw className={`h-4 w-4 ${syncing ? "animate-spin" : ""}`} /> Sync OSM
            </button>
            <button disabled={syncing} onClick={() => sync(true)} className="px-4 py-2.5 rounded-xl bg-blue-600 text-white font-bold disabled:opacity-50">
              Sync + Google IDs
            </button>
          </div>
        </div>
        {message && <p className="mt-4 text-sm font-semibold text-blue-700 bg-blue-50 rounded-xl px-4 py-3">{message}</p>}
      </div>

      <form onSubmit={addLocation} className="rounded-3xl bg-white border border-neutral-200 p-6 shadow-sm">
        <h3 className="font-extrabold text-neutral-900 flex items-center gap-2"><Plus className="h-5 w-5" /> Add neighborhood manually</h3>
        <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-3 mt-4">
          <input required placeholder="Neighborhood name" value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} className="border border-neutral-300 rounded-xl px-4 py-3" />
          <input placeholder="Aliases, comma separated" value={form.aliases} onChange={(event) => setForm({ ...form, aliases: event.target.value })} className="border border-neutral-300 rounded-xl px-4 py-3" />
          <input required type="number" step="any" min="8.75" max="9.18" placeholder="Latitude" value={form.latitude} onChange={(event) => setForm({ ...form, latitude: event.target.value })} className="border border-neutral-300 rounded-xl px-4 py-3" />
          <input required type="number" step="any" min="38.55" max="39.02" placeholder="Longitude" value={form.longitude} onChange={(event) => setForm({ ...form, longitude: event.target.value })} className="border border-neutral-300 rounded-xl px-4 py-3" />
        </div>
        <button disabled={saving} className="mt-4 px-5 py-3 rounded-xl bg-blue-600 text-white font-extrabold disabled:opacity-50">
          {saving ? "Saving…" : "Save neighborhood"}
        </button>
      </form>

      <div className="rounded-3xl bg-white border border-neutral-200 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-neutral-200 flex flex-col sm:flex-row sm:items-center gap-3">
          <div className="relative flex-1">
            <Search className="h-4 w-4 absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
            <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search the saved catalog" className="w-full border border-neutral-300 rounded-xl pl-10 pr-4 py-3" />
          </div>
          <span className="text-sm font-bold text-neutral-500">{locations.length} records</span>
        </div>
        <div className="max-h-[620px] overflow-auto divide-y divide-neutral-100">
          {loading && <p className="p-8 text-center text-neutral-500">Loading locations…</p>}
          {!loading && locations.map((location) => (
            <div key={location.id} className={`p-4 flex items-center gap-4 ${location.is_active ? "" : "opacity-50"}`}>
              <div className="h-10 w-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center"><MapPin className="h-5 w-5" /></div>
              <div className="min-w-0 flex-1">
                <p className="font-extrabold text-neutral-900 truncate">{location.name}</p>
                <p className="text-xs text-neutral-500 truncate">{location.latitude.toFixed(5)}, {location.longitude.toFixed(5)} · {location.source}{location.google_place_id ? " · Google validated" : ""}</p>
              </div>
              <button onClick={() => toggle(location)} className={`px-3 py-2 rounded-lg text-xs font-bold ${location.is_active ? "bg-emerald-50 text-emerald-700" : "bg-neutral-100 text-neutral-600"}`}>
                {location.is_active ? "Active" : "Inactive"}
              </button>
            </div>
          ))}
          {!loading && locations.length === 0 && <p className="p-8 text-center text-neutral-500">No saved neighborhoods yet.</p>}
        </div>
        <p className="px-5 py-3 text-xs text-neutral-400 border-t border-neutral-100">Location data © OpenStreetMap contributors, ODbL 1.0.</p>
      </div>
    </div>
  );
}
