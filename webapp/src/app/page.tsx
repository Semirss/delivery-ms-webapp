"use client";

import { motion } from "framer-motion";
import {
  ArrowRight,
  Bike,
  CheckCircle,
  Clock,
  Mail,
  Map,
  MapPin,
  MessageCircle,
  Package,
  Phone,
  Send,
  ShieldCheck,
  Zap,
} from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

const PRICING_CALC = {
  Bike: { base: 30, perKm: 40 },
  Motor: { base: 40, perKm: 50 },
};

const CONTACT_PHONE = "+251931323328";
const CONTACT_PHONE2 = "+251920202304";
const CONTACT_EMAIL = "Natnaeltegestuu@gmail.com";
const CONTACT_TELEGRAM = "motorbike_et";

function PriceCalculator() {
  const [km, setKm] = useState(3);
  const [vehicle, setVehicle] = useState<"Bike" | "Motor">("Motor");
  const { base, perKm } = PRICING_CALC[vehicle];
  const price = Math.round((base + km * perKm) / 10) * 10;

  return (
    <div className="mx-auto mt-14 max-w-xl rounded-[2rem] border border-[#ffe2dc] bg-white/90 p-8 shadow-[0_24px_60px_rgba(242,106,84,0.12)] backdrop-blur-xl">
      <div className="mb-6 text-center">
        <span className="text-xs font-black uppercase tracking-[0.24em] text-[#2aa7d6]">
          Try it out
        </span>
        <h3 className="mt-2 text-2xl font-black text-[#12263d]">
          Estimate Your Delivery Cost
        </h3>
      </div>

      <div className="mb-6 flex rounded-2xl bg-[#fff3ef] p-1.5">
        {(["Bike", "Motor"] as const).map((item) => (
          <button
            key={item}
            onClick={() => setVehicle(item)}
            className={`flex-1 rounded-xl px-3 py-2.5 text-sm font-black transition-all ${
              vehicle === item
                ? "bg-white text-[#12263d] shadow-[0_10px_22px_rgba(242,106,84,0.14)]"
                : "text-[#6c7a89] hover:text-[#12263d]"
            }`}
          >
            {item === "Bike" ? "Bicycle" : "Motorbike"}
          </button>
        ))}
      </div>

      <div className="mb-6">
        <div className="mb-3 flex justify-between">
          <label className="text-sm font-black text-[#12263d]">Distance</label>
          <span className="text-sm font-black text-[#f26a54]">{km} km</span>
        </div>
        <input
          type="range"
          min={1}
          max={30}
          value={km}
          onChange={(event) => setKm(Number(event.target.value))}
          className="h-2 w-full cursor-pointer appearance-none rounded-full bg-[#ffd8cf] accent-[#f26a54]"
        />
        <div className="mt-1.5 flex justify-between text-xs font-bold text-[#9aa6b5]">
          <span>1 km</span>
          <span>30 km</span>
        </div>
      </div>

      <div className="flex items-center justify-between rounded-2xl border border-[#ffe2dc] bg-[#fff8f5] p-5">
        <div>
          <p className="mb-1 text-xs font-black uppercase tracking-[0.18em] text-[#9aa6b5]">
            Estimated Price
          </p>
          <p className="text-3xl font-black text-[#12263d]">
            {price}{" "}
            <span className="text-base font-bold text-[#6c7a89]">ETB</span>
          </p>
          <p className="mt-1 text-xs font-bold text-[#8b98a8]">
            {base} base + {km} x {perKm} ETB/km
          </p>
        </div>
        <Link href="/book">
          <button className="flex items-center gap-2 rounded-xl bg-[#f26a54] px-5 py-3 text-sm font-black text-white shadow-[0_14px_24px_rgba(242,106,84,0.26)] transition hover:bg-[#e45d48] active:scale-95">
            <span>Book Now</span>
            <ArrowRight className="h-4 w-4" />
          </button>
        </Link>
      </div>
    </div>
  );
}

