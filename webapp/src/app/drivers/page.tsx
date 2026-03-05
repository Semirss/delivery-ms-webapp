"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

type Delivery = {
  id: string;
  customer_name: string;
  pickup_location: string;
  dropoff_location: string;
  status: string;
  created_at: string;
};

type Driver = {
  id: string;
  name: string;
  status: string;
};

export default function DriverPortal() {
  const [driver, setDriver] = useState<Driver | null>(null);
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [loading, setLoading] = useState(false);
  const [loginError, setLoginError] = useState("");

  useEffect(() => {
    // Check local storage for persistent logic purely for MVP usability
    const stored = localStorage.getItem('mvp_driver_session');
    if (stored) {
      setDriver(JSON.parse(stored));
    }
  }, []);

  useEffect(() => {
    if (driver?.id) {
      fetchDeliveries();
    }
  }, [driver]);

  const handleLogin = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    setLoginError("");
    
    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData.entries());

    try {
      const res = await fetch("/api/drivers/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data)
      });
      
      if (!res.ok) {
        throw new Error("Invalid name or password");
      }
      
      const session = await res.json();
      setDriver(session);
      localStorage.setItem('mvp_driver_session', JSON.stringify(session));
    } catch (err: any) {
      setLoginError(err.message);
    }
    setLoading(false);
  };

  const handleLogout = () => {
    setDriver(null);
    localStorage.removeItem('mvp_driver_session');
  };

  const fetchDeliveries = async () => {
    if (!driver) return;
    setLoading(true);
    try {
      const res = await fetch(`/api/deliveries?driver_id=${driver.id}`);
      const data = await res.json();
      setDeliveries(Array.isArray(data) ? data : []);
    } catch (err) {
      console.error(err);
    }
    setLoading(false);
  };

  const updateDeliveryStatus = async (id: string, status: string) => {
    if (!confirm(`Mark delivery as ${status}?`)) return;
    try {
      await fetch(`/api/deliveries/${id}/status`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status })
      });
      fetchDeliveries();
    } catch (err) {
      console.error(err);
    }
  };

  // Login View
  if (!driver) {
    return (
      <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8 text-black">
        <div className="max-w-md w-full mx-auto space-y-8">
          <div>
            <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900 tracking-tight">Driver Portal</h2>
            <p className="mt-2 text-center text-sm text-gray-600">Login to manage your assigned deliveries.</p>
          </div>
          
          <form className="bg-white shadow-xl rounded-2xl p-8 border border-gray-100 space-y-6" onSubmit={handleLogin}>
            {loginError && (
              <div className="p-3 bg-red-50 text-red-600 border border-red-200 rounded-lg text-sm text-center font-medium">
                {loginError}
              </div>
            )}
            <div>
              <label className="block text-sm font-bold text-gray-700 mb-1">Driver Name</label>
              <input required type="text" name="name" className="block w-full border-gray-300 border rounded-lg shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-50" placeholder="e.g. John Doe" />
            </div>
            <div>
              <label className="block text-sm font-bold text-gray-700 mb-1">Password</label>
              <input required type="password" name="password" className="block w-full border-gray-300 border rounded-lg shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-50" placeholder="••••••••" />
            </div>
            <button disabled={loading} type="submit" className="w-full py-3.5 px-4 rounded-lg shadow-md text-sm font-extrabold text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 transition-all">
              {loading ? 'Logging in...' : 'Sign In'}
            </button>
          </form>
          
          <div className="text-center">
             <Link href="/" className="text-sm text-gray-500 font-medium hover:text-gray-900">Return to Customer request</Link>
          </div>
        </div>
      </div>
    );
  }

  // Dashboard View for Driver (Mobile First Layout)
  const activeJobs = deliveries.filter(d => ['Assigned', 'Picked Up'].includes(d.status));
  const pastJobs = deliveries.filter(d => ['Delivered', 'Cancelled'].includes(d.status));

  return (
    <div className="min-h-screen bg-gray-50 pb-20 text-black">
      {/* Header */}
      <div className="bg-white px-4 py-4 shadow-sm border-b sticky top-0 z-10 flex justify-between items-center">
        <div>
          <h1 className="font-extrabold text-xl text-gray-900">Driver Portal</h1>
          <p className="text-sm font-medium text-gray-500">Welcome back, {driver.name}</p>
        </div>
        <button onClick={handleLogout} className="text-gray-500 hover:text-gray-900 text-sm font-bold bg-gray-100 px-3 py-1.5 rounded-lg">Logout</button>
      </div>

      <div className="p-4 max-w-lg mx-auto space-y-6">
        <div>
          <h2 className="text-lg font-bold text-gray-900 mb-4 flex items-center justify-between">
            Active Deliveries
            <button onClick={fetchDeliveries} className="text-blue-600 text-sm hover:underline">Refresh</button>
          </h2>
          
          {loading && activeJobs.length === 0 ? <p className="text-gray-500 text-sm text-center py-8">Loading...</p> : (
            <div className="space-y-4">
              {activeJobs.map(job => (
                <div key={job.id} className="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden flex flex-col">
                  {/* Status Banner */}
                  <div className={`px-4 py-2 font-bold text-sm uppercase tracking-wider ${job.status === 'Assigned' ? 'bg-amber-100 text-amber-800' : 'bg-blue-100 text-blue-800'}`}>
                    {job.status === 'Assigned' ? '⏳ Ready for Pickup' : '🚲 En Route Delivery'}
                  </div>
                  
                  <div className="p-4 space-y-3">
                    <p className="font-bold text-lg">{job.customer_name}</p>
                    <div className="space-y-2 text-sm bg-gray-50 p-3 rounded-lg border">
                      <p><span className="text-gray-500 font-bold uppercase text-xs mr-2">Pickup</span> <span className="text-gray-800 font-medium">{job.pickup_location}</span></p>
                      <hr className="border-gray-200" />
                      <p><span className="text-gray-500 font-bold uppercase text-xs mr-2">Dropoff</span> <span className="text-gray-800 font-medium">{job.dropoff_location}</span></p>
                    </div>
                  </div>
                  
                  <div className="p-4 bg-white border-t space-y-2">
                    {job.status === 'Assigned' && (
                      <>
                        <button onClick={() => updateDeliveryStatus(job.id, 'Picked Up')} className="w-full py-3 bg-blue-600 text-white font-bold rounded-lg hover:bg-blue-700 shadow-sm text-sm">
                          Accept & Marker Picked Up
                        </button>
                        <button onClick={() => updateDeliveryStatus(job.id, 'Pending')} className="w-full py-3 bg-white text-red-600 border border-red-200 font-bold rounded-lg hover:bg-red-50 shadow-sm text-sm">
                          Reject Delivery
                        </button>
                      </>
                    )}
                    {job.status === 'Picked Up' && (
                      <button onClick={() => updateDeliveryStatus(job.id, 'Delivered')} className="w-full py-4 bg-emerald-600 text-white font-extrabold rounded-lg hover:bg-emerald-700 shadow-md text-base">
                        🏁 Mark as Delivered
                      </button>
                    )}
                  </div>
                </div>
              ))}
              {activeJobs.length === 0 && (
                <div className="bg-white p-8 text-center rounded-xl border border-dashed text-gray-500 shadow-sm">
                  No active deliveries at the moment.
                </div>
              )}
            </div>
          )}
        </div>

        <div className="pt-6">
          <h2 className="text-base font-bold text-gray-900 mb-3 text-opacity-80">Past Deliveries ({pastJobs.length})</h2>
          <div className="space-y-3">
            {pastJobs.map(job => (
              <div key={job.id} className="bg-white border rounded-lg p-4 flex justify-between items-center opacity-75">
                <div>
                  <p className="font-bold text-sm text-gray-800">{job.customer_name}</p>
                  <p className="text-xs text-gray-500">{new Date(job.created_at).toLocaleDateString()}</p>
                </div>
                <span className={`text-xs font-bold px-2 py-1 rounded ${job.status === 'Delivered' ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-100 text-gray-600'}`}>{job.status}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
