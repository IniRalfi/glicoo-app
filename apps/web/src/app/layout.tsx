import type { Metadata } from "next";
import { Inter, Rammetto_One } from "next/font/google";
import "./globals.css";
import SmoothScrollProvider from "@/components/SmoothScrollProvider";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap", // Font loading optimization
});

const rammettoOne = Rammetto_One({
  variable: "--font-rammetto-one",
  weight: "400",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Glicoo — Cegah Diabetes Sejak Dini",
  description:
    "Cegah Diabetes Sejak Dini dengan AI yang Ada di Saku Anda. Glicoo adalah aplikasi mobile berbasis Agentic AI untuk deteksi dini Diabetes Melitus Tipe 2.",
  keywords: ["diabetes", "kesehatan", "AI", "mobile app", "pencegahan diabetes", "glicoo"],
  authors: [{ name: "Glicoo Team" }],
  manifest: "/manifest.json",
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/icon.svg", type: "image/svg+xml" },
      { url: "/icon.png", type: "image/png" },
    ],
    apple: "/apple-icon.png",
  },
  openGraph: {
    title: "Glicoo — Cegah Diabetes Sejak Dini",
    description: "Cegah Diabetes Sejak Dini dengan AI yang Ada di Saku Anda.",
    type: "website",
    locale: "id_ID",
  },
  twitter: {
    card: "summary_large_image",
    title: "Glicoo — Cegah Diabetes Sejak Dini",
    description: "Cegah Diabetes Sejak Dini dengan AI yang Ada di Saku Anda.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="id"
      className={`${inter.variable} ${rammettoOne.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <head>
        {/* DNS Prefetch & Preconnect untuk faster loading */}
        <link rel="dns-prefetch" href="https://res.cloudinary.com" />
        <link rel="preconnect" href="https://res.cloudinary.com" crossOrigin="anonymous" />
        <link rel="dns-prefetch" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      </head>
      <body className="min-h-full flex flex-col bg-background font-body text-foreground overflow-x-hidden" suppressHydrationWarning>
        {/* Lenis smooth scroll — aktif untuk pengalaman scroll buttery smooth */}
        <SmoothScrollProvider>
          {children}
        </SmoothScrollProvider>
      </body>
    </html>
  );
}