function PhoneInterface() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 54, rotate: 3 }}
      animate={{ opacity: 1, y: 0, rotate: -2 }}
      transition={{ duration: 0.9, delay: 0.18, ease: "easeOut" }}
      className="relative h-[670px] w-[335px] rounded-[3.1rem] border-[10px] border-[#12263d] bg-[#12263d] shadow-[0_42px_80px_rgba(18,38,61,0.22)]"
    >
      <div className="absolute left-1/2 top-0 z-30 h-7 w-36 -translate-x-1/2 rounded-b-2xl bg-[#12263d]" />
      <div className="absolute inset-[4px] overflow-hidden rounded-[2.45rem] bg-[#fffaf7]">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_5%,rgba(242,106,84,0.16),transparent_35%),radial-gradient(circle_at_88%_22%,rgba(42,167,214,0.16),transparent_30%),linear-gradient(180deg,#fffaf7,#ffffff)]" />

        <div className="relative z-10 flex h-full flex-col px-5 pb-5 pt-12">
          <div className="mb-4 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="relative h-11 w-11 overflow-hidden rounded-2xl shadow-sm">
                <Image
                  src="/favlogo1.png"
                  alt="MotoBike Logo"
                  fill
                  className="object-cover"
                />
              </div>
              <div>
                <p className="text-lg font-black leading-none text-[#f26a54]">
                  MotoBike
                </p>
                <p className="mt-1 text-xs font-bold text-[#9aa6b5]">
                  Your delivery companion
                </p>
              </div>
            </div>
            <motion.div
              animate={{ scale: [1, 1.08, 1], rotate: [0, -4, 0] }}
              transition={{ duration: 2.4, repeat: Infinity, ease: "easeInOut" }}
              className="flex h-11 w-11 items-center justify-center rounded-2xl border border-[#e9eef4] bg-white text-[#12263d] shadow-sm"
            >
              <Package className="h-5 w-5" />
            </motion.div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            {[
              {
                label: "Bicycle",
                price: "40",
                icon: Bike,
                border: "#f26a54",
                bg: "from-[#fff4f0] to-[#ffd8cf]",
                delay: 0,
              },
              {
                label: "Motorbike",
                price: "50",
                icon: Zap,
                border: "#afe4fa",
                bg: "from-[#effaff] to-[#e0f5ff]",
                delay: 0.55,
              },
            ].map((item) => {
              const Icon = item.icon;
              return (
                <motion.div
                  key={item.label}
                  animate={{ y: [0, -8, 0], scale: [1, 1.035, 1] }}
                  transition={{
                    duration: 2.2,
                    repeat: Infinity,
                    ease: "easeInOut",
                    delay: item.delay,
                  }}
                  className={`relative h-28 overflow-hidden rounded-[1.4rem] border bg-gradient-to-br ${item.bg} p-4 shadow-[0_16px_28px_rgba(18,38,61,0.08)]`}
                  style={{ borderColor: item.border }}
                >
                  <div className="absolute -bottom-8 -right-4 h-24 w-24 rounded-full bg-white/50 blur-xl" />
                  <p className="text-sm font-black text-[#12263d]">
                    {item.label}
                  </p>
                  <p className="mt-2 text-lg font-black text-[#f26a54]">
                    {item.price}
                    <span className="ml-1 text-xs font-bold text-[#9aa6b5]">
                      /km ETB
                    </span>
                  </p>
                  <div className="absolute bottom-4 right-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-white/78 text-[#12263d] shadow-sm">
                    <Icon className="h-7 w-7" />
                  </div>
                </motion.div>
              );
            })}
          </div>

          <motion.div
            animate={{ y: [0, -6, 0] }}
            transition={{ duration: 3.2, repeat: Infinity, ease: "easeInOut" }}
            className="mt-4 overflow-hidden rounded-[1.7rem] bg-gradient-to-br from-[#ffd6ba] via-[#ffefe4] to-[#fff8f4] p-5 shadow-[0_18px_34px_rgba(242,106,84,0.14)]"
          >
            <div className="inline-flex items-center gap-2 rounded-full bg-white/85 px-3 py-2 text-xs font-black text-[#12263d]">
              <Clock className="h-3.5 w-3.5 text-[#f26a54]" />
              Fast & reliable
            </div>
            <h3 className="mt-5 text-2xl font-black text-[#12263d]">
              Food delivery
            </h3>
            <p className="mt-2 max-w-[170px] text-sm font-bold leading-snug text-[#6c7a89]">
              Your favorite meals, delivered to your door.
            </p>
          </motion.div>

          <div className="mt-4 flex items-center gap-3 rounded-[1.55rem] border border-[#e9eef4] bg-white p-4 shadow-[0_12px_28px_rgba(18,38,61,0.06)]">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#fff3ef] text-[#f26a54]">
              <MapPin className="h-5 w-5" />
            </div>
            <p className="flex-1 text-base font-black text-[#12263d]">
              Where should we deliver?
            </p>
            <ArrowRight className="h-5 w-5 text-[#12263d]" />
          </div>

          <div className="relative mt-4 flex-1 overflow-hidden rounded-[1.7rem] bg-[#182431] shadow-[0_18px_38px_rgba(18,38,61,0.16)]">
            <div className="absolute inset-0 opacity-35">
              <div className="absolute left-[-20%] top-[18%] h-2 w-[150%] rotate-[-14deg] rounded-full bg-white" />
              <div className="absolute left-[-10%] top-[45%] h-2 w-[140%] rotate-[12deg] rounded-full bg-white" />
              <div className="absolute left-[42%] top-[-10%] h-[140%] w-2 rotate-[7deg] rounded-full bg-white" />
              <div className="absolute left-[10%] top-[5%] h-[130%] w-2 rotate-[-28deg] rounded-full bg-white" />
            </div>
            <div className="absolute inset-0 bg-gradient-to-br from-[#12263d]/80 via-[#12263d]/55 to-[#f26a54]/30" />
            <svg className="absolute inset-0 h-full w-full" viewBox="0 0 240 170">
              <path
                d="M30 122 C78 62 128 142 204 72"
                fill="none"
                stroke="white"
                strokeOpacity="0.72"
                strokeWidth="12"
                strokeLinecap="round"
              />
              <path
                d="M30 122 C78 62 128 142 204 72"
                fill="none"
                stroke="#f26a54"
                strokeWidth="7"
                strokeLinecap="round"
              />
            </svg>
            <motion.div
              animate={{
                left: ["12%", "38%", "62%", "84%", "84%", "12%"],
                top: ["70%", "42%", "67%", "38%", "38%", "70%"],
              }}
              transition={{
                duration: 4.8,
                repeat: Infinity,
                ease: "easeInOut",
                times: [0, 0.26, 0.52, 0.78, 0.9, 1],
              }}
              className="absolute z-20 flex h-11 w-11 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full border-4 border-white bg-[#f26a54] text-white shadow-lg"
            >
              <Bike className="h-5 w-5" />
            </motion.div>
            <div className="absolute left-5 top-5">
              <p className="text-2xl font-black leading-tight text-white">
                Fast city <span className="text-[#ff8a76]">delivery</span>
              </p>
              <p className="mt-2 text-sm font-bold text-white/78">
                Live route preview
              </p>
            </div>
          </div>

          <div className="mt-4 grid grid-cols-5 rounded-[1.5rem] border border-[#e9eef4] bg-white p-2 shadow-[0_12px_28px_rgba(18,38,61,0.08)]">
            {[Package, Clock, Bike, MapPin, MessageCircle].map((Icon, index) => (
              <div
                key={index}
                className={`flex h-10 items-center justify-center rounded-2xl ${
                  index === 2 ? "bg-[#f26a54] text-white" : "text-[#8b98a8]"
                }`}
              >
                <Icon className="h-5 w-5" />
              </div>
            ))}
          </div>
        </div>
      </div>
    </motion.div>
  );
}

