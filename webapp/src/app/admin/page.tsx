"use client";

import { useEffect, useState } from "react";

type Delivery = {
  id: string;
  customer_name: string;
  pickup_location: string;
  dropoff_location: string;
  status: string;
  driver?: { name: string } | null;
  created_at: string;
};

type Driver = {
  id: string;
  name: string;
  phone: string;
  password?: string;
  telegram_id?: string;
  status: string;
  total_deliveries: number;
};

export default function AdminDashboard() {
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [assigningId, setAssigningId] = useState<string | null>(null);

  // Driver CRUD state
  const [showDriverPanel, setShowDriverPanel] = useState(false);
  const [editingDriver, setEditingDriver] = useState<Driver | Partial<Driver> | null>(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [delRes, drvRes] = await Promise.all([
        fetch("/api/deliveries"),
        fetch("/api/drivers"),
      ]);
      const delData = await delRes.json();
      const drvData = await drvRes.json();
      setDeliveries(Array.isArray(delData) ? delData : []);
      setDrivers(Array.isArray(drvData) ? drvData : []);
    } catch (e) {
      console.error("Failed to load dashboard data", e);
    }
    setLoading(false);
  };

  const assignDriver = async (deliveryId: string, driverId: string) => {
    try {
      await fetch(`/api/deliveries/${deliveryId}/assign`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ driver_id: driverId }),
      });
      fetchData(); // refresh
    } catch (e) {
      console.error(e);
    }
  };

  const saveDriver = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData.entries());

    try {
      if (editingDriver?.id) {
        await fetch(`/api/drivers/${editingDriver.id}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(data),
        });
      } else {
        await fetch(`/api/drivers`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(data),
        });
      }
      setShowDriverPanel(false);
      fetchData();
    } catch (e) {
      console.error(e);
      alert("Failed to save driver");
    }
  };

  const deleteDriver = async (driverId: string) => {
    if (!confirm("Are you sure you want to delete this driver?")) return;
    try {
      await fetch(`/api/drivers/${driverId}`, {
        method: "DELETE",
      });
      fetchData();
    } catch (e) {
      console.error(e);
    }
  };

  const totalToday = deliveries.length;
  const completed = deliveries.filter((d) => d.status === "Delivered").length;
  const activeDrivers = drivers.filter((d) => d.status === "Online").length;

  return (
    <div className="min-h-screen bg-gray-50 p-4 md:p-8 text-black relative">
      <div className="max-w-7xl mx-auto space-y-8">
        <h1 className="text-3xl font-extrabold tracking-tight text-gray-900 border-b pb-4">
          Delivery MVP Admin
        </h1>

        {/* Analytics */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex flex-col items-center justify-center py-8">
            <h3 className="text-gray-500 font-medium text-sm mb-2 uppercase tracking-wide">Total Deliveries Today</h3>
            <p className="text-5xl border-emerald-500 font-black text-emerald-600">{totalToday}</p>
          </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex flex-col items-center justify-center py-8">
            <h3 className="text-gray-500 font-medium text-sm mb-2 uppercase tracking-wide">Completed Deliveries</h3>
            <p className="text-5xl font-black text-indigo-600">{completed}</p>
          </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex flex-col items-center justify-center py-8">
            <h3 className="text-gray-500 font-medium text-sm mb-2 uppercase tracking-wide">Active Drivers</h3>
            <p className="text-5xl font-black text-blue-600">{activeDrivers} <span className="text-2xl text-gray-400 font-medium">/ {drivers.length}</span></p>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
          {/* Deliveries */}
          <div className="lg:col-span-2 space-y-4">
            <h2 className="text-xl font-bold border-b pb-2">Recent Deliveries</h2>
            {loading ? <p className="text-gray-500 animate-pulse">Loading deliveries data...</p> : (
              <div className="space-y-4">
                {deliveries.map((del) => (
                  <div key={del.id} className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 transition-all hover:shadow-md">
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        <p className="font-bold text-lg text-gray-900">{del.customer_name}</p>
                        <p className="text-sm text-gray-500">{new Date(del.created_at).toLocaleString()}</p>
                      </div>
                      <span className={`px-4 py-1.5 text-xs rounded-full font-bold uppercase tracking-wider ${
                        del.status === 'Pending' ? 'bg-amber-100 text-amber-800' : 
                        del.status === 'Delivered' ? 'bg-emerald-100 text-emerald-800' : 
                        'bg-blue-100 text-blue-800'
                      }`}>
                        {del.status}
                      </span>
                    </div>
                    <div className="grid grid-cols-2 gap-4 mb-4 text-sm bg-gray-50/50 border p-4 rounded-lg">
                      <div>
                        <span className="font-semibold text-gray-500 text-xs uppercase tracking-wide block mb-1">Pickup</span>
                        <span className="text-gray-800">{del.pickup_location}</span>
                      </div>
                      <div>
                        <span className="font-semibold text-gray-500 text-xs uppercase tracking-wide block mb-1">Drop-off</span>
                        <span className="text-gray-800">{del.dropoff_location}</span>
                      </div>
                    </div>
                    <div className="flex items-center justify-between border-t pt-4">
                      <p className="text-sm">
                        <span className="font-semibold text-gray-500 text-xs uppercase tracking-wide mr-2">Assigned To:</span>
                        <span className={del.driver ? "text-gray-900 font-medium" : "text-gray-400 italic"}>
                          {del.driver ? del.driver.name : "Unassigned"}
                        </span>
                      </p>
                      {del.status === 'Pending' && (
                        <div>
                          {assigningId === del.id ? (
                            <div className="flex items-center space-x-3 bg-gray-50 p-2 rounded-lg border">
                              <select 
                                onChange={(e) => assignDriver(del.id, e.target.value)} 
                                defaultValue=""
                                className="border border-gray-200 rounded-md p-2 text-sm bg-white min-w-[150px] shadow-sm focus:ring-2 focus:ring-blue-500 outline-none"
                              >
                                <option value="" disabled>Select Driver</option>
                                {drivers.map(d => (
                                  <option key={d.id} value={d.id}>{d.name} ({d.status})</option>
                                ))}
                              </select>
                              <button onClick={() => setAssigningId(null)} className="text-gray-500 text-xs font-medium hover:text-gray-800">Cancel</button>
                            </div>
                          ) : (
                            <button onClick={() => setAssigningId(del.id)} className="bg-gray-900 text-white px-5 py-2.5 rounded-lg shadow-sm hover:bg-gray-800 transition-colors font-medium text-sm">
                              Assign Driver
                            </button>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
                {deliveries.length === 0 && (
                  <div className="bg-white p-12 text-center rounded-xl border border-gray-100 border-dashed">
                    <p className="text-gray-500 text-lg">No deliveries found.</p>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Drivers */}
          <div className="space-y-4">
            <div className="flex justify-between items-center border-b pb-2">
              <h2 className="text-xl font-bold">Drivers Directory</h2>
              <button 
                onClick={() => { setEditingDriver({ status: 'Offline' }); setShowDriverPanel(true); }}
                className="bg-emerald-600 text-white px-3 py-1.5 rounded text-sm font-semibold hover:bg-emerald-700"
              >
                + Add Driver
              </button>
            </div>
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 divide-y overflow-hidden">
              {drivers.map(drv => (
                <div key={drv.id} className="p-5 flex flex-col space-y-2 group transition-colors hover:bg-gray-50">
                  <div className="flex items-center justify-between">
                    <p className="font-bold text-gray-900">{drv.name}</p>
                    <div className="flex items-center space-x-2">
                      <span className="text-sm font-semibold capitalize text-gray-600">{drv.status}</span>
                      <span className={`h-3 w-3 rounded-full shadow-inner ${drv.status === 'Online' ? 'bg-emerald-500' : 'bg-gray-300'}`}></span>
                    </div>
                  </div>
                  <div className="flex justify-between items-center">
                    <p className="text-sm text-gray-500">{drv.total_deliveries} lifetime deliveries</p>
                    <div className="space-x-2 mt-2">
                      <button onClick={() => { setEditingDriver(drv); setShowDriverPanel(true); }} className="text-blue-600 text-xs font-bold uppercase hover:underline">Edit</button>
                      <button onClick={() => deleteDriver(drv.id)} className="text-red-600 text-xs font-bold uppercase hover:underline">Delete</button>
                    </div>
                  </div>
                </div>
              ))}
              {drivers.length === 0 && <p className="p-6 text-center text-gray-500 text-sm">No drivers registered yet.</p>}
            </div>
          </div>
        </div>
      </div>

      {/* Driver Side Panel Overlay */}
      {showDriverPanel && (
        <div className="fixed inset-0 z-50 flex justify-end bg-black/40 transition-opacity">
          <div className="w-full max-w-sm bg-white h-full shadow-2xl overflow-y-auto animate-in slide-in-from-right">
            <div className="p-6">
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-xl font-bold">{editingDriver?.id ? 'Edit Driver' : 'New Driver'}</h3>
                <button onClick={() => setShowDriverPanel(false)} className="text-gray-400 hover:text-gray-800 text-2xl font-bold">&times;</button>
              </div>
              <form onSubmit={saveDriver} className="space-y-4">
                <div>
                  <label className="block text-sm font-bold text-gray-700 mb-1">Full Name</label>
                  <input required defaultValue={editingDriver?.name || ''} name="name" className="w-full border p-2 rounded outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-sm font-bold text-gray-700 mb-1">Phone</label>
                  <input required defaultValue={editingDriver?.phone || ''} name="phone" className="w-full border p-2 rounded outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-sm font-bold text-gray-700 mb-1">Password</label>
                  <input required={!editingDriver?.id} defaultValue={editingDriver?.password || ''} name="password" type="text" placeholder={editingDriver?.id ? "Leave empty to keep current" : ""} className="w-full border p-2 rounded outline-none focus:ring-2 focus:ring-blue-500" />
                  <p className="text-xs text-gray-500 mt-1">Required for driver login portal.</p>
                </div>
                <div>
                  <label className="block text-sm font-bold text-gray-700 mb-1">Telegram ID (Optional)</label>
                  <input defaultValue={editingDriver?.telegram_id || ''} name="telegram_id" className="w-full border p-2 rounded outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-sm font-bold text-gray-700 mb-1">Status</label>
                  <select name="status" defaultValue={editingDriver?.status || 'Offline'} className="w-full border p-2 rounded outline-none focus:ring-2 focus:ring-blue-500 bg-white">
                    <option value="Offline">Offline</option>
                    <option value="Online">Online</option>
                  </select>
                </div>
                <div className="pt-4">
                  <button type="submit" className="w-full bg-gray-900 text-white font-bold py-3 rounded hover:bg-gray-800 transition">Save Driver</button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
