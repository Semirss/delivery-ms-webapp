"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { useRouter } from "next/navigation";
import NetworkStatus from "../components/NetworkStatus";
import Image from "next/image";
import dynamic from 'next/dynamic';

const LiveMap = dynamic(() => import('../components/LiveMap'), { ssr: false });

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
};

export default function AdminDashboard() {
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"deliveries" | "drivers" | "pending">("deliveries");
  const [filterStatus, setFilterStatus] = useState<string>("All");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [apiError, setApiError] = useState(false);
  const [modalConfig, setModalConfig] = useState<{
    isOpen: boolean; type: 'confirm' | 'alert' | 'prompt' | 'map'; title: string; message: string;
    fields?: { name: string; label: string; value: string }[];
    mapData?: { driverLat?: number; driverLng?: number; pickupLat?: number; pickupLng?: number; dropoffLat?: number; dropoffLng?: number; };
    onConfirm?: (data?: any) => void;
    onCancel?: () => void;
  }>({ isOpen: false, type: 'alert', title: '', message: '' });
  const router = useRouter();

  // Auto-refresh every 2 minutes for fail-safe syncing
  useEffect(() => {
    const intervalId = setInterval(() => {
      fetchData();
    }, 120000); // 2 minutes
    
    return () => clearInterval(intervalId);
  }, []);

  // Load Initial Data
  useEffect(() => {
    fetchData();

    // Supabase Real-time subscriptions
    const deliverySub = supabase.channel('schema-db-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'deliveries' }, () => {
         fetchData(); // Simplest way to ensure relations are fetched
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drivers' }, () => {
         fetchData();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(deliverySub);
    };
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

  const handleLogout = async () => {
    await fetch("/api/admin/logout", { method: "POST" });
    router.push("/admin/login");
    router.refresh();
  };

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
           fetchData(); // Rollback
        } else {
           if (driver.phone) {
              try {
                const res = await fetch('/api/sms/send', { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ phone: driver.phone, message: "🎉 Congratulations! You have been approved by the Admin. You can now Log In using your name and password." }) });
                if (!res.ok) {
                   const errData = await res.json();
                   setModalConfig({ 
                     isOpen: true, type: 'alert', 
                     title: 'Approval Succeeded (SMS Failed)', 
                     message: `Driver approved, but SMS failed: ${errData.error || 'Unknown error'}`,
                     onConfirm: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false }))
                   });
                }
              } catch (e) {
                console.error("Failed to notify driver via SMS", e);
              }
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
       message: 'Are you sure you want to completely DELETE this active driver? This may orphan their past deliveries.',
       onCancel: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false })),
       onConfirm: async () => {
          setModalConfig((prev: any) => ({ ...prev, isOpen: false }));
          const { error } = await supabase.from('drivers').delete().eq('id', id);
          if (error) {
             setModalConfig({ isOpen: true, type: 'alert', title: 'Failed to delete', message: error.message, onConfirm: () => setModalConfig((prev: any) => ({ ...prev, isOpen: false })) });
          }
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

  const assignDriver = async (deliveryId: string, driverId: string) => {
    await fetch(`/api/deliveries/${deliveryId}/assign`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ driver_id: driverId })
    });
    fetchData();
  };

  return (
    <div className="flex h-screen bg-neutral-50 text-neutral-900 font-sans relative">
      
      <NetworkStatus apiError={apiError} />

      {/* Mobile Sidebar Overlay */}
      {sidebarOpen && (
         <div 
           className="fixed inset-0 bg-neutral-900/50 backdrop-blur-sm z-30 md:hidden" 
           onClick={() => setSidebarOpen(false)}
         />
      )}

      {/* Persistent Sidebar */}
      <aside className={`fixed md:static inset-y-0 left-0 w-64 bg-neutral-900 text-white flex flex-col shadow-2xl z-40 transform transition-transform duration-300 ease-in-out ${sidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}`}>
        <div className="p-6 flex items-center justify-between">
          <div className="flex items-center space-x-3">
             <div className="h-10 w-10 rounded-xl flex items-center justify-center overflow-hidden shadow-lg shadow-blue-500/30">
                <Image src="/logo.jpg" alt="Motorbike Logo" width={40} height={40} className="object-cover" />
             </div>
             <h1 className="text-xl font-extrabold tracking-tight">Admin</h1>
          </div>
          <button className="md:hidden text-neutral-400 hover:text-white" onClick={() => setSidebarOpen(false)}>
             <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>
        
        <nav className="flex-1 px-4 space-y-2 mt-4">
          <button 
            onClick={() => setActiveTab('deliveries')}
            className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all ${activeTab === 'deliveries' ? 'bg-blue-600 font-bold shadow-md' : 'text-neutral-400 hover:bg-neutral-800 hover:text-white'}`}
          >
            <span>📦</span>
            <span>Deliveries</span>
          </button>
          
          <button 
            onClick={() => setActiveTab('drivers')}
            className={`w-full flex justify-between items-center px-4 py-3 rounded-xl transition-all ${activeTab === 'drivers' ? 'bg-blue-600 font-bold shadow-md' : 'text-neutral-400 hover:bg-neutral-800 hover:text-white'}`}
          >
            <div className="flex items-center space-x-3">
              <span>👤</span>
              <span>Drivers</span>
            </div>
            <span className="bg-neutral-800 text-xs px-2 py-1 rounded-full">{activeDrivers.length}</span>
          </button>
          
          <button 
            onClick={() => setActiveTab('pending')}
            className={`w-full flex justify-between items-center px-4 py-3 rounded-xl transition-all ${activeTab === 'pending' ? 'bg-amber-500 font-bold shadow-md text-white' : 'text-neutral-400 hover:bg-neutral-800 hover:text-white'}`}
          >
            <div className="flex items-center space-x-3">
              <span>⏳</span>
              <span>Approvals</span>
            </div>
            {pendingDrivers.length > 0 && (
              <span className="bg-amber-500 text-white text-xs font-bold px-2 py-1 rounded-full animate-pulse">{pendingDrivers.length}</span>
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

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col overflow-hidden bg-neutral-100 relative min-w-0">
         {/* Top Header */}
         <header className="bg-white px-6 md:px-8 py-5 border-b border-neutral-200 flex justify-between items-center shadow-sm z-10 sticky top-0">
            <div className="flex items-center space-x-4">
               <button className="md:hidden text-neutral-500 hover:text-neutral-900 p-1" onClick={() => setSidebarOpen(true)}>
                  <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" /></svg>
               </button>
               <h2 className="text-xl md:text-2xl font-extrabold text-neutral-800 capitalize truncate">
                  {activeTab === 'pending' ? 'Pending Approvals' : activeTab}
               </h2>
            </div>
            <div className="flex items-center space-x-3 flex-shrink-0">
               <span className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></span>
               <span className="text-sm font-bold text-neutral-500 uppercase tracking-wider">Live Sync</span>
            </div>
         </header>

         {/* Content Scroll */}
         <div className="flex-1 overflow-auto p-8 relative">
            {loading ? (
               <div className="absolute inset-0 flex items-center justify-center">
                  <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
               </div>
            ) : (
               <div className="max-w-6xl mx-auto">
                 
                 {/* DELIVERIES TAB */}
                 {activeTab === 'deliveries' && (
                    <div className="space-y-6">
                       <div className="flex justify-between items-center mb-2">
                           <h3 className="font-extrabold text-neutral-800 text-lg">Delivery Board</h3>
                           <select 
                               className="block rounded-xl border-neutral-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm font-medium py-2 pl-3 pr-10 text-neutral-700 bg-white"
                               value={filterStatus}
                               onChange={(e) => setFilterStatus(e.target.value)}
                           >
                               <option value="All">All Statuses</option>
                               <option value="Pending">Pending</option>
                               <option value="Assigned">Assigned</option>
                               <option value="Picked Up">Picked Up</option>
                               <option value="Delivered">Delivered</option>
                               <option value="Cancelled">Cancelled</option>
                           </select>
                       </div>
                       
                       <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                          <div className="bg-white p-6 rounded-2xl shadow-sm border border-neutral-100 flex items-center">
                            <div className="h-12 w-12 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center text-xl mr-4">📦</div>
                            <div>
                               <p className="text-sm text-neutral-500 font-medium">Total Requests</p>
                               <p className="text-2xl font-extrabold">{deliveries.length}</p>
                            </div>
                          </div>
                          <div className="bg-white p-6 rounded-2xl shadow-sm border border-neutral-100 flex items-center">
                            <div className="h-12 w-12 bg-amber-50 text-amber-600 rounded-full flex items-center justify-center text-xl mr-4">⏳</div>
                            <div>
                               <p className="text-sm text-neutral-500 font-medium">Pending Dispatch</p>
                               <p className="text-2xl font-extrabold">{deliveries.filter(d => d.status === 'Pending').length}</p>
                            </div>
                          </div>
                          <div className="bg-white p-6 rounded-2xl shadow-sm border border-neutral-100 flex items-center">
                            <div className="h-12 w-12 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center text-xl mr-4">🏁</div>
                            <div>
                               <p className="text-sm text-neutral-500 font-medium">Completed</p>
                               <p className="text-2xl font-extrabold">{deliveries.filter(d => d.status === 'Delivered').length}</p>
                            </div>
                          </div>
                       </div>

                       <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                           {deliveries.filter(d => filterStatus === "All" || d.status === filterStatus).length === 0 && (
                               <div className="col-span-full py-12 text-center text-neutral-500 font-medium bg-white rounded-2xl border border-neutral-200">No deliveries found for this filter.</div>
                           )}
                           {deliveries.filter(d => filterStatus === "All" || d.status === filterStatus).map(d => (
                              <div key={d.id} className="bg-white rounded-2xl border border-neutral-200 shadow-sm p-6 flex flex-col relative group hover:shadow-md transition-shadow">
                                  <div className="flex justify-between items-start mb-4">
                                      <div>
                                          <h3 className="font-extrabold text-neutral-900 text-lg">{d.customer_name}</h3>
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
                                  
                                  <div className="flex-1 space-y-3 mb-6">
                                      <div className="flex items-start bg-neutral-50 p-3 rounded-xl">
                                          <span className="text-blue-500 mr-2 flex-shrink-0">🟢</span>
                                          <span className="text-sm font-medium text-neutral-800 line-clamp-2">{d.pickup_location}</span>
                                      </div>
                                      <div className="flex items-start bg-neutral-50 p-3 rounded-xl">
                                          <span className="text-red-500 mr-2 flex-shrink-0">📍</span>
                                          <span className="text-sm font-medium text-neutral-800 line-clamp-2">{d.dropoff_location}</span>
                                      </div>

                                      <div className="grid grid-cols-2 gap-2 mt-4">
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

                                  <div className="mt-auto pt-4 border-t border-neutral-100">
                                      {d.status === 'Pending' ? (
                                          <div className="space-y-2">
                                              <select 
                                                className="block w-full text-sm rounded-xl border-neutral-200 bg-neutral-50 focus:ring-blue-500 focus:border-blue-500 font-medium py-3"
                                                onChange={(e) => {
                                                   if (e.target.value) assignDriver(d.id, e.target.value);
                                                }}
                                                defaultValue=""
                                              >
                                                <option value="" disabled>Assign Driver...</option>
                                                {activeDrivers.filter(drv => drv.status === 'Online').map(drv => (
                                                   <option key={drv.id} value={drv.id}>{drv.name} ({drv.vehicle_type || 'Bike'} - Online)</option>
                                                ))}
                                                {activeDrivers.filter(drv => drv.status === 'Offline').map(drv => (
                                                   <option key={drv.id} value={drv.id}>{drv.name} ({drv.vehicle_type || 'Bike'} - Offline)</option>
                                                ))}
                                              </select>
                                          </div>
                                      ) : (
                                          <div className="flex items-center justify-between p-3 bg-neutral-50 rounded-xl">
                                              <p className="text-xs font-bold text-neutral-400 uppercase tracking-wide">Driver</p>
                                              <p className="font-bold text-neutral-800 text-sm flex items-center">
                                                  <span className="mr-1.5">{d.driver?.vehicle_type === 'Motor' ? '🏍️' : '🚲'}</span>
                                                  {d.driver?.name}
                                              </p>
                                          </div>
                                      )}

                                      {/* Tracking Map Button */}
                                      {['Assigned', 'Picked Up'].includes(d.status) && (
                                         <button 
                                            className="w-full mt-3 flex items-center justify-center space-x-2 bg-neutral-900 text-white py-2.5 rounded-xl text-sm font-bold shadow-sm hover:bg-black transition-colors"
                                            onClick={() => setModalConfig({
                                               isOpen: true, type: 'map', title: `Track: ${d.customer_name}`, message: '',
                                               mapData: { 
                                                 driverLat: d.driver?.current_lat, driverLng: d.driver?.current_lng,
                                                 pickupLat: d.pickup_lat, pickupLng: d.pickup_lng,
                                                 dropoffLat: d.dropoff_lat, dropoffLng: d.dropoff_lng
                                               },
                                               onConfirm: () => setModalConfig(prev => ({...prev, isOpen: false}))
                                            })}
                                         >
                                            <span>🗺️</span>
                                            <span>Live Tracking</span>
                                         </button>
                                      )}
                                  </div>
                              </div>
                           ))}
                       </div>
                    </div>
                 )}

                 {/* DRIVERS TAB */}
                 {activeTab === 'drivers' && (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                       {activeDrivers.map(drv => (
                          <div key={drv.id} className="bg-white rounded-2xl shadow-sm border border-neutral-200 p-6 flex flex-col relative overflow-hidden group">
                             <div className="absolute top-0 right-0 p-4">
                                <span className={`inline-flex w-3 h-3 rounded-full shadow-inner ${drv.status === 'Online' ? 'bg-emerald-500 shadow-emerald-500/50' : 'bg-neutral-300'}`}></span>
                             </div>
                             
                             <div className="h-16 w-16 bg-gradient-to-br from-blue-50 to-blue-100 text-blue-600 rounded-full flex items-center justify-center text-2xl font-bold mb-4">
                                {drv.name.charAt(0)}
                             </div>
                             <h3 className="text-xl font-extrabold text-neutral-900 truncate">{drv.name}</h3>
                             <p className="text-neutral-500 font-medium mt-1 truncate">{drv.phone}</p>
                             <p className="text-neutral-400 text-sm mt-1 truncate">{drv.telegram_username || drv.telegram_id || 'No Telegram'}</p>
                             <div className="flex items-center space-x-2 mt-2">
                                <span className="text-neutral-600 font-bold text-sm">Plate: {drv.plate_number || 'N/A'}</span>
                                <span className={`text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-lg ${drv.vehicle_type === 'Motor' ? 'bg-amber-100 text-amber-700' : 'bg-indigo-100 text-indigo-700'}`}>
                                  {drv.vehicle_type === 'Motor' ? '🏍️ Motor' : '🚲 Bike'}
                                </span>
                             </div>
                             
                             <div className="mt-4 flex space-x-2">
                                <button onClick={() => editDriver(drv.id)} className="flex-1 px-3 py-1.5 bg-neutral-100 text-neutral-600 font-bold text-xs rounded-lg hover:bg-neutral-200 transition-colors">Edit</button>
                                {drv.personal_id_url && (
                                   <a href={drv.personal_id_url} target="_blank" rel="noopener noreferrer" className="flex-1 px-3 py-1.5 bg-blue-50 text-blue-600 font-bold text-xs rounded-lg text-center hover:bg-blue-100 transition-colors">View ID</a>
                                )}
                                <button onClick={() => deleteDriver(drv.id)} className="flex-1 px-3 py-1.5 bg-red-50 text-red-600 font-bold text-xs rounded-lg hover:bg-red-100 transition-colors">Delete</button>
                             </div>

                             <div className="mt-4 pt-4 border-t border-neutral-100 flex justify-between items-center w-full relative z-10">
                                <span className="text-sm font-bold text-neutral-500 pt-1">Status</span>
                                <span className={`text-sm font-bold px-3 py-1 rounded-full ${drv.status === 'Online' ? 'bg-emerald-50 text-emerald-700' : 'bg-neutral-100 text-neutral-600'}`}>{drv.status}</span>
                             </div>
                          </div>
                       ))}
                       {activeDrivers.length === 0 && (
                          <div className="col-span-full bg-white p-12 text-center rounded-2xl border border-dashed border-neutral-300 text-neutral-500 font-medium">
                             No approved drivers yet.
                          </div>
                       )}
                    </div>
                 )}

                 {/* PENDING APPROVALS TAB */}
                 {activeTab === 'pending' && (
                    <div className="max-w-3xl mx-auto space-y-4">
                       {pendingDrivers.map(drv => (
                          <div key={drv.id} className="bg-white rounded-2xl shadow-md border-l-4 border-l-amber-500 border-y border-r border-neutral-200 p-6 flex items-center justify-between">
                             <div className="flex items-center space-x-6">
                                <div className="h-14 w-14 bg-amber-50 text-amber-600 rounded-full flex items-center justify-center text-xl font-bold">
                                   {drv.name.charAt(0)}
                                </div>
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
                                   <a href={drv.personal_id_url} target="_blank" rel="noopener noreferrer" className="px-4 py-2 bg-blue-50 text-blue-600 font-bold text-center rounded-xl hover:bg-blue-100 transition-colors w-full sm:w-auto text-sm">
                                      View ID
                                   </a>
                                )}
                                <button onClick={() => rejectDriver(drv.id)} className="px-4 py-2 bg-neutral-100 text-neutral-600 font-bold justify-center rounded-xl hover:bg-neutral-200 transition-colors w-full sm:w-auto text-sm">
                                   Reject
                                </button>
                                <button onClick={() => approveDriver(drv)} className="px-4 py-2 bg-blue-600 shadow-lg shadow-blue-600/20 text-white font-bold rounded-xl hover:bg-blue-700 transition-all w-full sm:w-auto text-sm">
                                   Approve
                                </button>
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
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-md overflow-hidden relative z-10 animate-in fade-in zoom-in duration-200">
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
                    <div className="space-y-6">
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
                                <div className="h-[400px] flex items-center justify-center bg-neutral-100 text-neutral-500 font-bold">
                                   No tracking data available.
                                </div>
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
                    <button type={modalConfig.type === 'prompt' ? 'submit' : 'button'} form={modalConfig.type === 'prompt' ? 'modal-form' : undefined} onClick={modalConfig.type !== 'prompt' ? modalConfig.onConfirm : undefined} className="px-5 py-2.5 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 shadow-lg shadow-blue-500/20 transition-all text-sm">
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