export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false);
  const [contactOpen, setContactOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const fadeIn = {
    hidden: { opacity: 0, y: 30 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.75 } },
  };

  const staggerContainer = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { staggerChildren: 0.14 } },
  };

  return (
    <div className="min-h-screen overflow-x-hidden bg-[#fff8f5] font-sans text-[#12263d] selection:bg-[#ffd8cf]">
      <div className="pointer-events-none fixed left-[-12%] top-[-18%] h-[46rem] w-[46rem] rounded-full bg-[#ffd8cf]/55 blur-[120px]" />
      <div className="pointer-events-none fixed bottom-[-14%] right-[-12%] h-[40rem] w-[40rem] rounded-full bg-[#cdefff]/70 blur-[120px]" />

      <nav
        className={`fixed top-0 z-50 w-full transition-all duration-500 ${
          scrolled
            ? "bg-[#fff8f5]/82 py-4 shadow-[0_12px_30px_rgba(18,38,61,0.05)] backdrop-blur-2xl"
            : "bg-transparent py-7"
        }`}
      >
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 md:px-10">
          <div className="flex items-center gap-3">
            <div className="relative h-10 w-10 overflow-hidden rounded-2xl shadow-sm">
              <Image
                src="/favlogo1.png"
                alt="MotoBike Logo"
                fill
                className="object-cover"
              />
            </div>
            <span className="text-2xl font-black tracking-tight text-[#12263d]">
              MotoBike
            </span>
          </div>
          <div className="hidden items-center gap-10 text-sm font-black text-[#6c7a89] md:flex">
            <a href="#about" className="transition hover:text-[#f26a54]">
              About us
            </a>
            <a href="#pricing" className="transition hover:text-[#f26a54]">
              Pricing
            </a>
            <a href="#features" className="transition hover:text-[#f26a54]">
              Features
            </a>
          </div>
          <Link href="/book">
            <button className="rounded-full bg-[#f26a54] px-6 py-3 text-sm font-black text-white shadow-[0_16px_28px_rgba(242,106,84,0.24)] transition hover:bg-[#e45d48] active:scale-95">
              Order delivery
            </button>
          </Link>
        </div>
      </nav>

      <main className="relative px-6 pb-12 pt-36 md:px-10 md:pt-44">
        <div className="mx-auto grid max-w-7xl items-center gap-14 lg:grid-cols-[1.02fr_0.98fr]">
          <motion.div
            initial="hidden"
            animate="visible"
            variants={staggerContainer}
            className="relative z-10"
          >
            <motion.div
              variants={fadeIn}
              className="mb-6 inline-flex items-center gap-3 rounded-full border border-white/80 bg-white/75 px-4 py-2 text-sm font-black text-[#12263d] shadow-sm backdrop-blur-xl"
            >
              <span className="rounded-full bg-[#fff3ef] px-2 py-1 text-xs text-[#f26a54]">
                ET
              </span>
              Fast delivery across Addis Ababa
            </motion.div>

            <motion.h1
              variants={fadeIn}
              className="mb-8 max-w-3xl text-5xl font-black leading-[1.02] tracking-tight text-[#12263d] sm:text-6xl md:text-[5.4rem]"
            >
              Fast delivery,
              <br />
              <span className="text-[#f26a54]">anywhere in Addis.</span>
            </motion.h1>

            <motion.p
              variants={fadeIn}
              className="mb-10 max-w-xl text-xl font-semibold leading-relaxed text-[#5f7082]"
            >
              Skip the long taxi queues and chaotic roads. MotoBike connects
              businesses and individuals with trusted local couriers for fast,
              secure deliveries from Piassa to Bole.
            </motion.p>

            <motion.div
              variants={fadeIn}
              className="flex w-full flex-col gap-4 sm:w-auto sm:flex-row"
            >
              <Link href="/book" className="w-full sm:w-auto">
                <button className="flex w-full items-center justify-center gap-3 rounded-full bg-[#f26a54] px-8 py-4 text-lg font-black text-white shadow-[0_18px_34px_rgba(242,106,84,0.28)] transition hover:bg-[#e45d48] active:scale-95 sm:w-auto">
                  <span>Order Now</span>
                  <ArrowRight className="h-5 w-5" />
                </button>
              </Link>
              <a
                href="#about"
                className="rounded-full border border-[#ffe2dc] bg-white/82 px-8 py-4 text-center text-lg font-black text-[#12263d] shadow-sm backdrop-blur-md transition hover:border-[#f26a54]"
              >
                Learn more
              </a>
            </motion.div>
          </motion.div>

          <div className="relative flex justify-center lg:justify-end">
            <div className="absolute right-8 top-10 h-72 w-72 rounded-full bg-[#ffd8cf]/70 blur-[70px]" />
            <div className="absolute bottom-8 left-8 h-72 w-72 rounded-full bg-[#cdefff]/80 blur-[80px]" />
            <PhoneInterface />
          </div>
        </div>
      </main>

      <section id="about" className="relative z-10 py-24">
        <div className="mx-auto grid max-w-7xl items-center gap-12 px-6 md:px-10 lg:grid-cols-2">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={fadeIn}
            className="rounded-[2.4rem] border border-[#ffe2dc] bg-white/82 p-8 shadow-[0_26px_58px_rgba(242,106,84,0.10)] backdrop-blur-xl md:p-10"
          >
            <div className="relative mb-8 h-16 w-16 overflow-hidden rounded-3xl">
              <Image
                src="/favlogo1.png"
                alt="MotoBike logo"
                fill
                className="object-cover"
              />
            </div>
            <h2 className="mb-5 text-4xl font-black leading-tight text-[#12263d]">
              Built for real movement in Addis.
            </h2>
            <p className="text-lg font-semibold leading-relaxed text-[#5f7082]">
              MotoBike is a proudly Ethiopian startup built to solve daily
              logistics with fast riders, transparent pricing, and live delivery
              updates.
            </p>
          </motion.div>

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
            className="space-y-6"
          >
            <motion.span
              variants={fadeIn}
              className="block text-sm font-black uppercase tracking-[0.24em] text-[#2aa7d6]"
            >
              About MotoBike
            </motion.span>
            <motion.h2
              variants={fadeIn}
              className="text-4xl font-black leading-tight text-[#12263d] md:text-5xl"
            >
              Connecting the city, one drop-off at a time.
            </motion.h2>
            <motion.p
              variants={fadeIn}
              className="text-lg font-semibold leading-relaxed text-[#5f7082]"
            >
              We connect customers with trusted bicycle and motorbike couriers
              who know the city. No hidden fees, no unreliable timing, just
              fast delivery you can trust.
            </motion.p>
          </motion.div>
        </div>
      </section>

      <section
        id="pricing"
        className="relative z-10 border-y border-[#ffe2dc] bg-white/62 py-24"
      >
        <div className="mx-auto max-w-7xl px-6 md:px-10">
          <div className="mx-auto mb-16 max-w-2xl text-center">
            <span className="text-sm font-black uppercase tracking-[0.24em] text-[#f26a54]">
              Transparent Pricing
            </span>
            <h2 className="mt-3 text-4xl font-black text-[#12263d] md:text-5xl">
              Simple, fair rates for Addis.
            </h2>
            <p className="mt-4 text-lg font-semibold text-[#5f7082]">
              Pay by distance. No surges, no haggling. Starting at 30 ETB plus
              distance rate.
            </p>
          </div>

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
            className="mx-auto grid max-w-4xl gap-8 md:grid-cols-2"
          >
            {[
              {
                title: "Bicycle Courier",
                desc: "Best for light items, documents, and local traffic.",
                base: "30",
                perKm: "+40",
                accent: "#f26a54",
                panel: "bg-[#fff8f5]",
                icon: Bike,
              },
              {
                title: "Motorbike Courier",
                desc: "Fastest option for cross-city delivery and heavier items.",
                base: "40",
                perKm: "+50",
                accent: "#2aa7d6",
                panel: "bg-[#effaff]",
                icon: Zap,
              },
            ].map((plan) => {
              const Icon = plan.icon;
              return (
                <motion.div
                  key={plan.title}
                  variants={fadeIn}
                  className={`relative overflow-hidden rounded-[2.2rem] border border-white p-9 shadow-[0_24px_54px_rgba(18,38,61,0.08)] ${plan.panel}`}
                >
                  <div
                    className="absolute right-[-60px] top-[-60px] h-44 w-44 rounded-full blur-3xl"
                    style={{ backgroundColor: `${plan.accent}30` }}
                  />
                  <div className="relative z-10">
                    <div
                      className="mb-6 flex h-14 w-14 items-center justify-center rounded-2xl text-white shadow-lg"
                      style={{ backgroundColor: plan.accent }}
                    >
                      <Icon className="h-7 w-7" />
                    </div>
                    <h3 className="text-2xl font-black text-[#12263d]">
                      {plan.title}
                    </h3>
                    <p className="mt-2 font-semibold text-[#5f7082]">
                      {plan.desc}
                    </p>
                    <div className="mt-8">
                      <span className="text-5xl font-black text-[#12263d]">
                        {plan.base}
                      </span>
                      <span className="ml-2 font-bold text-[#6c7a89]">
                        ETB base fare
                      </span>
                    </div>
                    <p
                      className="mt-2 text-2xl font-black"
                      style={{ color: plan.accent }}
                    >
                      {plan.perKm}{" "}
                      <span className="text-sm font-bold text-[#6c7a89]">
                        ETB / km
                      </span>
                    </p>
                    <ul className="mt-8 space-y-4 text-sm font-bold text-[#5f7082]">
                      <li className="flex items-center gap-3">
                        <CheckCircle className="h-5 w-5 text-[#2dba87]" />
                        Transparent distance pricing
                      </li>
                      <li className="flex items-center gap-3">
                        <CheckCircle className="h-5 w-5 text-[#2dba87]" />
                        Live delivery updates
                      </li>
                      <li className="flex items-center gap-3">
                        <CheckCircle className="h-5 w-5 text-[#2dba87]" />
                        Vetted local couriers
                      </li>
                    </ul>
                    <Link href="/book">
                      <button
                        className="mt-8 w-full rounded-2xl py-4 font-black text-white shadow-lg transition active:scale-95"
                        style={{ backgroundColor: plan.accent }}
                      >
                        Book {plan.title.split(" ")[0]}
                      </button>
                    </Link>
                  </div>
                </motion.div>
              );
            })}
          </motion.div>

          <PriceCalculator />
        </div>
      </section>

      <section id="features" className="relative z-10 py-24">
        <div className="mx-auto max-w-7xl px-6 md:px-10">
          <div className="mb-16 text-center">
            <span className="text-sm font-black uppercase tracking-[0.24em] text-[#2aa7d6]">
              Why MotoBike
            </span>
            <h2 className="mt-3 text-4xl font-black text-[#12263d] md:text-5xl">
              Built for the local hustle.
            </h2>
          </div>

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
            className="grid gap-6 lg:grid-cols-3"
          >
            {[
              {
                title: "Local Traffic Experts",
                desc: "Riders use familiar routes and shortcuts across Addis.",
                icon: Map,
                color: "#f26a54",
              },
              {
                title: "Reliable Verification",
                desc: "Drivers are reviewed and verified before joining.",
                icon: ShieldCheck,
                color: "#2aa7d6",
              },
              {
                title: "Live SMS Updates",
                desc: "Customers get delivery progress updates by phone.",
                icon: Zap,
                color: "#2dba87",
              },
            ].map((card) => {
              const Icon = card.icon;
              return (
                <motion.div
                  key={card.title}
                  variants={fadeIn}
                  className="rounded-[2rem] border border-[#ffe2dc] bg-white/84 p-8 shadow-[0_20px_44px_rgba(18,38,61,0.06)] backdrop-blur-xl"
                >
                  <div
                    className="mb-8 flex h-14 w-14 items-center justify-center rounded-2xl text-white"
                    style={{ backgroundColor: card.color }}
                  >
                    <Icon className="h-6 w-6" />
                  </div>
                  <h3 className="text-2xl font-black text-[#12263d]">
                    {card.title}
                  </h3>
                  <p className="mt-3 font-semibold leading-relaxed text-[#5f7082]">
                    {card.desc}
                  </p>
                </motion.div>
              );
            })}
          </motion.div>

          <div className="mt-20 text-center">
            <div className="inline-flex items-center gap-4 rounded-full border border-[#ffe2dc] bg-white/86 p-2 pr-6 shadow-sm backdrop-blur-md">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-[#fff3ef] text-[#f26a54]">
                <Phone className="h-5 w-5" />
              </div>
              <div className="text-left leading-tight">
                <p className="font-black text-[#12263d]">
                  Need corporate delivery?
                </p>
                <p className="text-sm font-semibold text-[#5f7082]">
                  Call{" "}
                  <a href="tel:+251931323328" className="font-black text-[#f26a54]">
                    +251 93 132 3328
                  </a>
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <footer className="relative z-10 border-t border-[#ffe2dc] bg-[#fff8f5] py-10">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-6 px-6 md:flex-row md:px-10">
          <div className="flex flex-col items-center gap-4 md:flex-row">
            <div className="relative h-10 w-10 overflow-hidden rounded-xl opacity-80 shadow-sm">
              <Image
                src="/favlogo1.png"
                alt="MotoBike Logo"
                fill
                className="object-cover"
              />
            </div>
            <span className="text-center text-sm font-bold text-[#6c7a89] md:text-left">
              © {new Date().getFullYear()} MotoBike Logistics P.L.C. &{" "}
              <a className="text-[#f26a54]" href="https://semir-sultan.vercel.app">
                Semir Production
              </a>
              <br />
              Addis Ababa, Ethiopia
            </span>
          </div>
          <div className="flex gap-6 text-sm font-black text-[#6c7a89]">
            <a href="#about" className="hover:text-[#f26a54]">
              About Us
            </a>
            <a href="#pricing" className="hover:text-[#f26a54]">
              Pricing
            </a>
            <a href="#features" className="hover:text-[#f26a54]">
              Features
            </a>
          </div>
        </div>
      </footer>

      <div className="fixed bottom-6 right-6 z-50 flex flex-col items-end">
        <div
          className={`mb-4 flex origin-bottom flex-col gap-3 transition-all duration-300 ${
            contactOpen
              ? "translate-y-0 scale-100 opacity-100"
              : "pointer-events-none translate-y-10 scale-75 opacity-0"
          }`}
        >
          <button
            onClick={() => {
              const url = `https://t.me/${CONTACT_TELEGRAM}`;
              const tg = (window as any).Telegram?.WebApp;
              if (tg?.openTelegramLink) {
                tg.openTelegramLink(url);
              } else {
                window.open(url, "_blank");
              }
            }}
            className="flex h-12 w-12 items-center justify-center rounded-full bg-[#229ed9] text-white shadow-lg transition hover:scale-110"
            aria-label="Telegram"
          >
            <Send className="h-5 w-5" />
          </button>
          <a
            href={`mailto:${CONTACT_EMAIL}`}
            className="flex h-12 w-12 items-center justify-center rounded-full bg-[#2aa7d6] text-white shadow-lg transition hover:scale-110"
            aria-label="Email"
          >
            <Mail className="h-5 w-5" />
          </a>
          <a
            href={`tel:${CONTACT_PHONE2}`}
            className="flex h-12 w-12 items-center justify-center rounded-full bg-[#2dba87] text-white shadow-lg transition hover:scale-110"
            aria-label="Call alternative"
          >
            <Phone className="h-5 w-5" />
          </a>
          <a
            href={`tel:${CONTACT_PHONE}`}
            className="flex h-12 w-12 items-center justify-center rounded-full bg-[#f26a54] text-white shadow-lg transition hover:scale-110"
            aria-label="Call main"
          >
            <Phone className="h-5 w-5" />
          </a>
        </div>

        <button
          onClick={() => setContactOpen(!contactOpen)}
          className={`flex h-16 w-16 items-center justify-center rounded-full text-white shadow-[0_18px_34px_rgba(242,106,84,0.28)] transition-all duration-300 ${
            contactOpen ? "rotate-45 bg-[#12263d]" : "bg-[#f26a54] hover:bg-[#e45d48]"
          }`}
          aria-label="Contact us"
        >
          {contactOpen ? (
            <ArrowRight className="h-6 w-6" />
          ) : (
            <MessageCircle className="h-7 w-7" />
          )}
        </button>
      </div>
    </div>
  );
}
