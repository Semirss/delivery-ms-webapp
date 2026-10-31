"use client";

import { useCallback, useEffect, useState } from "react";

type BackendStatus = {
  environment: string;
  supabaseUrl: string;
  publicSupabaseUrl: string;
  urlsMatch: boolean;
  serviceRoleConfigured: boolean;
  sessionSecretConfigured: boolean;
  deploymentCommit: string | null;
};

export default function BackendManager() {
  const [status, setStatus] = useState<BackendStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const response = await fetch("/api/admin/backend-config", { cache: "no-store" });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Could not load backend status.");
      setStatus(data);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Could not load backend status.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  return (
    <div className="max-w-4xl space-y-5">
      <div className="rounded-3xl border border-neutral-200 bg-white p-6 shadow-sm">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h3 className="text-xl font-extrabold text-neutral-900">Active backend</h3>
            <p className="mt-1 text-sm text-neutral-500">Configuration used by this web deployment.</p>
          </div>
          <button type="button" onClick={() => void load()} disabled={loading}
            className="rounded-xl border border-neutral-300 px-4 py-2 font-bold text-neutral-700 disabled:opacity-50">
            {loading ? "Loading..." : "Refresh"}
          </button>
        </div>

        {error && <p role="alert" className="mt-5 rounded-xl bg-red-50 p-4 text-red-700">{error}</p>}
        {status && <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <StatusField label="Environment" value={status.environment} />
          <StatusField label="Deployment commit" value={status.deploymentCommit ?? "Unavailable"} />
          <StatusField label="Server Supabase URL" value={status.supabaseUrl || "Missing"} />
          <StatusField label="Public Supabase URL" value={status.publicSupabaseUrl || "Missing"} />
          <StatusField label="Server and public URLs" value={status.urlsMatch ? "Match" : "Mismatch"} healthy={status.urlsMatch} />
          <StatusField label="Service role key" value={status.serviceRoleConfigured ? "Configured" : "Missing"} healthy={status.serviceRoleConfigured} />
          <StatusField label="Session signing key" value={status.sessionSecretConfigured ? "Configured" : "Missing"} healthy={status.sessionSecretConfigured} />
        </div>}
      </div>

      <p className="rounded-2xl border border-blue-200 bg-blue-50 p-5 text-sm text-blue-900">
        The current mobile releases connect to the Supabase project set in their builds. This web
        deployment uses its Vercel environment. A backend switch in this panel would not redirect
        the current installed apps.
      </p>
    </div>
  );
}

function StatusField({ label, value, healthy }: { label: string; value: string; healthy?: boolean }) {
  return <div className="rounded-2xl border border-neutral-200 bg-neutral-50 p-4">
    <p className="text-xs font-bold uppercase tracking-wide text-neutral-500">{label}</p>
    <p className={`mt-2 break-all text-sm font-semibold ${healthy === false ? "text-red-700" : "text-neutral-900"}`}>{value}</p>
  </div>;
}
