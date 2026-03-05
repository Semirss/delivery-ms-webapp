"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import NetworkStatus from "../components/NetworkStatus";

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

  // Authentication persistence & realtime
  useEffect(() => {
    const stored = localStorage.getItem('mvp_driver_session');
    if (stored) {
      setDriver(JSON.parse(stored));
    }
  }, []);

  useEffect(() => {
    if (driver?.id) {
      fetchData();

      const sub = supabase.channel('schema-db-changes')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'deliveries', filter: `driver_id=eq.${driver.id}` }, () => {
           fetchData();
        })
        .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'drivers', filter: `id=eq.${driver.id}` }, (payload) => {
           setDriver(payload.new as Driver);
           localStorage.setItem('mvp_driver_session', JSON.stringify(payload.new));
        })
        .subscribe();
        
      // Auto-refresh every 2 minutes for fail-safe syncing
      const intervalId = setInterval(() => {
         fetchData();
      }, 120000);

      return () => { 
        supabase.removeChannel(sub); 
        clearInterval(intervalId);
      };
    }
  }, [driver?.id]);

  const fetchData = async () => {
    if (!driver) return;
    try {
      const res = await fetch(`/api/deliveries?driver_id=${driver.id}`);
      const data = await res.json();
      setDeliveries(Array.isArray(data) ? data : []);
      setApiError(false);
    } catch (err) {
      console.error(err);
      setApiError(true);
    }
  };

  const handleAuth = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    setAuthError("");
    
    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData.entries());

    try {
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
    } catch (err: any) {
      setAuthError(err.message);
    }
    setLoading(false);
  };

  const handleLogout = () => {
    setDriver(null);
    localStorage.removeItem('mvp_driver_session');
  };

  const updateDeliveryStatus = async (id: string, status: string) => {
    const successMessages: Record<string, { title: string; message: string }> = {
      'Picked Up': { title: '🚲 En Route!', message: "Package picked up! You're now on the way to the customer." },
      'Delivered':  { title: '🏁 Delivered!', message: "Great work! The delivery has been completed successfully." },
      'Pending':    { title: '↩️ Reassigned', message: "Delivery sent back to pending. Another driver can pick it up." },
    };
    // Optimistically update local state so the UI changes instantly
    setDeliveries(prev => prev.map(d => d.id === id ? { ...d, status } : d));
    try {
      await fetch(`/api/deliveries/${id}/status`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status })
      });
      // Show success modal
      const msg = successMessages[status] || { title: 'Updated!', message: `Status changed to ${status}.` };
      setModalConfig({
        isOpen: true, type: 'alert', title: msg.title, message: msg.message,
        onConfirm: () => setModalConfig(prev => ({ ...prev, isOpen: false }))
      });
    } catch (err) {
      console.error(err);
      // Rollback on error
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
            <div className="mx-auto h-16 w-16 bg-blue-600 rounded-[1.2rem] flex items-center justify-center shadow-xl shadow-blue-500/30">
               <span className="text-2xl font-extrabold text-white leading-none">SD</span>
            </div>
            <h2 className="mt-6 text-center text-3xl font-extrabold text-neutral-900 tracking-tight">Driver Portal</h2>
            <p className="mt-2 text-center text-sm font-medium text-neutral-500">Welcome back</p>
          </div>
          
            <form className="space-y-5" onSubmit={handleAuth}>
              {authError && (
                <div className="p-4 bg-red-50 text-red-600 border border-red-200 rounded-xl text-sm text-center font-bold">
                  {authError}
                </div>
              )}
              
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

              <button disabled={loading} type="submit" className="w-full mt-6 py-4 px-4 rounded-xl shadow-xl shadow-blue-500/20 text-sm font-extrabold text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 transition-all">
                {loading ? 'Signing in...' : 'Sign In'}
              </button>
              
              <div className="text-center pt-2 flex justify-between px-2">
                 <button type="button" onClick={() => setShowTelegramModal(true)} className="text-sm font-bold text-neutral-500 hover:text-blue-600 transition-colors">
                    Need an account?
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
               <h1 className="font-extrabold text-lg text-neutral-900 leading-tight">Driver Portal</h1>
               <p className="text-xs font-bold text-neutral-400">Welcome, {driver.name}</p>
             </div>
          </div>
          <button onClick={handleLogout} className="text-neutral-400 hover:text-neutral-900 p-2 rounded-full hover:bg-neutral-50 transition-colors">
             <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
          </button>
        </div>

        {/* Online Toggle */}
        <div className="bg-neutral-50 p-4 rounded-2xl flex items-center justify-between border border-neutral-100">
           <div className="flex items-center space-x-3">
              <span className="text-xl">🏃</span>
              <div>
                 <p className="font-bold text-neutral-800 text-sm">Status</p>
                 <p className="text-xs font-medium text-neutral-500">Are you ready to ride?</p>
              </div>
           </div>
           
           <button 
              onClick={toggleOnlineStatus}
              className={`relative inline-flex h-8 w-14 items-center rounded-full transition-colors focus:outline-none ${driver.status === 'Online' ? 'bg-emerald-500' : 'bg-neutral-300'}`}
            >
              <span className={`inline-block h-6 w-6 transform rounded-full bg-white transition-transform ${driver.status === 'Online' ? 'translate-x-7 shadow-sm' : 'translate-x-1 shadow-sm'}`} />
            </button>
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
                        <button onClick={() => updateDeliveryStatus(job.id, 'Pending')} className="w-1/3 py-4 bg-white text-rose-500 border border-neutral-200 font-extrabold rounded-xl hover:bg-rose-50 shadow-sm text-sm transition-colors">
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
                            <p className="font-medium text-emerald-600 mt-0.5">{job.delivery_fee || 'TBD'}</p>
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
    </div>
  );
}
