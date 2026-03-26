"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { supabase } from "@/lib/supabase";
import { useRouter } from "next/navigation";
import NetworkStatus from "../components/NetworkStatus";
import Image from "next/image";
import dynamic from 'next/dynamic';

const LiveMap = dynamic(() => import('../components/LiveMap'), { ssr: false });
const AllDriversMap = dynamic(() => import('../components/AllDriversMap'), { ssr: false });

// ── Types ───────────────────────────────────────────────────────────────────

type Delivery = {
  id: string;
  customer_name: string;
  customer_phone: string;
  pickup_location: string;
  dropoff_location: string;
  package_type: string;
  vehicle_category?: string;
  delivery_fee: string | null;
  status: string;
  driver_id: string | null;
  created_at: string;
  assigned_at?: string | null;
  cancelled_by?: string | null;
  cancellation_reason?: string | null;
  driver?: { name: string; phone: string; telegram_id: string; vehicle_type?: string; current_lat?: number; current_lng?: number; };
  pickup_lat?: number;
  pickup_lng?: number;
  dropoff_lat?: number;
  dropoff_lng?: number;
};

type Driver = {
  id: string;
  name: string;
  phone: string;
  telegram_id: string;
  telegram_username: string;
  plate_number: string;
  personal_id_url: string;
  status: string;
  approval_status: string;
  vehicle_type?: string;
  is_active?: boolean;
  current_lat?: number | null;
  current_lng?: number | null;
};

// ── Timeout config ───────────────────────────────────────────────────────────
const ASSIGN_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutes

function getSecondsLeft(assignedAt?: string | null): number {
  if (!assignedAt) return 0;
  const elapsed = Date.now() - new Date(assignedAt).getTime();
  return Math.max(0, Math.floor((ASSIGN_TIMEOUT_MS - elapsed) / 1000));
}

// ── Date filter helpers ──────────────────────────────────────────────────────
type DateRange = 'today' | 'week' | 'month' | 'all';

function filterByDate(deliveries: Delivery[], range: DateRange): Delivery[] {
  if (range === 'all') return deliveries;
  const now = new Date();
  return deliveries.filter(d => {
    const dt = new Date(d.created_at);
    if (range === 'today') {
      return dt.toDateString() === now.toDateString();
    }
    if (range === 'week') {
      const weekAgo = new Date(now); weekAgo.setDate(now.getDate() - 7);
      return dt >= weekAgo;
    }
    if (range === 'month') {
      return dt.getMonth() === now.getMonth() && dt.getFullYear() === now.getFullYear();
    }
    return true;
  });
}

// ── Analytics helpers ────────────────────────────────────────────────────────
function getLast7Days(deliveries: Delivery[]) {
  const days: { label: string; count: number }[] = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const label = d.toLocaleDateString('en-US', { weekday: 'short' });
    const count = deliveries.filter(del => new Date(del.created_at).toDateString() === d.toDateString()).length;
    days.push({ label, count });
  }
  return days;
}

// ── Main Component ────────────────────────────────────────────────────────────

