"use client";

import { useState, useEffect, useCallback } from "react";

/**
 * NetworkStatus – shows a sticky banner when the browser goes offline.
 * Pass `apiError={true}` from parent to also show a "Slow connection" warning
 * when API calls are timing out even though the browser thinks it's online.
 */
export default function NetworkStatus({ apiError = false }: { apiError?: boolean }) {
  const [online, setOnline] = useState(true);

  useEffect(() => {
    const goOnline  = () => setOnline(true);
    const goOffline = () => setOnline(false);
    setOnline(navigator.onLine);
    window.addEventListener("online",  goOnline);
    window.addEventListener("offline", goOffline);
    return () => {
      window.removeEventListener("online",  goOnline);
      window.removeEventListener("offline", goOffline);
    };
  }, []);

  const show     = !online || apiError;
  const isOffline = !online;

  if (!show) return null;

  return (
    <div
      className={`fixed top-0 left-0 right-0 z-[999] flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-bold tracking-wide shadow-lg transition-all
        ${isOffline ? "bg-rose-600 text-white" : "bg-amber-400 text-amber-900"}`}
    >
      <span>{isOffline ? "📡" : "🐢"}</span>
      <span>
        {isOffline
          ? "No internet connection — changes may not be saved"
          : "Slow connection — the server is taking longer than usual"
        }
      </span>
      {!isOffline && (
        <span className="ml-2 animate-spin inline-block text-base">⏳</span>
      )}
    </div>
  );
}
