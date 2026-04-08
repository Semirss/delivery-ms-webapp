"use client";

import { useEffect, useState, useCallback, useRef } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import NetworkStatus from "../components/NetworkStatus";
import Image from "next/image";

type Delivery = {
  id: string;
  customer_name: string;
  pickup_location: string;
  dropoff_location: string;
  status: string;
  created_at: string;
  delivery_fee: string | null;
  package_type: string;
  customer_phone: string;
};

type Driver = {
  id: string;
  name: string;
  status: string;
  approval_status: string;
  vehicle_type?: string;
};

type DriverNotification = {
  id: string;
  customer_name: string;
  pickup_location: string;
  dropoff_location: string;
  created_at: string;
};

export default function DriverPortal() {
  const [driver, setDriver] = useState<Driver | null>(null);
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [loading, setLoading] = useState(false);
  const [authMode, setAuthMode] = useState<"login" | "signup">("login");
  const [authError, setAuthError] = useState("");
  const [showTelegramModal, setShowTelegramModal] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [modalConfig, setModalConfig] = useState<{
    isOpen: boolean; type: 'confirm' | 'alert'; title: string; message: string;
    onConfirm?: () => void; onCancel?: () => void;
  }>({ isOpen: false, type: 'alert', title: '', message: '' });
  const [apiError, setApiError] = useState(false);
  const [locationEnabled, setLocationEnabled] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [notifications, setNotifications] = useState<DriverNotification[]>([]);
  const [realtimeState, setRealtimeState] = useState<'connecting' | 'live' | 'reconnecting' | 'offline'>('offline');

  // ── Toast Notifications State ───────────────────────────────────────────────
  const [toasts, setToasts] = useState<{ id: number; message: string }[]>([]);
  const addToast = useCallback((message: string) => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, message }]);
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 5000);
  }, []);

  // ── Web Audio ping + vibration ────────────────────────────────────────
  const playPing = useCallback(() => {
    try {
      const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
      // First tone — high pitch
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.frequency.setValueAtTime(880, ctx.currentTime);
      gain1.gain.setValueAtTime(0.5, ctx.currentTime);
      gain1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4);
      osc1.start(ctx.currentTime);
      osc1.stop(ctx.currentTime + 0.4);
      // Second tone — slightly lower, slight delay
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.frequency.setValueAtTime(660, ctx.currentTime + 0.15);
      gain2.gain.setValueAtTime(0.4, ctx.currentTime + 0.15);
      gain2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.6);
      osc2.start(ctx.currentTime + 0.15);
      osc2.stop(ctx.currentTime + 0.6);
      setTimeout(() => ctx.close(), 1000);
    } catch (e) {
      console.warn('Audio ping failed', e);
    }
    // Vibration (mobile devices)
    if ('vibrate' in navigator) {
      navigator.vibrate([200, 100, 200]);
    }
  }, []);

  // Track previous count of Assigned jobs to detect new assignments.
  const prevAssignedIdsRef = useRef<Set<string>>(new Set());
  // Flag: skip diff on first fetch (just seed the Set silently)
  const initialFetchDoneRef = useRef(false);

  // ── fetchData wrapped in useCallback ────────────────────────────────────────
  // driverId passed explicitly so the fn never closes over stale driver state.
  const fetchData = useCallback(async (driverId?: string) => {
    const id = driverId ?? driver?.id;
    if (!id) return;
    try {
      const ts = Date.now();
      const res = await fetch(`/api/deliveries?driver_id=${id}&_t=${ts}`, { cache: 'no-store' });
      const data = await res.json();
      
      if (Array.isArray(data)) {
        const assignedDeliveries = data.filter((d: Delivery) => d.status === 'Assigned');
        const assignedIds = new Set(assignedDeliveries.map((d: Delivery) => d.id));

        if (!initialFetchDoneRef.current) {
          // First fetch — just seed the set silently, no alerts
          prevAssignedIdsRef.current = assignedIds;
          initialFetchDoneRef.current = true;
        } else {
          const newAssignments = assignedDeliveries.filter((d: Delivery) => !prevAssignedIdsRef.current.has(d.id));
          if (newAssignments.length > 0) {
            playPing();
            setUnreadCount(prev => prev + newAssignments.length);
            setNotifications(prev => {
              const next = [...newAssignments, ...prev];
              const uniqueById = new Map<string, DriverNotification>();
              next.forEach(item => {
                if (!uniqueById.has(item.id)) uniqueById.set(item.id, item);
              });
              return Array.from(uniqueById.values()).slice(0, 30);
            });
            const newest = newAssignments[0];
            addToast(`🛕 New assignment! Pick up from ${newest.pickup_location}`);
            // Browser system notification (if permission granted)
            if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
              new Notification('MotoBike — New Delivery!', {
                body: `Pick up from ${newest.pickup_location} → ${newest.dropoff_location}`,
                icon: '/favlogo1.png',
                tag: newest.id,
              });
            }
          }
          prevAssignedIdsRef.current = assignedIds;
        }
      }

      setDeliveries(Array.isArray(data) ? data : []);
      setApiError(false);
    } catch (err) {
      console.error(err);
      setApiError(true);
    }
  }, [driver?.id, playPing, addToast]);

  // Stable ref so realtime callbacks always call the latest fetchData
  const fetchDataRef = useRef(fetchData);
  useEffect(() => { fetchDataRef.current = fetchData; }, [fetchData]);
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const reconnectTimerRef = useRef<number | null>(null);
  const reconnectAttemptRef = useRef(0);

  // Authentication persistence
  useEffect(() => {
    const stored = localStorage.getItem('mvp_driver_session');
    if (stored) {
      setDriver(JSON.parse(stored));
    }
  }, []);

  const clearReconnectTimer = useCallback(() => {
    if (reconnectTimerRef.current !== null) {
      window.clearTimeout(reconnectTimerRef.current);
      reconnectTimerRef.current = null;
    }
  }, []);

  useEffect(() => {
    if (!driver?.id) {
      clearReconnectTimer();
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
        channelRef.current = null;
      }
      setRealtimeState('offline');
      return;
    }

    fetchDataRef.current(driver.id);

    const parsePayload = (payload: unknown) => {
      if (payload && typeof payload === 'object') return payload as Record<string, unknown>;
      return {};
    };

    const scheduleReconnect = () => {
      if (reconnectTimerRef.current !== null) return;
      setRealtimeState('reconnecting');
      const delay = Math.min(1000 * (2 ** reconnectAttemptRef.current), 10000);
      reconnectTimerRef.current = window.setTimeout(() => {
        reconnectTimerRef.current = null;
        connectRealtime();
      }, delay);
      reconnectAttemptRef.current += 1;
    };

    const connectRealtime = () => {
      clearReconnectTimer();
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
        channelRef.current = null;
      }

      setRealtimeState(reconnectAttemptRef.current > 0 ? 'reconnecting' : 'connecting');

      const channel = supabase
      .channel('deliveries-sync')
      .on('broadcast', { event: 'delivery_assigned' }, ({ payload }) => {
        const parsed = parsePayload(payload);
        const eventDriverId = typeof parsed.driver_id === 'string' ? parsed.driver_id : null;
        if (!eventDriverId || eventDriverId === driver.id) {
          setTimeout(() => fetchDataRef.current(driver.id), 100);
        }
      })
      .on('broadcast', { event: 'delivery_created' }, () => {
        // A new order was placed — re-fetch in case admin assigns immediately
        setTimeout(() => fetchDataRef.current(driver.id), 300);
      })
      .on('broadcast', { event: 'delivery_status_updated' }, ({ payload }) => {
        const parsed = parsePayload(payload);
        const eventDriverId = typeof parsed.driver_id === 'string' ? parsed.driver_id : null;
        if (!eventDriverId || eventDriverId === driver.id) {
          setTimeout(() => fetchDataRef.current(driver.id), 100);
        }
      })
      .on('broadcast', { event: 'driver_updated' }, ({ payload }) => {
        const parsed = parsePayload(payload);
        const eventDriverId = typeof parsed.driver_id === 'string' ? parsed.driver_id : null;
        if (eventDriverId === driver.id) {
          setTimeout(() => fetchDataRef.current(driver.id), 100);
        }
      })
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'deliveries', filter: `driver_id=eq.${driver.id}` },
        () => {
          setTimeout(() => fetchDataRef.current(driver.id), 300);
        }
      )
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'drivers', filter: `id=eq.${driver.id}` },
        (payload) => {
          setDriver(payload.new as Driver);
          localStorage.setItem('mvp_driver_session', JSON.stringify(payload.new));
        }
      )
      .subscribe((status) => {
        console.log('[Driver Realtime]', status);
        if (status === 'SUBSCRIBED') {
          reconnectAttemptRef.current = 0;
          setRealtimeState('live');
        }
        if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
          scheduleReconnect();
        }
      });

      channelRef.current = channel;
    };

    connectRealtime();

    const handleOnline = () => {
      reconnectAttemptRef.current = 0;
      connectRealtime();
      fetchDataRef.current(driver.id);
    };
    window.addEventListener('online', handleOnline);

    return () => {
      window.removeEventListener('online', handleOnline);
      clearReconnectTimer();
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
        channelRef.current = null;
      }
      setRealtimeState('offline');
    };
  }, [driver?.id, clearReconnectTimer]);

  useEffect(() => {
    if (!driver?.id) {
      setLocationEnabled(false);
      return;
    }

    let watchId: number;
    if (driver.status === 'Online' && 'geolocation' in navigator) {
      watchId = navigator.geolocation.watchPosition(
        async (position) => {
          setLocationEnabled(true);
          const { latitude, longitude } = position.coords;
          try {
            await fetch(`/api/drivers/${driver.id}/location`, {
              method: 'PATCH',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ lat: latitude, lng: longitude })
            });
          } catch (err) {
            console.error('Failed to update location', err);
          }
        },
        (error) => {
          console.error('GPS Error:', error);
          setLocationEnabled(false);
        },
        { enableHighAccuracy: true, maximumAge: 10000, timeout: 5000 }
      );
    } else {
      setLocationEnabled(false);
    }

    return () => {
      if (watchId) navigator.geolocation.clearWatch(watchId);
    };
  }, [driver?.id, driver?.status]);


  const handleAuth = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    setAuthError("");
    
    const formElement = e.currentTarget;
    const formData = new FormData(formElement);

    try {
      if (authMode === "login") {
        const data = Object.fromEntries(formData.entries());
        const res = await fetch("/api/drivers/login", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name: data.name, password: data.password })
        });
        
        if (!res.ok) throw new Error("Invalid name or password");
        const session = await res.json();
        
        if (session.approval_status === "Pending") {
           throw new Error("Waiting for approval. You cannot login until the admin approves your account.");
        }
        
        setDriver(session);
        localStorage.setItem('mvp_driver_session', JSON.stringify(session));

        // Request browser notification permission
        if (typeof Notification !== 'undefined' && Notification.permission === 'default') {
          Notification.requestPermission();
        }
      } else {
        const file = formData.get('personal_id') as File;
        if (file && file.size > 5 * 1024 * 1024 * 1024 * 1024 * 1024) throw new Error("ID photo must be under 2MB.");
        
        const res = await fetch("/api/drivers", {
          method: "POST",
          body: formData 
        });

        if (!res.ok) {
           const errData = await res.json();
           throw new Error(errData.error || "Signup failed. A driver with this details may already exist.");
        }
        
        setAuthMode("login");
        setAuthError("Signup successful! Please wait for admin approval to login.");
        formElement.reset();
      }
    } catch (err: any) {
      setAuthError(err.message);
    }
    setLoading(false);
  };

  const handleLogout = () => {
    setDriver(null);
    localStorage.removeItem('mvp_driver_session');
  };

  const updateDeliveryStatus = async (id: string, status: string, extraData?: Record<string, string>) => {
    const successMessages: Record<string, { title: string; message: string }> = {
      'Picked Up': { title: '🚲 En Route!', message: "Package picked up! You're now on the way to the customer." },
      'Delivered':  { title: '🏁 Delivered!', message: "Great work! The delivery has been completed successfully." },
      'Pending':    { title: '↩️ Rejected', message: "Delivery returned to pending and saved in admin cancelled/rejected history." },
    };
    // Optimistically update local state so the UI changes instantly
    setDeliveries(prev => prev.map(d => d.id === id ? { ...d, status } : d));
    try {
      await fetch(`/api/deliveries/${id}/status`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status, ...extraData })
      });
      const msg = successMessages[status] || { title: 'Updated!', message: `Status changed to ${status}.` };
      setModalConfig({
        isOpen: true, type: 'alert', title: msg.title, message: msg.message,
        onConfirm: () => setModalConfig(prev => ({ ...prev, isOpen: false }))
      });
    } catch (err) {
      console.error(err);
      setDeliveries(prev => prev.map(d => d.id === id ? { ...d, status: 'Assigned' } : d));
    }
  };

  const toggleOnlineStatus = async () => {
     if (!driver) return;
     // Optimistically update local state for instant feedback
     const newStatus = driver.status === "Online" ? "Offline" : "Online";
     setDriver({ ...driver, status: newStatus });
     
     try {
       await fetch(`/api/drivers/${driver.id}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ status: newStatus })
       });
     } catch (err) {
        console.error("Failed to toggle status");
        // Revert local state on failure
        setDriver({ ...driver, status: driver.status });
     }
  };

  const toggleVehicleType = async () => {
     if (!driver) return;
     const newType = driver.vehicle_type === "Motor" ? "Bike" : "Motor";
     setDriver({ ...driver, vehicle_type: newType });
     
     try {
       await fetch(`/api/drivers/${driver.id}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ vehicle_type: newType })
       });
     } catch (err) {
        console.error("Failed to toggle vehicle type");
        setDriver({ ...driver, vehicle_type: driver.vehicle_type });
     }
  };


  // --- AUTH VIEW ---
  if (!driver) {
    return (
      <div className="min-h-screen bg-neutral-50 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8 text-black font-sans bg-[url('https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=2070&auto=format&fit=crop')] bg-cover bg-center">
        <NetworkStatus apiError={apiError} />
        <div className="absolute inset-0 bg-neutral-900/40 backdrop-blur-sm"></div>

        {/* Telegram Signup Modal */}
        {showTelegramModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setShowTelegramModal(false)} />
            <div className="relative bg-white rounded-3xl shadow-2xl p-8 max-w-sm w-full text-center space-y-5 z-10">
              <div className="mx-auto w-16 h-16 bg-blue-50 rounded-2xl flex items-center justify-center">
                <span className="text-4xl">✈️</span>
              </div>
              <h3 className="text-2xl font-extrabold text-neutral-900">Sign Up via Telegram</h3>
              <p className="text-neutral-500 font-medium text-sm leading-relaxed">
                Driver accounts are created through our Telegram bot.<br />
                Open the bot, tap <strong>"I am a Driver"</strong> then <strong>"Sign Up"</strong> to register.
              </p>
              <a
                href="https://t.me/sgcherosbot"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center space-x-2 w-full py-4 bg-[#2AABEE] hover:bg-[#1d96d3] text-white font-extrabold rounded-2xl shadow-lg shadow-blue-500/20 transition-all"
              >
                <span className="text-xl">📲</span>
                <span>Open @sgcherosbot</span>
              </a>
              <button onClick={() => setShowTelegramModal(false)} className="text-sm font-bold text-neutral-400 hover:text-neutral-700 transition-colors">
                Dismiss
              </button>
            </div>
          </div>
        )}

        <div className="max-w-md w-full mx-auto space-y-8 relative z-10 p-8 bg-white/95 backdrop-blur-md rounded-3xl shadow-2xl border border-white/20">
          <div>
             <div className="mx-auto h-16 w-16 rounded-[1.2rem] flex items-center justify-center overflow-hidden shadow-xl shadow-blue-500/30">
                <Image src="/favlogo1.png" alt="Motorbike Logo" width={64} height={64} className="object-cover" />
             </div>
            <h2 className="mt-6 text-center text-3xl font-extrabold text-neutral-900 tracking-tight">MotoBike</h2>
            <p className="mt-1 text-center text-sm font-extrabold text-blue-600">Driver Portal</p>
            <p className="mt-1 text-center text-sm font-medium text-neutral-500">{authMode === 'login' ? 'Welcome back' : 'Join our fleet'}</p>
          </div>
          
            <form className="space-y-5" onSubmit={handleAuth}>
              {authError && (
                <div className={`p-4 ${authError.includes('successful') ? 'bg-emerald-50 text-emerald-600 border-emerald-200' : 'bg-red-50 text-red-600 border-red-200'} border rounded-xl text-sm text-center font-bold`}>
                  {authError}
                </div>
              )}
              
              {authMode === "login" ? (
                  <div className="space-y-4">
                     <div>
                       <label className="block text-sm font-bold text-neutral-700 mb-1.5 ml-1">Full Name</label>
                       <input required type="text" name="name" className="block w-full border-neutral-300 border rounded-xl shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all" placeholder="e.g. John Doe" />
                     </div>
                     <div>
                       <label className="block text-sm font-bold text-neutral-700 mb-1.5 ml-1">Password</label>
                       <input required type="password" name="password" className="block w-full border-neutral-300 border rounded-xl shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all" placeholder="••••••••" />
                     </div>
                  </div>
              ) : (
                  <div className="space-y-4 h-64 overflow-y-auto pr-2 custom-scrollbar">
                     <div>
                       <label className="block text-sm font-bold text-neutral-700 mb-1.5 ml-1">Full Name</label>
                       <input required type="text" name="name" className="block w-full border-neutral-300 border rounded-xl shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all" placeholder="e.g. John Doe" />
                     </div>
                     <div>
                       <label className="block text-sm font-bold text-neutral-700 mb-1.5 ml-1">Phone Number</label>
                       <input required type="tel" name="phone" className="block w-full border-neutral-300 border rounded-xl shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all" placeholder="0912345678" />
                     </div>
                     <div>
                       <label className="block text-sm font-bold text-neutral-700 mb-1.5 ml-1">Telegram Username <span className="text-xs text-neutral-400 font-normal ml-2">(To receive notifications)</span></label>
                       <input required type="text" name="telegram_username" className="block w-full border-neutral-300 border rounded-xl shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all" placeholder="@username" />
                     </div>
                     <div>
                       <label className="block text-sm font-bold text-neutral-700 mb-1.5 ml-1">Plate Number</label>
                       <input required type="text" name="plate_number" className="block w-full border-neutral-300 border rounded-xl shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all" placeholder="AA 12345" />
                     </div>
                     <div>
                       <label className="block text-sm font-bold text-neutral-700 mb-1.5 ml-1">Vehicle Type</label>
                       <select required name="vehicle_type" className="block w-full border-neutral-300 border rounded-xl shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all">
                         <option value="Bike">Bike</option>
                         <option value="Motor">Motor</option>
                       </select>
                     </div>
                     <div>
                       <label className="block text-sm font-bold text-neutral-700 mb-1.5 ml-1">Personal ID Photo <span className="text-xs text-red-400 ml-1">Max 5MB</span></label>
                       <input required type="file" accept="image/*" name="personal_id" className="block w-full border-neutral-300 border rounded-xl shadow-sm p-2 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all text-neutral-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100 cursor-pointer" />
                     </div>
                     <div>
                       <label className="block text-sm font-bold text-neutral-700 mb-1.5 ml-1">Password</label>
                       <input required type="password" name="password" className="block w-full border-neutral-300 border rounded-xl shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all" placeholder="••••••••" />
                     </div>
                  </div>
              )}

              <button disabled={loading} type="submit" className="w-full mt-6 py-4 px-4 rounded-xl shadow-xl shadow-blue-500/20 text-sm font-extrabold text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 transition-all">
                {loading ? 'Processing...' : (authMode === 'login' ? 'Sign In' : 'Submit Application')}
              </button>
              
              <div className="text-center pt-2 flex justify-between px-2">
                 <button type="button" onClick={() => setAuthMode(authMode === "login" ? "signup" : "login")} className="text-sm font-bold text-neutral-500 hover:text-blue-600 transition-colors">
                    {authMode === "login" ? "Need an account?" : "Already have an account?"}
                 </button>
                 <Link href="/" className="text-sm font-bold text-neutral-400 hover:text-neutral-900 transition-colors">Go Home</Link>
              </div>
            </form>
        </div>
      </div>
    );
  }

  // --- DASHBOARD VIEW (Mobile First) ---
  const activeJobs = deliveries.filter(d => ['Assigned', 'Picked Up'].includes(d.status));
  const pastJobs = deliveries.filter(d => ['Delivered', 'Cancelled'].includes(d.status));

  return (
    <div className="min-h-screen bg-neutral-100 pb-20 text-neutral-900 font-sans">
      <NetworkStatus apiError={apiError} />
      
      {/* Premium Header */}
      <div className="bg-white px-5 py-6 shadow-[0_4px_20px_-10px_rgba(0,0,0,0.1)] sticky top-0 z-20 rounded-b-3xl">
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center space-x-3">
             <div className="h-10 w-10 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center font-bold text-lg shadow-sm">
                {driver.name.charAt(0)}
             </div>
           <div>
             <h1 className="font-extrabold text-lg text-neutral-900 leading-tight">MotoBike</h1>
             <p className="text-xs font-bold text-neutral-400">Driver Portal · {driver.name}</p>
           </div>
          </div>
          <div className="flex items-center space-x-2">
            <button 
              onClick={() => {
                setUnreadCount(0);
                setNotificationsOpen(true);
              }}
              className="relative p-2 text-neutral-400 hover:text-blue-600 rounded-full hover:bg-neutral-50 transition-colors"
              title="Notifications"
            >
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
              </svg>
              {unreadCount > 0 && (
                <span className="absolute top-0 right-0 inline-flex items-center justify-center w-4 h-4 text-[10px] font-bold text-white bg-red-500 rounded-full shadow-sm animate-[bounce_1s_infinite]">
                  {unreadCount}
                </span>
              )}
            </button>
            <button onClick={handleLogout} className="text-neutral-400 hover:text-neutral-900 p-2 rounded-full hover:bg-neutral-50 transition-colors">
               <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
            </button>
          </div>
        </div>
        <div className="flex justify-end">
          <div className="flex items-center space-x-2 bg-neutral-50 py-1.5 px-3 rounded-full border border-neutral-100">
            <span className={`w-2.5 h-2.5 rounded-full shadow-[0_0_8px_rgba(34,197,94,0.6)] ${realtimeState === 'live' ? 'bg-green-500 animate-pulse' : realtimeState === 'reconnecting' || realtimeState === 'connecting' ? 'bg-amber-500 animate-pulse' : 'bg-neutral-400'}`}></span>
            <span className="text-[10px] font-bold text-neutral-500 uppercase tracking-widest leading-none">
              {realtimeState === 'live' ? 'Live Sync' : realtimeState === 'reconnecting' ? 'Reconnecting' : realtimeState === 'connecting' ? 'Connecting' : 'Offline'}
            </span>
          </div>
        </div>

        {/* GPS Warning label */}
        {driver.status === 'Online' && !locationEnabled && (
           <div className="mb-4 bg-red-50 border border-red-200 p-3 rounded-xl flex items-start space-x-3 shadow-sm">
              <span className="text-red-500 text-lg">⚠️</span>
              <div>
                  <h3 className="text-red-800 font-bold text-sm">Location Access Required</h3>
                  <p className="text-red-600 text-xs font-medium mt-0.5">Please allow GPS tracking in your browser so we can assign you nearby deliveries.</p>
              </div>
           </div>
        )}

        {/* Online Toggle & Vehicle Type */}
        <div className="grid grid-cols-2 gap-4">
            <div className="bg-neutral-50 p-4 rounded-2xl flex items-center justify-between border border-neutral-100 col-span-2 sm:col-span-1">
               <div className="flex items-center space-x-3">
                  <span className="text-xl">🏃</span>
                  <div>
                     <p className="font-bold text-neutral-800 text-sm">Status</p>
                     <p className="text-xs font-medium text-neutral-500">Ready to ride?</p>
                  </div>
               </div>
               
               <button 
                  onClick={toggleOnlineStatus}
                  className={`relative inline-flex h-8 w-14 items-center rounded-full transition-colors focus:outline-none ${driver.status === 'Online' ? 'bg-emerald-500' : 'bg-neutral-300'}`}
                >
                  <span className={`inline-block h-6 w-6 transform rounded-full bg-white transition-transform ${driver.status === 'Online' ? 'translate-x-7 shadow-sm' : 'translate-x-1 shadow-sm'}`} />
                </button>
            </div>

            <div className="bg-neutral-50 p-4 rounded-2xl flex items-center justify-between border border-neutral-100 col-span-2 sm:col-span-1">
               <div className="flex items-center space-x-3">
                  <span className="text-xl">{driver.vehicle_type === 'Motor' ? '🏍️' : '🚲'}</span>
                  <div>
                     <p className="font-bold text-neutral-800 text-sm">Vehicle</p>
                     <p className="text-xs font-medium text-neutral-500 text-blue-600">{driver.vehicle_type || 'Bike'}</p>
                  </div>
               </div>
               
               <button 
                  onClick={toggleVehicleType}
                  className="px-3 py-1.5 bg-white border border-neutral-200 text-neutral-600 text-xs font-bold rounded-lg shadow-sm hover:bg-neutral-50"
                >
                  Switch
                </button>
            </div>
        </div>
      </div>

      <div className="p-5 max-w-lg mx-auto space-y-8 mt-4">
        
        {/* Active Jobs */}
        <div>
          <div className="flex items-center justify-between mb-4 px-1">
             <h2 className="text-lg font-extrabold text-neutral-900 flex items-center">
                <span className="w-2.5 h-2.5 rounded-full bg-blue-500 mr-2 shadow-[0_0_8px_rgba(59,130,246,0.6)]"></span>
                Active Deliveries
             </h2>
             {activeJobs.length > 0 && <span className="bg-neutral-200 text-neutral-700 font-bold text-xs px-2 py-0.5 rounded-full">{activeJobs.length}</span>}
          </div>
          
          {loading && activeJobs.length === 0 ? (
             <div className="py-10 text-center text-neutral-400 font-medium">Syncing...</div>
          ) : (
            <div className="space-y-4">
              {activeJobs.map(job => (
                <div key={job.id} className="bg-white border border-neutral-100 rounded-[1.5rem] shadow-sm overflow-hidden flex flex-col group transition-all hover:shadow-md">
                  
                  {/* Status Banner */}
                  <div className={`px-5 py-3 font-extrabold text-xs uppercase tracking-wider ${job.status === 'Assigned' ? 'bg-amber-100 text-amber-800' : 'bg-indigo-100 text-indigo-800'}`}>
                    {job.status === 'Assigned' ? '⚡ Ready for Pickup' : '🚲 En Route to Customer'}
                  </div>
                  
                  <div className="p-5 space-y-4">
                    <p className="font-extrabold text-xl text-neutral-900">{job.customer_name}</p>
                    
                    <div className="relative pl-6 space-y-4 before:absolute before:inset-y-0 before:left-[11px] before:w-0.5 before:bg-neutral-200 before:z-0 py-1">
                       <div className="relative z-10 flex items-start">
                          <span className="absolute -left-[27px] flex items-center justify-center w-6 h-6 bg-blue-100 text-blue-500 rounded-full text-xs">🟢</span>
                          <div>
                             <p className="text-[10px] font-bold text-neutral-400 uppercase tracking-wide">Pickup Point</p>
                             <p className="text-neutral-800 font-bold mt-0.5 whitespace-pre-wrap">{job.pickup_location}</p>
                          </div>
                       </div>
                       <div className="relative z-10 flex items-start">
                           <span className="absolute -left-[27px] flex items-center justify-center w-6 h-6 bg-red-100 text-red-500 rounded-full text-xs">📍</span>
                          <div>
                             <p className="text-[10px] font-bold text-neutral-400 uppercase tracking-wide">Dropoff Point</p>
                             <p className="text-neutral-800 font-bold mt-0.5 whitespace-pre-wrap">{job.dropoff_location}</p>
                          </div>
                       </div>
                    </div>

                    {/* Show more active job details without needing to drop down */}
                    <div className="grid grid-cols-2 gap-4 mt-4 pt-4 border-t border-neutral-100">
                       <div>
                          <p className="text-[10px] font-bold text-neutral-400 uppercase">Package</p>
                          <p className="font-medium text-neutral-800 mt-0.5">{job.package_type}</p>
                       </div>
                       <div>
                          <p className="text-[10px] font-bold text-neutral-400 uppercase">Fee</p>
                          <p className="font-medium text-emerald-600 mt-0.5">{job.delivery_fee || 'TBD'}</p>
                       </div>
                       <div className="col-span-2">
                           <p className="text-[10px] font-bold text-neutral-400 uppercase">Call Customer</p>
                           <a href={`tel:${job.customer_phone}`} className="inline-flex items-center space-x-1.5 mt-1 font-bold text-blue-600 hover:text-blue-700 active:text-blue-800 transition-colors">
                             <span>📞</span>
                             <span className="underline underline-offset-2">{job.customer_phone}</span>
                           </a>
                        </div>
                    </div>
                  </div>
                  
                  <div className="p-4 bg-neutral-50/50 border-t border-neutral-100 space-y-3">
                    {job.status === 'Assigned' && (
                      <div className="flex space-x-3">
                        <button
                           onClick={() => updateDeliveryStatus(job.id, 'Pending', {
                             cancelled_by: 'driver_reject',
                             cancellation_reason: `Driver ${driver.name} rejected the delivery`
                           })}
                           className="w-1/3 py-4 bg-white text-rose-500 border border-neutral-200 font-extrabold rounded-xl hover:bg-rose-50 shadow-sm text-sm transition-colors"
                         >
                          Reject
                        </button>
                        <button onClick={() => updateDeliveryStatus(job.id, 'Picked Up')} className="w-2/3 py-4 bg-blue-600 shadow-lg shadow-blue-500/20 text-white font-extrabold rounded-xl hover:bg-blue-700 text-sm transition-all focus:ring-4 focus:ring-blue-500/30">
                          Confirm Pickup
                        </button>
                      </div>
                    )}
                    {job.status === 'Picked Up' && (
                      <button onClick={() => updateDeliveryStatus(job.id, 'Delivered')} className="w-full py-4 bg-emerald-500 shadow-lg shadow-emerald-500/20 text-white font-extrabold rounded-xl hover:bg-emerald-600 text-sm transition-all flex items-center justify-center space-x-2">
                        <span>🏁 Mark as Delivered</span>
                      </button>
                    )}
                  </div>
                </div>
              ))}
              {activeJobs.length === 0 && (
                <div className="bg-white/50 py-12 px-6 text-center rounded-[1.5rem] border-2 border-dashed border-neutral-200 text-neutral-400 shadow-sm flex flex-col items-center">
                   <span className="text-4xl mb-3">☕</span>
                   <p className="font-bold text-neutral-600">No active jobs</p>
                   <p className="text-sm mt-1">Take a break or switch to Online to receive dispatch.</p>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Past Jobs with Expandable Accordion */}
        <div className="pt-2">
          <h2 className="text-base font-extrabold text-neutral-900 mb-4 px-1 opacity-90">Past Deliveries ({pastJobs.length})</h2>
          <div className="space-y-3">
            {pastJobs.map(job => (
              <div key={job.id} className="bg-white border border-neutral-100 rounded-2xl overflow-hidden shadow-sm transition-all">
                <button 
                  onClick={() => setExpandedId(expandedId === job.id ? null : job.id)}
                  className="w-full p-4 flex justify-between items-center text-left hover:bg-neutral-50 transition-colors"
                >
                  <div>
                    <p className="font-bold text-sm text-neutral-800">{job.customer_name}</p>
                    <p className="text-[11px] font-bold text-neutral-400 mt-1 uppercase">{new Date(job.created_at).toLocaleDateString()}</p>
                  </div>
                  <div className="flex items-center space-x-3">
                     <span className={`text-[10px] font-extrabold uppercase tracking-wide px-2 py-1 rounded-md ${job.status === 'Delivered' ? 'bg-emerald-50 text-emerald-600' : 'bg-neutral-100 text-neutral-500'}`}>{job.status}</span>
                     <svg className={`w-5 h-5 text-neutral-400 transition-transform ${expandedId === job.id ? 'rotate-180' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
                  </div>
                </button>
                
                {/* Expandable Content Target */}
                <div className={`transition-all duration-300 ease-in-out ${expandedId === job.id ? 'max-h-[500px] border-t border-neutral-100' : 'max-h-0'}`}>
                   <div className="p-4 bg-neutral-50/50 space-y-3 text-sm">
                      <div className="grid grid-cols-2 gap-4">
                         <div>
                            <p className="text-[10px] font-bold text-neutral-400 uppercase">Package</p>
                            <p className="font-medium text-neutral-800 mt-0.5">{job.package_type}</p>
                         </div>
                         <div>
                            <p className="text-[10px] font-bold text-neutral-400 uppercase">Fee</p>
                            <p className="font-medium text-emerald-600 mt-0.5">{job.delivery_fee ? `${job.delivery_fee} Birr` : 'TBD'}</p>
                         </div>
                      </div>
                      <div className="space-y-2 pt-2 border-t border-neutral-100">
                         <div className="flex start">
                            <span className="text-neutral-400 text-xs mr-2 mt-0.5">🟢</span>
                            <span className="font-medium text-neutral-600 text-xs">{job.pickup_location}</span>
                         </div>
                         <div className="flex start">
                            <span className="text-neutral-400 text-xs mr-2 mt-0.5">📍</span>
                            <span className="font-medium text-neutral-600 text-xs">{job.dropoff_location}</span>
                         </div>
                      </div>
                      <div className="pt-3 flex justify-end">
                         <a href={`tel:${job.customer_phone}`} className="px-4 py-2 bg-neutral-200 hover:bg-neutral-300 text-neutral-700 font-bold text-xs rounded-lg transition-colors flex items-center space-x-2">
                            <span>📞</span> <span>Call Customer</span>
                         </a>
                      </div>
                   </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {notificationsOpen && (
        <div className="fixed inset-0 z-[70] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-neutral-900/60 backdrop-blur-sm" onClick={() => setNotificationsOpen(false)}></div>
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-xl overflow-hidden relative z-10">
            <div className="p-6 border-b border-neutral-100 flex items-center justify-between">
              <h3 className="text-xl font-extrabold text-neutral-900">Notifications</h3>
              <div className="flex items-center space-x-2">
                <button onClick={() => { setNotifications([]); setUnreadCount(0); }} className="px-3 py-1.5 bg-red-50 text-red-600 rounded-lg text-sm font-bold hover:bg-red-100">Clear</button>
                <button onClick={() => setNotificationsOpen(false)} className="px-3 py-1.5 bg-neutral-100 text-neutral-700 rounded-lg text-sm font-bold hover:bg-neutral-200">Close</button>
              </div>
            </div>
            <div className="max-h-[60vh] overflow-y-auto p-4 space-y-3">
              {notifications.length === 0 && (
                <div className="py-10 text-center text-neutral-500 font-medium">No assignment notifications yet.</div>
              )}
              {notifications.map((note) => (
                <div key={note.id} className="bg-neutral-50 border border-neutral-200 rounded-2xl p-4">
                  <p className="text-sm font-extrabold text-neutral-900">Customer: {note.customer_name || 'Customer'}</p>
                  <p className="text-xs text-neutral-500 mt-1">Pickup: {note.pickup_location}</p>
                  <p className="text-xs text-neutral-500 mt-1">Dropoff: {note.dropoff_location}</p>
                  <p className="text-[11px] text-neutral-400 mt-2">{new Date(note.created_at).toLocaleString()}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Driver Custom Modal */}
      {modalConfig.isOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-neutral-900/60 backdrop-blur-sm" onClick={modalConfig.onCancel || modalConfig.onConfirm}></div>
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-sm overflow-hidden relative z-10 animate-in fade-in zoom-in duration-200">
             <div className="p-6">
                <h3 className="text-xl font-extrabold text-neutral-900 mb-2">{modalConfig.title}</h3>
                <p className="text-sm font-medium text-neutral-500 mb-6">{modalConfig.message}</p>
                <div className="flex space-x-3 justify-end">
                   {modalConfig.type === 'confirm' && (
                      <button type="button" onClick={modalConfig.onCancel} className="px-5 py-2.5 bg-neutral-100 text-neutral-600 font-bold rounded-xl hover:bg-neutral-200 transition-colors text-sm w-full flex-1">Cancel</button>
                   )}
                   <button type="button" onClick={modalConfig.onConfirm} className="px-5 py-2.5 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 shadow-lg shadow-blue-500/20 transition-all text-sm w-full flex-1">
                      {modalConfig.type === 'alert' ? 'OK' : 'Confirm'}
                   </button>
                </div>
             </div>
          </div>
        </div>
      )}

      {/* Driver Toast Notifications */}
      <div className="fixed bottom-24 left-4 right-4 z-[9999] flex flex-col items-center space-y-2 pointer-events-none">
        {toasts.map(toast => (
          <div key={toast.id} className="bg-neutral-900 text-white w-full max-w-sm px-5 py-4 rounded-xl shadow-2xl font-semibold text-sm border border-neutral-700/50 flex items-start space-x-3 transition-all duration-300 opacity-100">
            <span className="text-yellow-400 mt-0.5">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path></svg>
            </span>
            <span className="leading-snug flex-1">{toast.message}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
