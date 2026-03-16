import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: "MotoBike - Fast & Reliable Delivery Service in Ethiopia",
    template: "%s | MotoBike"
  },
  description: "MotoBike is Ethiopia's premier courier and delivery service. Book a bike or motorbike for fast, secure, and affordable package delivery anywhere in the city.",
  keywords: ["delivery", "courier", "ethiopia", "addis ababa", "motorbike delivery", "package delivery", "fast delivery", "motobike"],
  authors: [{ name: "MotoBike" }],
  creator: "MotoBike",
  publisher: "MotoBike",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    title: "MotoBike - Fast & Reliable Delivery Service in Ethiopia",
    description: "Book a bike or motorbike for fast, secure, and affordable package delivery.",
    url: "https://motobike-delivery.com",
    siteName: "MotoBike",
    images: [
      {
        url: "/favlogo1.png",
        width: 800,
        height: 600,
        alt: "MotoBike Logo",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "MotoBike - Fast & Reliable Delivery Service",
    description: "Book a bike or motorbike for fast, secure, and affordable package delivery.",
    images: ["/favlogo1.png"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  icons: {
    icon: "/favlogo1.png",
    shortcut: "/favlogo1.png",
    apple: "/favlogo1.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-gray-50 text-gray-900`}
      >
        {children}
        <Analytics />
      </body>
    </html>
  );
}
