"use client";

import { useEffect, useMemo, useState } from "react";

type AppKey = "client" | "driver";
type PlatformKey = "android" | "ios";

type AppVersion = {
  id?: string;
  app: AppKey;
  platform: PlatformKey;
  minimum_build: number;
  latest_build: number;
  latest_version: string;
  force_update: boolean;
  update_url: string;
  release_notes: string;
  maintenance_mode: boolean;
  maintenance_message: string;
  updated_at?: string;
};

const androidPlayStoreUrls: Record<AppKey, string> = {
  client: "https://play.google.com/store/apps/details?id=com.motobikedeliveryservice.client",
  driver: "https://play.google.com/store/apps/details?id=com.motobikedeliveryservice.driver",
};

const defaultRows: AppVersion[] = [
  {
    app: "client",
    platform: "android",
    minimum_build: 1,
    latest_build: 1,
    latest_version: "1.0.0",
    force_update: false,
    update_url: androidPlayStoreUrls.client,
    release_notes: "",
    maintenance_mode: false,
    maintenance_message: "",
  },
  {
    app: "client",
    platform: "ios",
    minimum_build: 1,
    latest_build: 1,
    latest_version: "1.0.0",
    force_update: false,
    update_url: androidPlayStoreUrls.driver,
    release_notes: "",
    maintenance_mode: false,
    maintenance_message: "",
  },
  {
    app: "driver",
    platform: "android",
    minimum_build: 1,
    latest_build: 1,
    latest_version: "1.0.0",
    force_update: false,
    update_url: "",
    release_notes: "",
    maintenance_mode: false,
    maintenance_message: "",
  },
  {
    app: "driver",
    platform: "ios",
    minimum_build: 1,
    latest_build: 1,
    latest_version: "1.0.0",
    force_update: false,
    update_url: "",
    release_notes: "",
    maintenance_mode: false,
    maintenance_message: "",
  },
];

function rowKey(row: Pick<AppVersion, "app" | "platform">) {
  return `${row.app}:${row.platform}`;
}

function labelFor(row: AppVersion) {
  const appLabel = row.app === "client" ? "Client App" : "Driver App";
  const platformLabel = row.platform === "android" ? "Android" : "iOS";
  return `${appLabel} - ${platformLabel}`;
}

function withDefaultUpdateUrl(row: AppVersion) {
  if (row.update_url.trim() || row.platform !== "android") return row;
  return { ...row, update_url: androidPlayStoreUrls[row.app] };
}

function errorMessage(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback;
}

