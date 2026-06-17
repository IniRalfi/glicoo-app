import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
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
  title: "Glico — Coming Soon",
  description:
    "Cegah Diabetes Sejak Dini dengan AI yang Ada di Saku Anda. Glico adalah aplikasi mobile berbasis Agentic AI untuk deteksi dini Diabetes Melitus Tipe 2.",
  openGraph: {
    title: "Glico — Coming Soon",
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
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <body className="min-h-full flex flex-col bg-white text-neutral-800">{children}</body>
    </html>
  );
}
