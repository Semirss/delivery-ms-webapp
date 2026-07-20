"use client";

import { useState } from "react";

type BackendConfig = {
  label: string;
  supabaseUrl: string;
  supabaseAnonKey: string;
  maskedAnonKey: string;
  hasServiceRoleKey: boolean;
  maskedServiceRoleKey: string;
  updatedAt?: string;
  source: "master" | "env";
};

export default function BackendManager() {
  const [pass, setPass] = useState("");
  const [unlocked, setUnlocked] = useState(false);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [config, setConfig] = useState<BackendConfig | null>(null);
  const [form, setForm] = useState({
    label: "production",
    supabaseUrl: "",
    supabaseAnonKey: "",
    supabaseServiceRoleKey: "",
  });

  async function loadConfig(nextPass = pass) {
    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const response = await fetch("/api/admin/backend-config", {
        cache: "no-store",
        headers: {
          "x-backend-pass": nextPass,
        },
      });
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Could not unlock backend section.");
      }

      setConfig(data);
      setForm({
        label: data.label || "production",
        supabaseUrl: data.supabaseUrl || "",
        supabaseAnonKey: data.supabaseAnonKey || "",
        supabaseServiceRoleKey: "",
      });
      setUnlocked(true);
    } catch (err: unknown) {
      setUnlocked(false);
      setError(
        err instanceof Error
          ? err.message
          : "Could not unlock backend section.",
      );
    } finally {
      setLoading(false);
    }
  }

  async function saveConfig(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError("");
    setSuccess("");

    try {
      const response = await fetch("/api/admin/backend-config", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "x-backend-pass": pass,
        },
        body: JSON.stringify({
          pass,
          ...form,
        }),
      });
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Could not save backend config.");
      }

      setSuccess("Backend config saved. New app launches will use this Supabase after the master config is reachable.");
      await loadConfig(pass);
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : "Could not save backend config.",
      );
    } finally {
      setSaving(false);
    }
  }

  if (!unlocked) {
    return (
      <div className="max-w-xl bg-white rounded-3xl border border-neutral-200 shadow-sm p-8">
        <div className="h-12 w-12 rounded-2xl bg-neutral-900 text-white flex items-center justify-center text-xl mb-5">
          🔐
        </div>
        <h2 className="text-2xl font-extrabold text-neutral-900">Backend Control</h2>
        <p className="text-sm text-neutral-500 mt-2">
          This section controls which Supabase project the published apps and website should use.
        </p>

        <div className="mt-5 rounded-2xl bg-amber-50 border border-amber-200 p-4 text-sm text-amber-900">
          Use this carefully. URL/anon changes affect new app starts. Server/admin APIs also need the matching service-role key.
        </div>

        <form
          className="mt-6 space-y-4"
          onSubmit={(event) => {
            event.preventDefault();
            loadConfig();
          }}
        >
          <div>
            <label className="block text-sm font-bold text-neutral-700 mb-2">Backend pass</label>
            <input
              value={pass}
              onChange={(event) => setPass(event.target.value)}
              type="password"
              placeholder="Enter backend pass"
              className="w-full rounded-2xl border border-neutral-300 px-4 py-3 outline-none focus:ring-2 focus:ring-orange-500"
            />
          </div>

          {error && (
            <div className="rounded-2xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-2xl bg-neutral-900 text-white py-3 font-extrabold disabled:opacity-50"
          >
            {loading ? "Unlocking..." : "Unlock Backend"}
          </button>
        </form>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="bg-white rounded-3xl border border-neutral-200 shadow-sm p-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-orange-600 font-black">Backend</p>
            <h2 className="text-2xl font-extrabold text-neutral-900 mt-1">Active Supabase Runtime</h2>
            <p className="text-sm text-neutral-500 mt-1">
              Source: <span className="font-bold">{config?.source}</span>
              {config?.updatedAt ? ` • Updated ${new Date(config.updatedAt).toLocaleString()}` : ""}
            </p>
          </div>
          <button
            type="button"
            onClick={() => loadConfig(pass)}
            className="rounded-2xl border border-neutral-300 px-4 py-2 font-bold text-neutral-700 hover:bg-neutral-50"
          >
            Refresh
          </button>
        </div>

        <div className="grid md:grid-cols-2 gap-4 mt-6">
          <div className="rounded-2xl bg-neutral-50 border border-neutral-200 p-4">
            <p className="text-xs font-black uppercase text-neutral-400">URL</p>
            <p className="font-mono text-sm text-neutral-800 break-all mt-2">{config?.supabaseUrl}</p>
          </div>
          <div className="rounded-2xl bg-neutral-50 border border-neutral-200 p-4">
            <p className="text-xs font-black uppercase text-neutral-400">Anon key</p>
            <p className="font-mono text-sm text-neutral-800 break-all mt-2">{config?.maskedAnonKey}</p>
          </div>
          <div className="rounded-2xl bg-neutral-50 border border-neutral-200 p-4 md:col-span-2">
            <p className="text-xs font-black uppercase text-neutral-400">Service role</p>
            <p className="font-mono text-sm text-neutral-800 break-all mt-2">
              {config?.hasServiceRoleKey ? config.maskedServiceRoleKey : "Not set"}
            </p>
          </div>
        </div>
      </div>

      <form onSubmit={saveConfig} className="bg-white rounded-3xl border border-neutral-200 shadow-sm p-6 space-y-5">
        <h3 className="text-xl font-extrabold text-neutral-900">Rotate active Supabase</h3>

        <div>
          <label className="block text-sm font-bold text-neutral-700 mb-2">Label</label>
          <input
            value={form.label}
            onChange={(event) => setForm((prev) => ({ ...prev, label: event.target.value }))}
            className="w-full rounded-2xl border border-neutral-300 px-4 py-3 outline-none focus:ring-2 focus:ring-orange-500"
          />
        </div>

        <div>
          <label className="block text-sm font-bold text-neutral-700 mb-2">Supabase URL</label>
          <input
            value={form.supabaseUrl}
            onChange={(event) => setForm((prev) => ({ ...prev, supabaseUrl: event.target.value }))}
            className="w-full rounded-2xl border border-neutral-300 px-4 py-3 outline-none focus:ring-2 focus:ring-orange-500"
            placeholder="https://project-ref.supabase.co"
          />
        </div>

        <div>
          <label className="block text-sm font-bold text-neutral-700 mb-2">Supabase anon key</label>
          <textarea
            value={form.supabaseAnonKey}
            onChange={(event) => setForm((prev) => ({ ...prev, supabaseAnonKey: event.target.value }))}
            className="w-full min-h-24 rounded-2xl border border-neutral-300 px-4 py-3 outline-none focus:ring-2 focus:ring-orange-500 font-mono text-sm"
            placeholder="Paste anon key"
          />
        </div>

        <div>
          <label className="block text-sm font-bold text-neutral-700 mb-2">Service-role key for web/admin APIs</label>
          <textarea
            value={form.supabaseServiceRoleKey}
            onChange={(event) => setForm((prev) => ({ ...prev, supabaseServiceRoleKey: event.target.value }))}
            className="w-full min-h-24 rounded-2xl border border-neutral-300 px-4 py-3 outline-none focus:ring-2 focus:ring-orange-500 font-mono text-sm"
            placeholder="Paste service-role key for the target project"
          />
          <p className="text-xs text-neutral-500 mt-2">
            This is never returned by the public app config endpoint.
          </p>
        </div>

        {error && (
          <div className="rounded-2xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        )}
        {success && (
          <div className="rounded-2xl bg-emerald-50 border border-emerald-200 px-4 py-3 text-sm text-emerald-700">
            {success}
          </div>
        )}

        <button
          type="submit"
          disabled={saving}
          className="rounded-2xl bg-orange-600 hover:bg-orange-500 text-white px-6 py-3 font-extrabold disabled:opacity-50"
        >
          {saving ? "Saving..." : "Save active backend"}
        </button>
      </form>
    </div>
  );
}