export default function AppVersionManager() {
  const [versions, setVersions] = useState<AppVersion[]>(defaultRows);
  const [loading, setLoading] = useState(true);
  const [savingKey, setSavingKey] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [successKey, setSuccessKey] = useState<string | null>(null);

  const orderedVersions = useMemo(() => {
    const order = new Map(defaultRows.map((row, index) => [rowKey(row), index]));
    return [...versions].sort((a, b) => (order.get(rowKey(a)) ?? 99) - (order.get(rowKey(b)) ?? 99));
  }, [versions]);

  useEffect(() => {
    let cancelled = false;

    async function loadVersions() {
      try {
        const res = await fetch("/api/app-versions", { cache: "no-store" });
        if (!res.ok) throw new Error("Failed to load app versions");
        const data = await res.json();
        const byKey = new Map<string, AppVersion>();

        defaultRows.forEach((row) => byKey.set(rowKey(row), withDefaultUpdateUrl(row)));
        if (Array.isArray(data)) {
          data.forEach((row: AppVersion) => {
            if (row?.app && row?.platform) {
              byKey.set(rowKey(row), withDefaultUpdateUrl({ ...byKey.get(rowKey(row)), ...row }));
            }
          });
        }

        if (!cancelled) {
          setVersions(Array.from(byKey.values()));
          setError(null);
        }
      } catch (err: unknown) {
        if (!cancelled) setError(errorMessage(err, "Could not load app versions"));
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    loadVersions();
    return () => {
      cancelled = true;
    };
  }, []);

  function updateVersion(key: string, patch: Partial<AppVersion>) {
    setVersions((prev) => prev.map((row) => (rowKey(row) === key ? { ...row, ...patch } : row)));
    setSuccessKey(null);
  }

  async function saveVersion(row: AppVersion) {
    const key = rowKey(row);
    setSavingKey(key);
    setError(null);
    setSuccessKey(null);

    try {
      const payload = {
        ...row,
        minimum_build: Math.max(1, Number(row.minimum_build) || 1),
        latest_build: Math.max(1, Number(row.latest_build) || 1),
      };

      if (payload.latest_build < payload.minimum_build) {
        throw new Error("Latest build must be greater than or equal to minimum build");
      }

      const res = await fetch("/api/app-versions", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data?.error || "Failed to save app version");

      setVersions((prev) => prev.map((item) => (rowKey(item) === key ? data : item)));
      setSuccessKey(key);
    } catch (err: unknown) {
      setError(errorMessage(err, "Failed to save app version"));
    } finally {
      setSavingKey(null);
    }
  }

  if (loading) {
    return (
      <div className="bg-white rounded-2xl border border-neutral-200 p-10 text-center text-neutral-500 font-semibold">
        Loading app version policies...
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-2xl border border-neutral-200 p-6 shadow-sm">
        <p className="text-xs font-extrabold text-blue-600 uppercase tracking-widest">Release governance</p>
        <h3 className="text-2xl font-extrabold text-neutral-900 mt-2">Mobile App Versions</h3>
        <p className="text-sm text-neutral-500 mt-2 max-w-3xl">
          Set the minimum build each mobile app must run. When force update is enabled and an installed build is below
          the minimum, the app blocks normal use and shows the update message.
        </p>
        {error && (
          <div className="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700">
            {error}
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-5">
        {orderedVersions.map((row) => {
          const key = rowKey(row);
          const isSaving = savingKey === key;

          return (
            <div key={key} className="bg-white rounded-2xl border border-neutral-200 shadow-sm overflow-hidden">
              <div className="p-5 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                  <h4 className="text-lg font-extrabold text-neutral-900">{labelFor(row)}</h4>
                  <p className="text-xs text-neutral-400 mt-1">
                    {row.updated_at ? `Updated ${new Date(row.updated_at).toLocaleString()}` : "Not saved yet"}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-extrabold ${
                      row.force_update ? "bg-red-50 text-red-700" : "bg-emerald-50 text-emerald-700"
                    }`}
                  >
                    {row.force_update ? "Force update on" : "Force update off"}
                  </span>
                  {row.maintenance_mode && (
                    <span className="px-3 py-1 rounded-full text-xs font-extrabold bg-amber-50 text-amber-700">
                      Maintenance
                    </span>
                  )}
                </div>
              </div>

              <div className="p-5 space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <label className="space-y-1">
                    <span className="text-xs font-bold text-neutral-600">Minimum build</span>
                    <input
                      type="number"
                      min={1}
                      value={row.minimum_build}
                      onChange={(e) => updateVersion(key, { minimum_build: Number(e.target.value) || 1 })}
                      className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold focus:border-blue-500 focus:outline-none"
                    />
                  </label>
                  <label className="space-y-1">
                    <span className="text-xs font-bold text-neutral-600">Latest build</span>
                    <input
                      type="number"
                      min={1}
                      value={row.latest_build}
                      onChange={(e) => updateVersion(key, { latest_build: Number(e.target.value) || 1 })}
                      className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold focus:border-blue-500 focus:outline-none"
                    />
                  </label>
                  <label className="space-y-1">
                    <span className="text-xs font-bold text-neutral-600">Latest version</span>
                    <input
                      value={row.latest_version}
                      onChange={(e) => updateVersion(key, { latest_version: e.target.value })}
                      className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold focus:border-blue-500 focus:outline-none"
                    />
                  </label>
                </div>

                <label className="space-y-1 block">
                  <span className="text-xs font-bold text-neutral-600">Update URL</span>
                  <input
                    value={row.update_url}
                    onChange={(e) => updateVersion(key, { update_url: e.target.value })}
                    placeholder="https://play.google.com/store/apps/details?id=..."
                    className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold focus:border-blue-500 focus:outline-none"
                  />
                </label>

                <label className="space-y-1 block">
                  <span className="text-xs font-bold text-neutral-600">Release notes</span>
                  <textarea
                    value={row.release_notes}
                    onChange={(e) => updateVersion(key, { release_notes: e.target.value })}
                    rows={3}
                    className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold focus:border-blue-500 focus:outline-none"
                  />
                </label>

                <label className="space-y-1 block">
                  <span className="text-xs font-bold text-neutral-600">Maintenance message</span>
                  <textarea
                    value={row.maintenance_message}
                    onChange={(e) => updateVersion(key, { maintenance_message: e.target.value })}
                    rows={2}
                    placeholder="Optional message shown when maintenance mode is enabled."
                    className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold focus:border-blue-500 focus:outline-none"
                  />
                </label>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <label className="flex items-center justify-between rounded-xl border border-neutral-200 bg-neutral-50 px-4 py-3">
                    <span className="text-sm font-bold text-neutral-700">Force update</span>
                    <input
                      type="checkbox"
                      checked={row.force_update}
                      onChange={(e) => updateVersion(key, { force_update: e.target.checked })}
                      className="h-5 w-5"
                    />
                  </label>
                  <label className="flex items-center justify-between rounded-xl border border-neutral-200 bg-neutral-50 px-4 py-3">
                    <span className="text-sm font-bold text-neutral-700">Maintenance mode</span>
                    <input
                      type="checkbox"
                      checked={row.maintenance_mode}
                      onChange={(e) => updateVersion(key, { maintenance_mode: e.target.checked })}
                      className="h-5 w-5"
                    />
                  </label>
                </div>

                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pt-2">
                  <p className="text-xs text-neutral-400">
                    Installed builds below <span className="font-bold text-neutral-700">{row.minimum_build}</span> are blocked
                    when force update is on.
                  </p>
                  <button
                    onClick={() => saveVersion(row)}
                    disabled={isSaving}
                    className="px-5 py-2.5 bg-blue-600 text-white rounded-xl text-sm font-extrabold shadow-lg shadow-blue-500/20 hover:bg-blue-700 disabled:opacity-60"
                  >
                    {isSaving ? "Saving..." : successKey === key ? "Saved" : "Save Policy"}
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