export default function AdminDashboard() {
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"deliveries" | "drivers" | "pending" | "map" | "analytics">("deliveries");
  const [filterStatus, setFilterStatus] = useState<string>("All");
  const [dateRange, setDateRange] = useState<DateRange>('all');
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [apiError, setApiError] = useState(false);
  const [tickKey, setTickKey] = useState(0); // force countdown re-render
  const [assigningDelivery, setAssigningDelivery] = useState<Delivery | null>(null); // for map-assisted assignment
  const [modalConfig, setModalConfig] = useState<{
    isOpen: boolean; type: 'confirm' | 'alert' | 'prompt' | 'map'; title: string; message: string;
    fields?: { name: string; label: string; value: string }[];
    mapData?: { driverLat?: number; driverLng?: number; pickupLat?: number; pickupLng?: number; dropoffLat?: number; dropoffLng?: number; };
    onConfirm?: (data?: any) => void;
    onCancel?: () => void;
  }>({ isOpen: false, type: 'alert', title: '', message: '' });
  const router = useRouter();

  // ── Countdown ticker (every second) ──────────────────────────────────────
  useEffect(() => {
    const interval = setInterval(() => setTickKey(k => k + 1), 1000);
    return () => clearInterval(interval);
  }, []);

  // ── Auto-revert timed-out assigned deliveries (check every 30s) ──────────
  const checkTimeouts = useCallback(async () => {
    const now = Date.now();
    const timedOut = deliveries.filter(d =>
      d.status === 'Assigned' &&
      d.assigned_at &&
      now - new Date(d.assigned_at).getTime() > ASSIGN_TIMEOUT_MS
    );
    for (const d of timedOut) {
      try {
        await fetch(`/api/deliveries/${d.id}/status`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            status: 'Pending',
            cancelled_by: 'timeout',
            cancellation_reason: 'Driver did not accept within 2 minutes'
          })
        });
      } catch (e) {
        console.error('Failed to revert delivery', d.id, e);
      }
    }
    if (timedOut.length > 0) fetchData();
  }, [deliveries]);

  useEffect(() => {
    const interval = setInterval(checkTimeouts, 30000);
    return () => clearInterval(interval);
  }, [checkTimeouts]);

  // ── Auto-refresh + real-time ──────────────────────────────────────────────
  useEffect(() => {
    const intervalId = setInterval(fetchData, 120000);
    return () => clearInterval(intervalId);
  }, []);

  useEffect(() => {
    fetchData();
    const deliverySub = supabase.channel('admin-db-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'deliveries' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drivers' }, () => fetchData())
      .subscribe();
    return () => { supabase.removeChannel(deliverySub); };
  }, []);

  const fetchData = async () => {
    try {
      const [delRes, drvRes] = await Promise.all([
        fetch("/api/deliveries"),
        fetch("/api/drivers")
      ]);
      if (!delRes.ok || !drvRes.ok) throw new Error("Failed to fetch");
      const delData = await delRes.json();
      const drvData = await drvRes.json();
      setDeliveries(Array.isArray(delData) ? delData : []);
      setDrivers(Array.isArray(drvData) ? drvData : []);
      setApiError(false);
    } catch (error) {
      console.error(error);
      setApiError(true);
    } finally {
      setLoading(false);
    }
  };

  const pendingDrivers = drivers.filter(d => d.approval_status === 'Pending');
  const activeDrivers = drivers.filter(d => d.approval_status === 'Approved');
  const assignableDrivers = activeDrivers.filter(d => d.is_active !== false);

  const handleLogout = async () => {
    await fetch("/api/admin/logout", { method: "POST" });
    router.push("/admin/login");
    router.refresh();
  };

  // ── Driver actions ────────────────────────────────────────────────────────
  const approveDriver = (driver: Driver) => {
    setModalConfig({
      isOpen: true, type: 'confirm', title: 'Approve Driver',
      message: 'Approve this driver? They will be notified automatically via SMS.',
      onCancel: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false })),
      onConfirm: async () => {
        setModalConfig((prev: any) => ({ ...prev, isOpen: false }));
        setDrivers(prev => prev.map(d => d.id === driver.id ? { ...d, approval_status: 'Approved' } : d));
        const { error } = await supabase.from('drivers').update({ approval_status: 'Approved' }).eq('id', driver.id);
        if (error) {
          setModalConfig({ isOpen: true, type: 'alert', title: 'Error', message: error.message, onConfirm: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false })) });
          fetchData();
        } else {
          if (driver.phone) {
            try {
              await fetch('/api/sms/send', { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ phone: driver.phone, message: "🎉 Congratulations! You have been approved by the Admin. You can now Log In using your name and password." }) });
            } catch (e) { console.error("Failed to notify driver via SMS", e); }
          }
          fetchData();
        }
      }
    });
  };

  const rejectDriver = (id: string) => {
    setModalConfig({
      isOpen: true, type: 'confirm', title: 'Reject Driver',
      message: 'Are you sure you want to REJECT and DELETE this driver application?',
      onCancel: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false })),
      onConfirm: async () => {
        setModalConfig((prev: any) => ({ ...prev, isOpen: false }));
        setDrivers(prev => prev.filter(d => d.id !== id));
        const { error } = await supabase.from('drivers').delete().eq('id', id);
        if (error) {
          setModalConfig({ isOpen: true, type: 'alert', title: 'Failed to delete', message: error.message, onConfirm: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false })) });
          fetchData();
        }
      }
    });
  };

  const deleteDriver = (id: string) => {
    setModalConfig({
      isOpen: true, type: 'confirm', title: 'Delete Driver',
      message: 'Are you sure you want to completely DELETE this active driver?',
      onCancel: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false })),
      onConfirm: async () => {
        setModalConfig((prev: any) => ({ ...prev, isOpen: false }));
        const { error } = await supabase.from('drivers').delete().eq('id', id);
        if (error) setModalConfig({ isOpen: true, type: 'alert', title: 'Failed to delete', message: error.message, onConfirm: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false })) });
        fetchData();
      }
    });
  };

  const editDriver = (id: string) => {
    const driver = drivers.find((d: any) => d.id === id);
    if (!driver) return;
    setModalConfig({
      isOpen: true, type: 'prompt', title: 'Edit Driver',
      message: 'Update the driver details below:',
      fields: [
        { name: 'name', label: 'Driver Name', value: driver.name },
        { name: 'phone', label: 'Driver Phone', value: driver.phone },
        { name: 'plate_number', label: 'Plate Number', value: driver.plate_number || '' }
      ],
      onCancel: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false })),
      onConfirm: async (data: any) => {
        setModalConfig((prev: any) => ({ ...prev, isOpen: false }));
        if (data.name && data.phone) {
          setDrivers((prev: Driver[]) => prev.map((d: Driver) => d.id === id ? { ...d, name: data.name, phone: data.phone, plate_number: data.plate_number } : d));
          await supabase.from('drivers').update({ name: data.name, phone: data.phone, plate_number: data.plate_number }).eq('id', id);
          fetchData();
        }
      }
    });
  };

  const toggleDriverActive = async (driver: Driver) => {
    const newActive = driver.is_active === false ? true : false;
    setDrivers(prev => prev.map(d => d.id === driver.id ? { ...d, is_active: newActive } : d));
    await supabase.from('drivers').update({ is_active: newActive }).eq('id', driver.id);
  };

  // ── Delivery assignment ───────────────────────────────────────────────────
  const assignDriver = async (deliveryId: string, driverId: string) => {
    await fetch(`/api/deliveries/${deliveryId}/assign`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ driver_id: driverId })
    });
    setAssigningDelivery(null);
    fetchData();
  };

  // ── Date-filtered stats ───────────────────────────────────────────────────
  const filteredDeliveries = filterByDate(deliveries, dateRange);

  // ── Analytics data ────────────────────────────────────────────────────────
  const uniqueCustomers = new Set(deliveries.map(d => d.customer_phone)).size;
  const deliveryTrend = getLast7Days(deliveries);
  const maxTrendCount = Math.max(...deliveryTrend.map(d => d.count), 1);
  const completionRate = deliveries.length > 0
    ? Math.round((deliveries.filter(d => d.status === 'Delivered').length / deliveries.length) * 100)
    : 0;

  // ─────────────────────────────────────────────────────────────────────────
  // RENDER
  // ─────────────────────────────────────────────────────────────────────────
  return (
    <div className="flex h-screen bg-neutral-50 text-neutral-900 font-sans relative">
      <NetworkStatus apiError={apiError} />

      {/* Mobile Sidebar Overlay */}
      {sidebarOpen && (
        <div className="fixed inset-0 bg-neutral-900/50 backdrop-blur-sm z-30 md:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      {/* Persistent Sidebar */}
      <aside className={`fixed md:static inset-y-0 left-0 w-64 bg-neutral-900 text-white flex flex-col shadow-2xl z-40 transform transition-transform duration-300 ease-in-out ${sidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}`}>
        <div className="p-6 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="h-10 w-10 rounded-xl flex items-center justify-center overflow-hidden shadow-lg shadow-blue-500/30">
              <Image src="/favlogo1.png" alt="MotoBike Logo" width={40} height={40} className="object-cover" />
            </div>
            <div>
              <h1 className="text-lg font-extrabold tracking-tight leading-tight">MotoBike</h1>
              <p className="text-xs text-neutral-500 font-medium">Admin Panel</p>
            </div>
          </div>
          <button className="md:hidden text-neutral-400 hover:text-white" onClick={() => setSidebarOpen(false)}>
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <nav className="flex-1 px-4 space-y-1.5 mt-2">
          {([
            { key: 'deliveries', label: 'Deliveries', icon: '📦' },
            { key: 'map', label: 'Live Map', icon: '🗺️' },
            { key: 'drivers', label: 'Drivers', icon: '👤', badge: activeDrivers.length },
            { key: 'analytics', label: 'Analytics', icon: '📊' },
          ] as const).map(tab => (
            <button
              key={tab.key}
              onClick={() => { setActiveTab(tab.key); setSidebarOpen(false); }}
              className={`w-full flex justify-between items-center px-4 py-3 rounded-xl transition-all ${activeTab === tab.key ? 'bg-blue-600 font-bold shadow-md' : 'text-neutral-400 hover:bg-neutral-800 hover:text-white'}`}
            >
              <div className="flex items-center space-x-3">
                <span>{tab.icon}</span>
                <span>{tab.label}</span>
              </div>
              {'badge' in tab && (
                <span className="bg-neutral-700 text-xs px-2 py-0.5 rounded-full">{tab.badge}</span>
              )}
            </button>
          ))}

          <button
            onClick={() => { setActiveTab('pending'); setSidebarOpen(false); }}
            className={`w-full flex justify-between items-center px-4 py-3 rounded-xl transition-all ${activeTab === 'pending' ? 'bg-amber-500 font-bold shadow-md text-white' : 'text-neutral-400 hover:bg-neutral-800 hover:text-white'}`}
          >
            <div className="flex items-center space-x-3">
              <span>⏳</span>
              <span>Approvals</span>
            </div>
            {pendingDrivers.length > 0 && (
              <span className="bg-amber-500 text-white text-xs font-bold px-2 py-0.5 rounded-full animate-pulse">{pendingDrivers.length}</span>
            )}
          </button>
        </nav>

        <div className="p-4 border-t border-neutral-800">
          <button onClick={handleLogout} className="w-full flex items-center space-x-3 px-4 py-3 text-neutral-400 hover:text-white hover:bg-neutral-800 rounded-xl transition-all">
            <span>🚪</span>
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col overflow-hidden bg-neutral-100 relative min-w-0">
        {/* Header */}
        <header className="bg-white px-6 md:px-8 py-5 border-b border-neutral-200 flex justify-between items-center shadow-sm z-10 sticky top-0">
          <div className="flex items-center space-x-4">
            <button className="md:hidden text-neutral-500 hover:text-neutral-900 p-1" onClick={() => setSidebarOpen(true)}>
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" /></svg>
            </button>
            <h2 className="text-xl md:text-2xl font-extrabold text-neutral-800 capitalize truncate">
              {activeTab === 'pending' ? 'Pending Approvals' : activeTab === 'map' ? 'Live Driver Map' : activeTab}
            </h2>
          </div>
          <div className="flex items-center space-x-3 flex-shrink-0">
            <span className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></span>
            <span className="text-sm font-bold text-neutral-500 uppercase tracking-wider">Live Sync</span>
          </div>
        </header>

        {/* Content */}
        <div className="flex-1 overflow-auto p-4 md:p-8 relative">
          {loading ? (
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            </div>
          ) : (
            <div className="max-w-6xl mx-auto">

              {/* ── DELIVERIES TAB ──────────────────────────────────────── */}
              {activeTab === 'deliveries' && (
                <div className="space-y-6">
                  {/* Filters row */}
                  <div className="flex flex-wrap gap-3 items-center justify-between">
                    <div className="flex gap-2 flex-wrap">
                      {(['today', 'week', 'month', 'all'] as DateRange[]).map(r => (
                        <button
                          key={r}
                          onClick={() => setDateRange(r)}
                          className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${dateRange === r ? 'bg-blue-600 text-white shadow-sm' : 'bg-white text-neutral-500 border border-neutral-200 hover:border-blue-400'}`}
                        >
                          {r === 'today' ? 'Today' : r === 'week' ? 'This Week' : r === 'month' ? 'This Month' : 'All Time'}
                        </button>
                      ))}
                    </div>
                    <select
                      className="block rounded-xl border-neutral-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm font-medium py-2 pl-3 pr-10 text-neutral-700 bg-white border"
                      value={filterStatus}
                      onChange={(e) => setFilterStatus(e.target.value)}
                    >
                      <option value="All">All Statuses</option>
                      <option value="Pending">Pending</option>
                      <option value="Assigned">Assigned</option>
                      <option value="Picked Up">Picked Up</option>
                      <option value="Delivered">Delivered</option>
                      <option value="Cancelled">Cancelled/Rejected</option>
                    </select>
                  </div>

                  {/* Stats cards */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="bg-white p-5 rounded-2xl shadow-sm border border-neutral-100 flex items-center">
                      <div className="h-11 w-11 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center text-xl mr-3">📦</div>
                      <div>
                        <p className="text-xs text-neutral-500 font-medium">Total</p>
                        <p className="text-2xl font-extrabold">{filteredDeliveries.length}</p>
                      </div>
                    </div>
                    <div className="bg-white p-5 rounded-2xl shadow-sm border border-neutral-100 flex items-center">
                      <div className="h-11 w-11 bg-amber-50 text-amber-600 rounded-full flex items-center justify-center text-xl mr-3">⏳</div>
                      <div>
                        <p className="text-xs text-neutral-500 font-medium">Pending</p>
                        <p className="text-2xl font-extrabold">{filteredDeliveries.filter(d => d.status === 'Pending').length}</p>
                      </div>
                    </div>
                    <div className="bg-white p-5 rounded-2xl shadow-sm border border-neutral-100 flex items-center">
                      <div className="h-11 w-11 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center text-xl mr-3">🏁</div>
                      <div>
                        <p className="text-xs text-neutral-500 font-medium">Completed</p>
                        <p className="text-2xl font-extrabold">{filteredDeliveries.filter(d => d.status === 'Delivered').length}</p>
                      </div>
                    </div>
                    <div className="bg-white p-5 rounded-2xl shadow-sm border border-neutral-100 flex items-center">
                      <div className="h-11 w-11 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center text-xl mr-3">👤</div>
                      <div>
                        <p className="text-xs text-neutral-500 font-medium">Drivers</p>
                        <p className="text-2xl font-extrabold">{activeDrivers.length}</p>
                      </div>
                    </div>
                  </div>

                  {/* Delivery cards */}
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                    {deliveries.filter(d => filterStatus === "All" || d.status === filterStatus).length === 0 && (
                      <div className="col-span-full py-12 text-center text-neutral-500 font-medium bg-white rounded-2xl border border-neutral-200">No deliveries found.</div>
                    )}
                    {deliveries.filter(d => filterStatus === "All" || d.status === filterStatus).map(d => {
                      const secsLeft = d.status === 'Assigned' ? getSecondsLeft(d.assigned_at) : 0;
                      const isTimingOut = d.status === 'Assigned' && secsLeft > 0 && secsLeft < 60;
                      return (
                        <div key={d.id} className={`bg-white rounded-2xl border shadow-sm p-5 flex flex-col relative group hover:shadow-md transition-shadow ${isTimingOut ? 'border-amber-300' : 'border-neutral-200'}`}>
                          <div className="flex justify-between items-start mb-3">
                            <div>
                              <h3 className="font-extrabold text-neutral-900">{d.customer_name}</h3>
                              <p className="text-neutral-500 text-sm font-medium">{d.customer_phone}</p>
                            </div>
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold whitespace-nowrap
                              ${d.status === 'Pending' ? 'bg-amber-100 text-amber-800' : ''}
                              ${d.status === 'Assigned' ? 'bg-blue-100 text-blue-800' : ''}
                              ${d.status === 'Picked Up' ? 'bg-indigo-100 text-indigo-800' : ''}
                              ${d.status === 'Delivered' ? 'bg-emerald-100 text-emerald-800' : ''}
                              ${d.status === 'Cancelled' ? 'bg-red-100 text-red-800' : ''}
                            `}>
                              {d.status === 'Pending' ? '⏳ Pending' : d.status}
                            </span>
                          </div>

                          {/* Countdown timer */}
                          {d.status === 'Assigned' && d.assigned_at && (
                            <div className={`mb-3 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center space-x-2 ${secsLeft === 0 ? 'bg-red-50 text-red-600' : secsLeft < 60 ? 'bg-amber-50 text-amber-700 animate-pulse' : 'bg-blue-50 text-blue-600'}`}>
                              <span>⏱️</span>
                              <span>{secsLeft === 0 ? 'Reverting...' : `Driver accepts in: ${Math.floor(secsLeft / 60)}:${String(secsLeft % 60).padStart(2, '0')}`}</span>
                            </div>
                          )}

                          {/* Cancellation info */}
                          {(d.cancelled_by || d.cancellation_reason) && (
                            <div className="mb-3 px-3 py-1.5 bg-red-50 rounded-lg text-xs text-red-600 font-medium">
                              ⚠️ {d.cancelled_by === 'driver_reject' ? 'Driver rejected' : d.cancelled_by === 'timeout' ? 'Timed out (no accept)' : 'Cancelled'}{d.cancellation_reason ? ` — ${d.cancellation_reason}` : ''}
                            </div>
                          )}

                          <div className="flex-1 space-y-2 mb-4">
                            <div className="flex items-start bg-neutral-50 p-2.5 rounded-xl">
                              <span className="text-blue-500 mr-2 flex-shrink-0">🟢</span>
                              <span className="text-sm font-medium text-neutral-800 line-clamp-2">{d.pickup_location}</span>
                            </div>
                            <div className="flex items-start bg-neutral-50 p-2.5 rounded-xl">
                              <span className="text-red-500 mr-2 flex-shrink-0">📍</span>
                              <span className="text-sm font-medium text-neutral-800 line-clamp-2">{d.dropoff_location}</span>
                            </div>
                            <div className="grid grid-cols-2 gap-2 mt-2">
                              <div className="bg-blue-50/50 p-2 rounded-lg">
                                <p className="text-[10px] uppercase font-bold text-neutral-400">Item</p>
                                <p className="text-xs font-bold text-neutral-700 truncate">{d.package_type}</p>
                              </div>
                              <div className="bg-emerald-50/50 p-2 rounded-lg">
                                <p className="text-[10px] uppercase font-bold text-neutral-400">Required</p>
                                <p className="text-xs font-bold text-neutral-700 truncate">{d.vehicle_category === 'Motor' ? '🏍️ Motor' : '🚲 Bike'}</p>
                              </div>
                            </div>
                          </div>

                          <div className="mt-auto pt-3 border-t border-neutral-100">
                            {d.status === 'Pending' ? (
                              <div className="space-y-2">
                                <select
                                  className="block w-full text-sm rounded-xl border-neutral-200 bg-neutral-50 focus:ring-blue-500 focus:border-blue-500 font-medium py-2.5 border"
                                  onChange={(e) => {
                                    if (e.target.value) {
                                      assignDriver(d.id, e.target.value);
                                      // NOTE: do NOT switch tabs here — switching tabs unmounts this
                                      // card which causes the dropdown to vanish before selection registers.
                                    }
                                  }}
                                  defaultValue=""
                                >
                                  <option value="" disabled>Assign Driver...</option>
                                  {assignableDrivers.filter(drv => drv.status === 'Online').map(drv => (
                                    <option key={drv.id} value={drv.id}>{drv.name} ({drv.vehicle_type || 'Bike'} - Online 🟢)</option>
                                  ))}
                                  {assignableDrivers.filter(drv => drv.status === 'Offline').map(drv => (
                                    <option key={drv.id} value={drv.id}>{drv.name} ({drv.vehicle_type || 'Bike'} - Offline)</option>
                                  ))}
                                </select>
                                <button
                                  onClick={() => { setAssigningDelivery(d); setActiveTab('map'); }}
                                  className="w-full text-xs font-bold text-blue-600 hover:text-blue-700 py-1.5 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors"
                                >
                                  🗺️ View Map to Find Nearest Driver
                                </button>
                              </div>
                            ) : (
                              <div className="flex items-center justify-between p-2.5 bg-neutral-50 rounded-xl">
                                <p className="text-xs font-bold text-neutral-400 uppercase tracking-wide">Driver</p>
                                <p className="font-bold text-neutral-800 text-sm flex items-center">
                                  <span className="mr-1.5">{d.driver?.vehicle_type === 'Motor' ? '🏍️' : '🚲'}</span>
                                  {d.driver?.name || 'Unassigned'}
                                </p>
                              </div>
                            )}

                            {['Assigned', 'Picked Up'].includes(d.status) && (
                              <button
                                className="w-full mt-2.5 flex items-center justify-center space-x-2 bg-neutral-900 text-white py-2.5 rounded-xl text-sm font-bold shadow-sm hover:bg-black transition-colors"
                                onClick={() => setModalConfig({
                                  isOpen: true, type: 'map', title: `Track: ${d.customer_name}`, message: '',
                                  mapData: { driverLat: d.driver?.current_lat, driverLng: d.driver?.current_lng, pickupLat: d.pickup_lat, pickupLng: d.pickup_lng, dropoffLat: d.dropoff_lat, dropoffLng: d.dropoff_lng },
                                  onConfirm: () => setModalConfig(prev => ({ ...prev, isOpen: false }))
                                })}
                              >
                                <span>🗺️</span>
                                <span>Live Tracking</span>
                              </button>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* ── MAP TAB ─────────────────────────────────────────────── */}
              {activeTab === 'map' && (
                <div className="space-y-4">
                  {assigningDelivery && (
                    <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 flex items-start justify-between">
                      <div>
                        <p className="font-bold text-blue-800 text-sm">📦 Assigning delivery for: <span className="font-extrabold">{assigningDelivery.customer_name}</span></p>
                        <p className="text-xs text-blue-600 mt-0.5">Pickup: {assigningDelivery.pickup_location}</p>
                        <p className="text-xs text-blue-500 mt-0.5">Select the driver closest to the pickup pin on the map.</p>
                      </div>
                      <button onClick={() => setAssigningDelivery(null)} className="text-blue-400 hover:text-blue-700 font-bold text-xs px-3 py-1 rounded-lg hover:bg-blue-100 transition-colors flex-shrink-0 ml-3">
                        Clear
                      </button>
                    </div>
                  )}

                  <div className="bg-white rounded-2xl shadow-sm border border-neutral-200 overflow-hidden" style={{ height: 'calc(100vh - 280px)', minHeight: '400px' }}>
                    <AllDriversMap
                      drivers={activeDrivers}
                      pickupLat={assigningDelivery?.pickup_lat}
                      pickupLng={assigningDelivery?.pickup_lng}
                      pickupLabel={assigningDelivery?.pickup_location}
                    />
                  </div>
                </div>
              )}

              {/* ── DRIVERS TAB ─────────────────────────────────────────── */}
              {activeTab === 'drivers' && (
                <div className="space-y-4">
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="font-extrabold text-neutral-800 text-lg">Active Drivers <span className="text-neutral-400 font-medium text-base ml-2">({activeDrivers.length} total)</span></h3>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                    {activeDrivers.map(drv => (
                      <div key={drv.id} className={`bg-white rounded-2xl shadow-sm border p-5 flex flex-col relative overflow-hidden group ${drv.is_active === false ? 'border-neutral-300 opacity-70' : 'border-neutral-200'}`}>
                        <div className="absolute top-0 right-0 p-4 flex items-center space-x-2">
                          <span className={`inline-block w-2.5 h-2.5 rounded-full shadow-inner ${drv.status === 'Online' ? 'bg-emerald-500 shadow-emerald-500/50' : 'bg-neutral-300'}`}></span>
                        </div>

                        <div className="h-14 w-14 bg-gradient-to-br from-blue-50 to-blue-100 text-blue-600 rounded-full flex items-center justify-center text-2xl font-bold mb-3">
                          {drv.name.charAt(0)}
                        </div>
                        <h3 className="text-lg font-extrabold text-neutral-900 truncate">{drv.name}</h3>
                        <p className="text-neutral-500 font-medium mt-0.5 truncate text-sm">{drv.phone}</p>
                        <p className="text-neutral-400 text-xs mt-0.5 truncate">{drv.telegram_username || drv.telegram_id || 'No Telegram'}</p>
                        <div className="flex items-center space-x-2 mt-2">
                          <span className="text-neutral-600 font-bold text-xs">Plate: {drv.plate_number || 'N/A'}</span>
                          <span className={`text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-lg ${drv.vehicle_type === 'Motor' ? 'bg-amber-100 text-amber-700' : 'bg-indigo-100 text-indigo-700'}`}>
                            {drv.vehicle_type === 'Motor' ? '🏍️ Motor' : '🚲 Bike'}
                          </span>
                        </div>

                        <div className="mt-3 flex space-x-2">
                          <button onClick={() => editDriver(drv.id)} className="flex-1 px-2 py-1.5 bg-neutral-100 text-neutral-600 font-bold text-xs rounded-lg hover:bg-neutral-200 transition-colors">Edit</button>
                          {drv.personal_id_url && (
                            <a href={drv.personal_id_url} target="_blank" rel="noopener noreferrer" className="flex-1 px-2 py-1.5 bg-blue-50 text-blue-600 font-bold text-xs rounded-lg text-center hover:bg-blue-100 transition-colors">View ID</a>
                          )}
                          <button onClick={() => deleteDriver(drv.id)} className="flex-1 px-2 py-1.5 bg-red-50 text-red-600 font-bold text-xs rounded-lg hover:bg-red-100 transition-colors">Delete</button>
                        </div>

                        <div className="mt-3 pt-3 border-t border-neutral-100 flex justify-between items-center">
                          <div>
                            <p className="text-xs font-bold text-neutral-500">Connection</p>
                            <span className={`text-xs font-bold px-2 py-0.5 rounded-full mt-0.5 inline-block ${drv.status === 'Online' ? 'bg-emerald-50 text-emerald-700' : 'bg-neutral-100 text-neutral-600'}`}>{drv.status}</span>
                          </div>
                          <div className="text-right">
                            <p className="text-xs font-bold text-neutral-500 mb-1">Active</p>
                            <button
                              onClick={() => toggleDriverActive(drv)}
                              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none ${drv.is_active !== false ? 'bg-emerald-500' : 'bg-neutral-300'}`}
                            >
                              <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform shadow-sm ${drv.is_active !== false ? 'translate-x-6' : 'translate-x-1'}`} />
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                    {activeDrivers.length === 0 && (
                      <div className="col-span-full bg-white p-12 text-center rounded-2xl border border-dashed border-neutral-300 text-neutral-500 font-medium">No approved drivers yet.</div>
                    )}
                  </div>
                </div>
              )}

              {/* ── ANALYTICS TAB ───────────────────────────────────────── */}
              {activeTab === 'analytics' && (
                <div className="space-y-6">
                  {/* Top stat cards */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="bg-white p-5 rounded-2xl shadow-sm border border-neutral-100">
                      <div className="h-10 w-10 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center text-lg mb-3">👤</div>
                      <p className="text-xs text-neutral-500 font-medium uppercase tracking-wide">Total Drivers</p>
                      <p className="text-3xl font-extrabold text-neutral-900 mt-1">{activeDrivers.length}</p>
                      <p className="text-xs text-neutral-400 mt-1">{activeDrivers.filter(d => d.is_active !== false).length} active · {activeDrivers.filter(d => d.is_active === false).length} inactive</p>
                    </div>
                    <div className="bg-white p-5 rounded-2xl shadow-sm border border-neutral-100">
                      <div className="h-10 w-10 bg-emerald-50 text-emerald-600 rounded-xl flex items-center justify-center text-lg mb-3">🟢</div>
                      <p className="text-xs text-neutral-500 font-medium uppercase tracking-wide">Online Now</p>
                      <p className="text-3xl font-extrabold text-neutral-900 mt-1">{activeDrivers.filter(d => d.status === 'Online').length}</p>
                      <p className="text-xs text-neutral-400 mt-1">of {activeDrivers.length} drivers</p>
                    </div>
                    <div className="bg-white p-5 rounded-2xl shadow-sm border border-neutral-100">
                      <div className="h-10 w-10 bg-violet-50 text-violet-600 rounded-xl flex items-center justify-center text-lg mb-3">📱</div>
                      <p className="text-xs text-neutral-500 font-medium uppercase tracking-wide">Platform Users</p>
                      <p className="text-3xl font-extrabold text-neutral-900 mt-1">{uniqueCustomers}</p>
                      <p className="text-xs text-neutral-400 mt-1">unique customers</p>
                    </div>
                    <div className="bg-white p-5 rounded-2xl shadow-sm border border-neutral-100">
                      <div className="h-10 w-10 bg-amber-50 text-amber-600 rounded-xl flex items-center justify-center text-lg mb-3">📊</div>
                      <p className="text-xs text-neutral-500 font-medium uppercase tracking-wide">Completion Rate</p>
                      <p className="text-3xl font-extrabold text-neutral-900 mt-1">{completionRate}%</p>
                      <p className="text-xs text-neutral-400 mt-1">{deliveries.filter(d => d.status === 'Delivered').length} of {deliveries.length} deliveries</p>
                    </div>
                  </div>

                  {/* Delivery Volume Chart (last 7 days) */}
                  <div className="bg-white p-6 rounded-2xl shadow-sm border border-neutral-100">
                    <h3 className="font-extrabold text-neutral-800 mb-1">Delivery Volume — Last 7 Days</h3>
                    <p className="text-xs text-neutral-400 mb-6">Total delivery requests per day</p>
                    <div className="flex items-end space-x-3 h-40">
                      {deliveryTrend.map((day, idx) => (
                        <div key={idx} className="flex-1 flex flex-col items-center">
                          <span className="text-xs font-bold text-neutral-500 mb-1">{day.count || ''}</span>
                          <div
                            className="w-full rounded-t-lg bg-gradient-to-t from-blue-600 to-blue-400 transition-all duration-500"
                            style={{ height: `${day.count === 0 ? 4 : Math.max(8, (day.count / maxTrendCount) * 128)}px`, minHeight: '4px' }}
                          />
                          <span className="text-[10px] font-bold text-neutral-400 mt-2">{day.label}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Breakdown table */}
                  <div className="bg-white p-6 rounded-2xl shadow-sm border border-neutral-100">
                    <h3 className="font-extrabold text-neutral-800 mb-4">All-Time Delivery Breakdown</h3>
                    <div className="space-y-3">
                      {[
                        { label: 'Pending', count: deliveries.filter(d => d.status === 'Pending').length, color: 'bg-amber-400' },
                        { label: 'Assigned', count: deliveries.filter(d => d.status === 'Assigned').length, color: 'bg-blue-400' },
                        { label: 'Picked Up', count: deliveries.filter(d => d.status === 'Picked Up').length, color: 'bg-indigo-400' },
                        { label: 'Delivered', count: deliveries.filter(d => d.status === 'Delivered').length, color: 'bg-emerald-400' },
                        { label: 'Cancelled', count: deliveries.filter(d => d.status === 'Cancelled').length, color: 'bg-red-400' },
                      ].map(item => (
                        <div key={item.label} className="flex items-center space-x-3">
                          <span className="text-xs font-bold text-neutral-600 w-20 flex-shrink-0">{item.label}</span>
                          <div className="flex-1 bg-neutral-100 rounded-full h-2.5">
                            <div
                              className={`${item.color} h-2.5 rounded-full transition-all duration-700`}
                              style={{ width: deliveries.length > 0 ? `${(item.count / deliveries.length) * 100}%` : '0%' }}
                            />
                          </div>
                          <span className="text-xs font-extrabold text-neutral-700 w-8 text-right">{item.count}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {/* ── PENDING APPROVALS TAB ───────────────────────────────── */}
              {activeTab === 'pending' && (
                <div className="max-w-3xl mx-auto space-y-4">
                  {pendingDrivers.map(drv => (
                    <div key={drv.id} className="bg-white rounded-2xl shadow-md border-l-4 border-l-amber-500 border-y border-r border-neutral-200 p-6 flex items-center justify-between">
                      <div className="flex items-center space-x-5">
                        <div className="h-14 w-14 bg-amber-50 text-amber-600 rounded-full flex items-center justify-center text-xl font-bold">{drv.name.charAt(0)}</div>
                        <div>
                          <h3 className="text-xl font-extrabold text-neutral-900">{drv.name}</h3>
                          <div className="flex space-x-4 mt-1 text-sm text-neutral-500 font-medium">
                            <span>📞 {drv.phone}</span>
                            <span>📱 {drv.telegram_id}</span>
                          </div>
                        </div>
                      </div>
                      <div className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-3 w-full sm:w-auto mt-4 sm:mt-0">
                        {drv.personal_id_url && (
                          <a href={drv.personal_id_url} target="_blank" rel="noopener noreferrer" className="px-4 py-2 bg-blue-50 text-blue-600 font-bold text-center rounded-xl hover:bg-blue-100 transition-colors w-full sm:w-auto text-sm">View ID</a>
                        )}
                        <button onClick={() => rejectDriver(drv.id)} className="px-4 py-2 bg-neutral-100 text-neutral-600 font-bold rounded-xl hover:bg-neutral-200 transition-colors w-full sm:w-auto text-sm">Reject</button>
                        <button onClick={() => approveDriver(drv)} className="px-4 py-2 bg-blue-600 shadow-lg shadow-blue-600/20 text-white font-bold rounded-xl hover:bg-blue-700 transition-all w-full sm:w-auto text-sm">Approve</button>
                      </div>
                    </div>
                  ))}
                  {pendingDrivers.length === 0 && (
                    <div className="bg-white p-16 text-center rounded-3xl border border-dashed border-neutral-300">
                      <div className="text-4xl mb-4">✨</div>
                      <p className="text-lg text-neutral-500 font-bold">You're all caught up!</p>
                      <p className="text-sm text-neutral-400 mt-1">No pending driver approvals.</p>
                    </div>
                  )}
                </div>
              )}

            </div>
          )}
        </div>
      </main>

      {/* Custom Modal */}
      {modalConfig.isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-neutral-900/60 backdrop-blur-sm" onClick={modalConfig.onCancel || modalConfig.onConfirm}></div>
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-md overflow-hidden relative z-10">
            <div className="p-6">
              <h3 className="text-xl font-extrabold text-neutral-900 mb-2">{modalConfig.title}</h3>
              <p className="text-sm font-medium text-neutral-500 mb-6">{modalConfig.message}</p>

              {modalConfig.type === 'prompt' && modalConfig.fields && (
                <form id="modal-form" className="space-y-4 mb-6" onSubmit={(e) => {
                  e.preventDefault();
                  const formData = new FormData(e.currentTarget);
                  const data = Object.fromEntries(formData.entries());
                  if (modalConfig.onConfirm) modalConfig.onConfirm(data);
                }}>
                  {modalConfig.fields.map(field => (
                    <div key={field.name}>
                      <label className="block text-xs font-bold text-neutral-700 mb-1 ml-1">{field.label}</label>
                      <input required name={field.name} defaultValue={field.value} className="block w-full border-neutral-300 border rounded-xl shadow-sm p-3 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-neutral-50 font-medium transition-all" />
                    </div>
                  ))}
                </form>
              )}

              {modalConfig.type === 'map' && (
                <div className="space-y-4">
                  <div className="rounded-xl overflow-hidden border border-neutral-200 shadow-inner">
                    {modalConfig.mapData ? (
                      <LiveMap
                        driverLat={modalConfig.mapData.driverLat}
                        driverLng={modalConfig.mapData.driverLng}
                        pickupLat={modalConfig.mapData.pickupLat}
                        pickupLng={modalConfig.mapData.pickupLng}
                        dropoffLat={modalConfig.mapData.dropoffLat}
                        dropoffLng={modalConfig.mapData.dropoffLng}
                      />
                    ) : (
                      <div className="h-[400px] flex items-center justify-center bg-neutral-100 text-neutral-500 font-bold">No tracking data available.</div>
                    )}
                  </div>
                  <button onClick={modalConfig.onConfirm} className="w-full px-4 py-3 bg-neutral-900 text-white font-extrabold rounded-xl hover:bg-black shadow-lg">Close Tracking</button>
                </div>
              )}

              {modalConfig.type !== 'map' && (
                <div className="flex space-x-3 justify-end">
                  {(modalConfig.type === 'confirm' || modalConfig.type === 'prompt') && (
                    <button type="button" onClick={modalConfig.onCancel} className="px-5 py-2.5 bg-neutral-100 text-neutral-600 font-bold rounded-xl hover:bg-neutral-200 transition-colors text-sm">Cancel</button>
                  )}
                  <button
                    type={modalConfig.type === 'prompt' ? 'submit' : 'button'}
                    form={modalConfig.type === 'prompt' ? 'modal-form' : undefined}
                    onClick={modalConfig.type !== 'prompt' ? modalConfig.onConfirm : undefined}
                    className="px-5 py-2.5 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 shadow-lg shadow-blue-500/20 transition-all text-sm"
                  >
                    {modalConfig.type === 'alert' ? 'OK' : 'Confirm'}
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
