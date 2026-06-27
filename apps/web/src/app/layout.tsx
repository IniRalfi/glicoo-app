import type { Metadata } from "next";
import { Inter, Rammetto_One } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const rammettoOne = Rammetto_One({
  variable: "--font-rammetto-one",
  weight: "400",
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
      className={`${inter.variable} ${rammettoOne.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <body className="min-h-full flex flex-col bg-background font-body text-foreground">
        {children}
      </body>
    </html>
  );
}
