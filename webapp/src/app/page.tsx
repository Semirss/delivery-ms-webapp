"use client";

import { useState } from "react";
import Link from "next/link";

export default function Home() {
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = e.currentTarget;
    setLoading(true);
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries()) as Record<string, any>;
    
    // Convert delivery_fee to number if present
    if (data.delivery_fee) {
      data.delivery_fee = parseFloat(data.delivery_fee as string);
    }
    
    try {
      const res = await fetch('/api/deliveries', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error("Failed to submit");
      setSuccess(true);
      form.reset();
    } catch(err) {
      console.error(err);
      alert("Failed to submit request.");
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full mx-auto space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900 tracking-tight">
            Request a Delivery
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Fast bike-based delivery service right to your door
          </p>
        </div>
        
        {success ? (
          <div className="bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-xl p-8 text-center shadow-sm">
            <div className="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" /></svg>
            </div>
            <h3 className="text-xl font-bold mb-2">Request Submitted!</h3>
            <p className="text-sm mb-6 text-emerald-700">We've received your delivery request. A driver will be assigned to you shortly.</p>
            <button 
              onClick={() => setSuccess(false)}
              className="px-6 py-2.5 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 font-bold transition-colors shadow-sm"
            >
              Submit Another Request
            </button>
          </div>
        ) : (
          <form className="bg-white shadow-xl rounded-2xl p-8 border border-gray-100 space-y-6" onSubmit={handleSubmit}>
            <div className="space-y-4">
              <div>
                <label htmlFor="customer_name" className="block text-sm font-bold text-gray-700 mb-1">Full Name</label>
                <input required type="text" name="customer_name" id="customer_name" className="block w-full border-gray-300 border rounded-lg shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-50 focus:bg-white transition-colors outline-none" placeholder="John Doe" />
              </div>
              
              <div>
                <label htmlFor="customer_phone" className="block text-sm font-bold text-gray-700 mb-1">Phone Number</label>
                <input required type="tel" name="customer_phone" id="customer_phone" className="block w-full border-gray-300 border rounded-lg shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-50 focus:bg-white transition-colors outline-none" placeholder="+1234567890" />
              </div>

              <div>
                <label htmlFor="pickup_location" className="block text-sm font-bold text-gray-700 mb-1">Pickup Location</label>
                <input required type="text" name="pickup_location" id="pickup_location" className="block w-full border-gray-300 border rounded-lg shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-50 focus:bg-white transition-colors outline-none" placeholder="123 Sender Street" />
              </div>

              <div>
                <label htmlFor="dropoff_location" className="block text-sm font-bold text-gray-700 mb-1">Drop-off Location</label>
                <input required type="text" name="dropoff_location" id="dropoff_location" className="block w-full border-gray-300 border rounded-lg shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-50 focus:bg-white transition-colors outline-none" placeholder="456 Receiver Avenue" />
              </div>
              
              <div className="grid grid-cols-2 gap-4 pt-2">
                <div>
                  <label htmlFor="package_type" className="block text-sm font-bold text-gray-700 mb-1">Package Type</label>
                  <input type="text" name="package_type" id="package_type" className="block w-full border-gray-300 border rounded-lg shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-50 focus:bg-white transition-colors outline-none" placeholder="Documents, Food..." />
                </div>
                <div>
                  <label htmlFor="delivery_fee" className="block text-sm font-bold text-gray-700 mb-1">Est. Fee ($)</label>
                  <input type="number" step="0.01" name="delivery_fee" id="delivery_fee" className="block w-full border-gray-300 border rounded-lg shadow-sm p-3.5 focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-50 focus:bg-white transition-colors outline-none" placeholder="10.00" />
                </div>
              </div>
            </div>

            <div className="pt-2">
              <button disabled={loading} type="submit" className="w-full flex justify-center py-3.5 px-4 border border-transparent rounded-lg shadow-md text-sm font-extrabold text-white bg-gray-900 hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-900 disabled:opacity-50 transition-all">
                {loading ? 'Submitting...' : 'Confirm Delivery Request'}
              </button>
            </div>
          </form>
        )}
        
        <div className="text-center mt-8">
          <Link href="/admin" className="inline-flex items-center text-sm font-bold text-gray-500 hover:text-gray-900 transition-colors">
            Go to Admin Dashboard 
            <svg className="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
          </Link>
        </div>
      </div>
    </div>
  );
}
