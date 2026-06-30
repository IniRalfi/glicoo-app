import type { Metadata } from "next";

/**
 * [ID]
 * Layout khusus untuk halaman download guna mendukung SEO metadata dinamis (Server Component).
 *
 * [EN]
 * Specific layout for the download page to support dynamic SEO metadata (Server Component).
 */
export const metadata: Metadata = {
  title: "Unduh Glicoo APK — Cegah Diabetes Sejak Dini",
  description:
    "Unduh aplikasi Glicoo APK terbaru (v1.0.1) untuk Android 10+. Cegah Diabetes Sejak Dini dengan bantuan asisten kesehatan AI companion Iloo di saku Anda.",
  keywords: ["unduh glicoo", "download apk glicoo", "glicoo android", "ai kesehatan", "diabetes melitus"],
  openGraph: {
    title: "Unduh Glicoo APK — Cegah Diabetes Sejak Dini",
    description: "Unduh aplikasi Glicoo APK terbaru (v1.0.1) untuk Android 10+.",
    type: "website",
    url: "https://glicoo.app/download", // fallback / standard URL
  },
  twitter: {
    card: "summary_large_image",
    title: "Unduh Glicoo APK — Cegah Diabetes Sejak Dini",
    description: "Unduh aplikasi Glicoo APK terbaru (v1.0.1) untuk Android 10+.",
  },
};

export default function DownloadLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
