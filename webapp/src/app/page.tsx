"use client";

import { motion } from "framer-motion";
import { ArrowRight, Package, MapPin, CheckCircle, ShieldCheck, Map, Clock, HelpCircle, ChevronRight, Bike, Zap } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

// ── Contact details ──
const CONTACT_PHONE = "+251931323328";
const CONTACT_PHONE2 = "+251920202304";
const CONTACT_EMAIL = "Natnaeltegestuu@gmail.com";
const CONTACT_TELEGRAM = "motorbike_et";

export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false);
  const [contactOpen, setContactOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const fadeIn: any = {
    hidden: { opacity: 0, y: 30 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.8, ease: "easeOut" } }
  };

  const staggerContainer: any = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { staggerChildren: 0.15 } }
  };

  return (
    <div className="min-h-screen bg-[#e8ebea] text-neutral-900 selection:bg-purple-200 overflow-x-hidden font-sans">
      {/* Background Soft Gradients */}
      <div className="fixed top-[-20%] left-[-10%] w-[50%] h-[50%] bg-[#f4f7f6] blur-[100px] rounded-full pointer-events-none" />
      <div className="fixed bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-white/50 blur-[100px] rounded-full pointer-events-none" />

      {/* Navigation */}
      <nav className={`fixed top-0 w-full z-50 transition-all duration-500 ${scrolled ? "bg-[#e8ebea]/70 backdrop-blur-2xl py-4" : "bg-transparent py-8"}`}>
        <div className="max-w-7xl mx-auto px-6 md:px-10 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="relative w-9 h-9 rounded-xl overflow-hidden shadow-sm">
              <Image src="/favlogo1.png" alt="MotoBike Logo" fill className="object-cover" />
            </div>
            <span className="text-xl font-bold tracking-tight text-neutral-900">MotoBike</span>
          </div>
          <div className="hidden md:flex items-center space-x-10 text-sm font-medium text-neutral-600">
            <a href="#about" className="hover:text-black transition-colors">About us</a>
            <a href="#pricing" className="hover:text-black transition-colors">Pricing</a>
            <a href="#features" className="hover:text-black transition-colors">Features</a>
          </div>
          <div className="flex items-center space-x-6">
            <Link href="/book">
              <button className="bg-white text-black px-6 py-3 rounded-full font-semibold text-sm hover:scale-105 active:scale-95 transition-transform shadow-[0_8px_20px_rgba(0,0,0,0.04)] hover:shadow-[0_12px_25px_rgba(0,0,0,0.06)]">
                Order delivery
              </button>
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <main className="relative pt-40 md:pt-48 pb-10 px-6 md:px-10">
        <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-12 lg:gap-8 items-center">
          <motion.div 
            initial="hidden"
            animate="visible"
            variants={staggerContainer}
            className="flex flex-col items-start text-left relative z-10 w-full mb-16 lg:mb-0"
          >
            <motion.div variants={fadeIn} className="inline-flex items-center space-x-2 bg-white/60 backdrop-blur-xl border border-white/80 px-4 py-2 rounded-full text-neutral-800 text-sm font-medium mb-6 shadow-sm">
              <span className="text-lg">🇪🇹</span>
              <span>በአዲስ አበባ ፈጣን የመልእክት አገልግሎት</span>
            </motion.div>

            <motion.h1 variants={fadeIn} className="text-5xl sm:text-6xl md:text-[5rem] lg:text-[5.5rem] font-bold tracking-[-0.03em] leading-[1.05] text-neutral-900 mb-8">
              Fast delivery,<br />
              <span className="text-neutral-500">anywhere in Addis.</span>
            </motion.h1>
            
            <motion.p variants={fadeIn} className="text-xl text-neutral-600 max-w-lg leading-snug mb-10">
              Skip the long taxi queues and chaotic roads. We connect businesses and individuals with trusted local couriers for fast, secure deliveries from Piassa to Bole.
            </motion.p>
            
            <motion.div variants={fadeIn} className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto">
              <Link href="/book" className="w-full sm:w-auto">
                <button className="w-full sm:w-auto bg-black text-white px-8 py-4 rounded-full font-medium text-lg flex items-center justify-center space-x-2 hover:bg-neutral-800 transition-all active:scale-95 shadow-[0_10px_20px_rgba(0,0,0,0.1)]">
                  <span>አሁን እዘዝ (Order Now)</span>
                  <ArrowRight className="w-5 h-5" />
                </button>
              </Link>
              <a href="#about" className="w-full sm:w-auto text-center px-8 py-4 bg-white/80 backdrop-blur-md rounded-full font-medium text-lg text-neutral-900 hover:bg-white transition-all shadow-sm">
                Learn more
              </a>
            </motion.div>
          </motion.div>

          {/* Hero Visual: Phone Mockup */}
          <div className="relative flex justify-center lg:justify-end lg:pr-10 mt-8 lg:mt-0">
            <motion.div 
              initial={{ opacity: 0, y: 50, rotate: 2 }}
              animate={{ opacity: 1, y: 0, rotate: -2 }}
              transition={{ duration: 1, delay: 0.2, ease: "easeOut" }}
              className="relative w-full max-w-[320px] aspect-[1/2] rounded-[3rem] border-[10px] border-neutral-900 bg-[#f4f6f5] shadow-2xl overflow-hidden group hover:rotate-0 transition-transform duration-500"
            >
              {/* Phone Notch */}
              <div className="absolute top-0 inset-x-0 h-7 bg-neutral-900 rounded-b-2xl w-36 mx-auto z-30" />
              
              {/* Map Background UI */}
              <div className="absolute inset-0 bg-[#e8ecea] overflow-hidden rounded-[3rem]">
                {/* Real map background of Addis Ababa */}
                <iframe 
                  src="https://www.openstreetmap.org/export/embed.html?bbox=38.74,9.00,38.78,9.04&layer=mapnik" 
                  className="absolute -inset-10 w-[150%] h-[150%] pointer-events-none opacity-[0.6] grayscale"
                  tabIndex={-1}
                />
                
                {/* Gradient overlay to ensure UI elements are readable */}
                <div className="absolute inset-0 bg-gradient-to-t from-[#eef1ef] via-transparent to-white/40 pointer-events-none" />
                
                {/* Accurate GPS Route SVG */}
               

                {/* Moving Marker interpolating over the Bezier Curve (M 25 30 C 25 60, 75 50, 75 80) */}
                <motion.div 
                  animate={{ 
                    left: ["25%", "32.8%", "50%", "67.2%", "75%", "75%", "25%"],
                    top:  ["30%", "41.2%", "55%", "68.8%", "80%", "80%", "30%"] 
                  }}
                  transition={{ duration: 7, repeat: Infinity, ease: "easeInOut", times: [0, 0.2, 0.4, 0.6, 0.8, 0.95, 1] }}
                  className="absolute w-8 h-8 bg-white border-[2.5px] border-neutral-900 rounded-full shadow-lg flex items-center justify-center z-20 -translate-x-1/2 -translate-y-1/2"
                >
                  <Package className="w-4 h-4 text-neutral-900" />
                </motion.div>

                {/* Pickup Pin */}
                <div className="absolute w-3.5 h-3.5 bg-neutral-900 rounded-full ring-4 ring-black/10 z-10 -translate-x-1/2 -translate-y-1/2 drop-shadow-sm" style={{ top: '30%', left: '25%' }} />
                
                {/* Dropoff Pin */}
                <div className="absolute w-5 h-5 bg-emerald-500 rounded-full ring-4 ring-emerald-500/20 flex items-center justify-center z-10 -translate-x-1/2 -translate-y-1/2 drop-shadow-sm" style={{ top: '80%', left: '75%' }}>
                  <div className="w-2 h-2 bg-white rounded-full shadow-sm" />
                </div>
              </div>

              {/* Floating UI Elements over map */}
              <div className="absolute inset-0 z-20 flex flex-col justify-between p-4 pb-6 pt-12 pointer-events-none">
                
                {/* Top Notification */}
                <div className="bg-white/95 backdrop-blur-md rounded-3xl p-3 shadow-lg shadow-black/5 mx-2 flex items-center space-x-3 transform group-hover:translate-y-2 transition-transform duration-500 pointer-events-auto">
                  <div className="w-12 h-12 bg-orange-50 rounded-full flex items-center justify-center border border-orange-100">
                    <span className="text-2xl filter drop-shadow-sm">🏍️</span>
                  </div>
                  <div>
                    <h4 className="font-extrabold text-[15px] text-neutral-900">Arriving in 12 min</h4>
                    <p className="text-xs text-neutral-500 font-medium tracking-wide">Rider: Abel T.</p>
                  </div>
                </div>

                {/* Bottom Sheet UI */}
                <div className="bg-white rounded-[2rem] p-6 shadow-[0_-10px_40px_rgba(0,0,0,0.05)] mx-1 transform group-hover:-translate-y-2 transition-transform duration-500 pointer-events-auto">
                  <div className="w-12 h-1.5 bg-neutral-200 rounded-full mx-auto mb-5" />
                  <h4 className="font-extrabold text-xl mb-1 text-neutral-900">En route to Dropoff</h4>
                  <p className="text-[13px] text-neutral-500 mb-6 font-medium">Bole Medhanialem, Addis Ababa</p>
                  
                  <div className="w-full bg-neutral-100 h-2.5 rounded-full overflow-hidden mb-3">
                    <div className="bg-black w-[65%] h-full rounded-full relative">
                      <div className="absolute inset-0 bg-white/20 animate-pulse" />
                    </div>
                  </div>
                  <div className="flex justify-between text-[11px] text-neutral-400 font-bold uppercase tracking-wider">
                    <span>Pickup</span>
                    <span className="text-black">Dropoff</span>
                  </div>
                </div>

              </div>
            </motion.div>
          </div>
        </div>
      </main>

      {/* About Section */}
      <section id="about" className="py-24 relative z-10">
        <div className="max-w-7xl mx-auto px-6 md:px-10">
          <motion.div 
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
            className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center"
          >
            <motion.div variants={fadeIn} className="relative w-full max-w-md mx-auto order-2 lg:order-1 mt-8 lg:mt-0">
              <div className="absolute inset-0 bg-blue-100 rounded-full blur-3xl opacity-50" />
              <div className="w-full bg-white/60 backdrop-blur-xl border border-white/80 rounded-[2.5rem] sm:rounded-[3rem] p-8 sm:p-10 shadow-2xl shadow-black/5 flex flex-col justify-center relative overflow-hidden">
                <div className="absolute -top-10 -right-10 w-40 h-40 bg-orange-100 rounded-full blur-2xl pointer-events-none" />
                <h3 className="text-2xl sm:text-3xl font-bold mb-6 relative z-10 text-neutral-800 leading-snug">"We grew up navigating these streets."</h3>
                <p className="text-neutral-600 text-base sm:text-lg leading-relaxed relative z-10">
                  MotoBike is a proudly Ethiopian startup built to solve the daily logistics nightmare of Addis Ababa. Whether you need an important document signed in Megenagna or a forgotten laptop brought to your office in Kazanchis, our riders know the shortcuts.
                </p>
                <div className="mt-8 flex items-center space-x-3 relative z-10">
                  <div className="w-12 h-12 rounded-full overflow-hidden border border-neutral-200 shadow-sm relative shrink-0">
                    <Image src="/favlogo1.png" alt="Local Rider" fill className="object-cover" />
                  </div>
                  <div className="flex flex-col">
                    <span className="font-bold text-neutral-900 leading-tight">Natnael Tegestu</span>
                    <span className="text-xs sm:text-sm text-neutral-500">Founder, MotoBike</span>
                  </div>
                </div>
              </div>
            </motion.div>
            
            <motion.div variants={fadeIn} className="space-y-6 lg:space-y-8 order-1 lg:order-2">
              <div>
                <span className="text-emerald-600 font-bold tracking-wider uppercase text-xs sm:text-sm mb-2 block">About MotoBike</span>
                <h2 className="text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-neutral-900 mb-6 leading-tight">Connecting the city, one drop-off at a time.</h2>
                <p className="text-base sm:text-lg text-neutral-600 leading-relaxed mb-6">
                  Delivery in Ethiopia traditionally relied on unofficial middlemen or slow postal systems. MotoBike changes the narrative by offering an app-driven, professional courier network built specifically for our local terrain.
                </p>
                <p className="text-base sm:text-lg text-neutral-600 leading-relaxed">
                  We empower young Ethiopian riders with steady income while providing unmatched speed and transparency for our clients. No hidden fees, no unreliable timing—just fast delivery you can trust.
                </p>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-24 bg-[#f8f9fa] border-y border-neutral-200/50 relative z-10">
        <div className="max-w-7xl mx-auto px-6 md:px-10">
          <div className="text-center mb-16 space-y-4">
            <span className="text-orange-600 font-bold tracking-wider uppercase text-sm block">Transparent Pricing</span>
            <h2 className="text-4xl md:text-5xl font-bold tracking-tight text-neutral-900">Simple, fair rates for Addis.</h2>
            <p className="text-lg text-neutral-600 max-w-2xl mx-auto">Pay strictly by distance and vehicle type. No unpredictable surges, no haggling.</p>
          </div>

          <motion.div 
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
            className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto"
          >
            {/* Eco Bike Pricing */}
            <motion.div variants={fadeIn} className="bg-white/80 backdrop-blur-xl border border-white p-10 rounded-[2.5rem] shadow-[0_20px_40px_rgba(0,0,0,0.04)] relative overflow-hidden group">
              <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-100 blur-[60px] pointer-events-none group-hover:scale-110 transition-transform duration-500" />
              <div className="relative z-10 flex flex-col h-full">
                <div className="w-14 h-14 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center justify-center mb-6">
                  <span className="text-3xl filter drop-shadow-sm">🚲</span>
                </div>
                <h3 className="text-2xl font-bold text-neutral-900 mb-2">Bicycle Courier</h3>
                <p className="text-neutral-500 mb-6">Best for light items, documents, and navigating localized traffic jams.</p>
                <div className="flex items-end space-x-2 mb-8">
                  <span className="text-5xl font-bold text-neutral-900">200</span>
                  <span className="text-lg text-neutral-500 font-medium pb-1.5">ETB</span>
                  <span className="text-sm text-neutral-400 pb-2">/ base fare</span>
                </div>
                <ul className="space-y-4 flex-1 mb-8">
                  <li className="flex items-center space-x-3 text-neutral-700">
                    <CheckCircle className="w-5 h-5 text-emerald-500 flex-shrink-0" />
                    <span>Up to 5kg weight limit</span>
                  </li>
                  <li className="flex items-center space-x-3 text-neutral-700">
                    <CheckCircle className="w-5 h-5 text-emerald-500 flex-shrink-0" />
                    <span>Zero emissions footprint</span>
                  </li>
                  <li className="flex items-center space-x-3 text-neutral-700">
                    <CheckCircle className="w-5 h-5 text-emerald-500 flex-shrink-0" />
                    <span>Ideal for areas like Bole, Piassa</span>
                  </li>
                </ul>
                <Link href="/book">
                  <button className="w-full bg-[#f0f2f5] hover:bg-emerald-50 text-emerald-700 font-bold py-4 rounded-xl transition-colors">
                    Book a Bicycle
                  </button>
                </Link>
              </div>
            </motion.div>

            {/* Motorbike Pricing */}
            <motion.div variants={fadeIn} className="bg-neutral-900 border border-neutral-800 p-10 rounded-[2.5rem] shadow-[0_30px_60px_rgba(0,0,0,0.15)] relative overflow-hidden group">
              <div className="absolute top-0 right-0 w-32 h-32 bg-purple-900/40 blur-[60px] pointer-events-none group-hover:scale-110 transition-transform duration-500" />
              <div className="absolute top-5 right-5 bg-white/10 backdrop-blur-md px-3 py-1 rounded-full border border-white/20">
                <span className="text-xs font-bold text-white uppercase tracking-wider">Most Popular</span>
              </div>
              <div className="relative z-10 flex flex-col h-full">
                <div className="w-14 h-14 bg-white/10 text-white rounded-2xl flex items-center justify-center mb-6">
                  <span className="text-3xl filter drop-shadow-sm">🏍️</span>
                </div>
                <h3 className="text-2xl font-bold text-white mb-2">Motorbike Courier</h3>
                <p className="text-neutral-400 mb-6">Fastest option across the entire city, capable of handling heavier packages.</p>
                <div className="flex items-end space-x-2 mb-8">
                  <span className="text-5xl font-bold text-white">350</span>
                  <span className="text-lg text-neutral-400 font-medium pb-1.5">ETB</span>
                  <span className="text-sm text-neutral-500 pb-2">/ base fare</span>
                </div>
                <ul className="space-y-4 flex-1 mb-8">
                  <li className="flex items-center space-x-3 text-neutral-300">
                    <CheckCircle className="w-5 h-5 text-purple-400 flex-shrink-0" />
                    <span>Up to 20kg weight limit</span>
                  </li>
                  <li className="flex items-center space-x-3 text-neutral-300">
                    <CheckCircle className="w-5 h-5 text-purple-400 flex-shrink-0" />
                    <span>Cross-city delivery (e.g. Kality to CMC)</span>
                  </li>
                  <li className="flex items-center space-x-3 text-neutral-300">
                    <CheckCircle className="w-5 h-5 text-purple-400 flex-shrink-0" />
                    <span>Heavy duty, weather-resistant box</span>
                  </li>
                </ul>
                <Link href="/book">
                  <button className="w-full bg-white text-black hover:bg-neutral-200 font-bold py-4 rounded-xl transition-colors shadow-[0_10px_20px_rgba(255,255,255,0.1)]">
                    Book a Motorbike
                  </button>
                </Link>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-24 relative z-10">
        <div className="max-w-7xl mx-auto px-6 md:px-10">
          <div className="text-center mb-16 space-y-4">
            <span className="text-indigo-600 font-bold tracking-wider uppercase text-sm block">Why MotoBike</span>
            <h2 className="text-4xl md:text-5xl font-bold tracking-tight text-neutral-900">Built for the local hustle.</h2>
          </div>

          <motion.div 
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
            className="grid lg:grid-cols-3 gap-6 relative z-10"
          >
            {[
              {
                title: "Local Traffic Experts",
                desc: "Our dispatch explicitly routes riders through familiar backstreets, completely avoiding gridlocked main roads during rush hours.",
                icon: <Map className="w-6 h-6 text-orange-500" />,
                bgClass: "bg-white",
              },
              {
                title: "Reliable Verification",
                desc: "Each driver registers with their official Kebele ID, passing comprehensive background checks. Your valuable items are safe.",
                icon: <ShieldCheck className="w-6 h-6 text-indigo-500" />,
                bgClass: "bg-gradient-to-b from-[#f8f9fa] to-[#e4e7ea]",
              },
              {
                title: "Live Ethio Telecom SMS",
                desc: "Get SMS updates sent directly to your phone when the rider is dispatched, arriving at pickup, and delivery completion.",
                icon: <Zap className="w-6 h-6 text-emerald-500" />,
                bgClass: "bg-gradient-to-tr from-stone-100 to-white",
              }
            ].map((card, idx) => (
              <motion.div 
                key={idx}
                variants={fadeIn}
                className={`p-8 md:p-10 rounded-[2.5rem] flex flex-col justify-between h-[320px] shadow-[0_20px_40px_rgba(0,0,0,0.03)] border border-white/50 relative overflow-hidden group ${card.bgClass}`}
              >
                <div className="absolute top-0 right-0 w-32 h-32 bg-white/50 blur-[50px] pointer-events-none" />

                <div className="w-14 h-14 rounded-2xl bg-white shadow-sm border border-neutral-100 flex items-center justify-center mb-8 relative z-10 group-hover:scale-110 transition-transform">
                  {card.icon}
                </div>

                <div className="z-10 mt-auto">
                  <h3 className="text-2xl font-bold mb-3 tracking-tight text-neutral-900">{card.title}</h3>
                  <p className="text-sm md:text-base text-neutral-600 leading-relaxed mb-2">{card.desc}</p>
                </div>
              </motion.div>
            ))}
          </motion.div>

          <div className="mt-20 text-center">
            <div className="inline-flex items-center space-x-4 bg-white/80 backdrop-blur-md p-2 pr-6 rounded-full shadow-sm border border-neutral-200">
              <div className="w-12 h-12 rounded-full overflow-hidden bg-emerald-100 border border-white flex items-center justify-center text-2xl filter drop-shadow-sm">
                📞
              </div>
              <div className="text-left leading-tight">
                <p className="font-bold text-neutral-900">Need corporate delivery?</p>
                <p className="text-sm text-neutral-500">Call us around the clock at <a href="tel:+251931323328" className="text-indigo-600 font-bold">+251 93 132 3328</a></p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="mt-10 py-10 border-t border-neutral-200/50 bg-[#e8ebea] relative z-10">
        <div className="max-w-7xl mx-auto px-6 md:px-10 flex flex-col md:flex-row justify-between items-center gap-6">
          <div className="flex flex-col md:flex-row items-center gap-4">
            <div className="w-10 h-10 rounded-xl overflow-hidden shadow-sm relative  opacity-70">
              <Image src="/favlogo1.png" alt="MotoBike Logo" fill className="object-cover" />
            </div>
            <span className="text-neutral-500 font-medium text-sm text-center md:text-left pt-1">
              © {new Date().getFullYear()} MotoBike Logistics P.L.C. & <a className="text-gray-500" href="https://semir-sultan.vercel.app">Semir Production</a><br />
              Addis Ababa, Ethiopia
            </span>
          </div>
          <div className="flex space-x-6 text-sm font-medium text-neutral-600">
            <a href="#about" className="hover:text-black transition-colors">About Us</a>
            <a href="#pricing" className="hover:text-black transition-colors">Pricing</a>
            <a href="#" className="hover:text-black transition-colors">Terms of Service</a>
          </div>
        </div>
      </footer>

      {/* Upward-Popping Contact FAB */}
      <div className="fixed bottom-6 right-6 z-50 flex flex-col items-end">
        <div
          className={`flex flex-col gap-3 mb-4 transition-all duration-300 origin-bottom ${
            contactOpen
              ? "opacity-100 scale-100 translate-y-0"
              : "opacity-0 scale-75 translate-y-10 pointer-events-none"
          }`}
        >
          {/* Telegram */}
          <button
            onClick={() => {
              if (typeof window !== "undefined") {
                const tg = (window as any).Telegram?.WebApp;
                const url = `https://t.me/${CONTACT_TELEGRAM}`;
                if (tg && tg.openTelegramLink) {
                  tg.openTelegramLink(url);
                } else {
                  window.open(url, "_blank");
                }
              }
            }}
            className="flex items-center justify-center w-12 h-12 bg-[#229ED9] hover:bg-[#1f8ec2] shadow-lg rounded-full text-white transition-transform hover:scale-110"
            aria-label="Telegram"
          >
            <svg className="w-5 h-5 ml-[-2px]" fill="currentColor" viewBox="0 0 24 24">
              <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.664 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/>
            </svg>
          </button>

          {/* Email */}
          <a
            href={`mailto:${CONTACT_EMAIL}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center w-12 h-12 bg-indigo-500 hover:bg-indigo-400 shadow-lg rounded-full text-white transition-transform hover:scale-110"
            aria-label="Email"
          >
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
            </svg>
          </a>

          {/* Phone 2 */}
          <a
            href={`tel:${CONTACT_PHONE2}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center w-12 h-12 bg-emerald-500 hover:bg-emerald-400 shadow-lg rounded-full text-white transition-transform hover:scale-110"
            aria-label="Call Alternative"
          >
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-2.896-1.596-5.48-4.18-7.076-7.076l1.293-.97c.362-.271.527-.733.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z" />
            </svg>
          </a>

          {/* Phone 1 */}
          <a
            href={`tel:${CONTACT_PHONE}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center w-12 h-12 bg-blue-500 hover:bg-blue-400 shadow-lg rounded-full text-white transition-transform hover:scale-110"
            aria-label="Call Main"
          >
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-2.896-1.596-5.48-4.18-7.076-7.076l1.293-.97c.362-.271.527-.733.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z" />
            </svg>
          </a>
        </div>

        {/* Main Toggle Button */}
        <button
          onClick={() => setContactOpen(!contactOpen)}
          className={`flex items-center justify-center w-16 h-16 rounded-full text-white shadow-xl transition-all duration-300 ${
            contactOpen ? "bg-neutral-800 rotate-45" : "bg-black hover:bg-neutral-800"
          }`}
          aria-label="Contact Us"
        >
          {contactOpen ? (
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-6 h-6">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
          ) : (
            <svg fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-7 h-7">
              <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z" />
            </svg>
          )}
        </button>
      </div>
    </div>
  );
}