"use client";

import { useEffect } from "react";
import { motion } from "framer-motion";
import Link from "next/link";
import CloudinaryImage from "@/components/CloudinaryImage";
import { IMAGES } from "@/lib/cloudinary-images";
import { trackMetric } from "@/lib/utils";

/**
 * [ID]
 * Download Page — halaman unduhan APK Glicoo
 *
 * [EN]
 * Download Page — Glicoo APK download page
 */

import { useIsMobile, getMotionProps } from "@/lib/hooks";

const APP_VERSION = "1.0.1";
const APP_SIZE = "63 MB";
const LAST_UPDATED = "30 Juni 2026";

// URL Download APK — bisa diset via Environment Variable (NEXT_PUBLIC_APK_DOWNLOAD_URL)
// atau langsung ganti string di bawah ini.
const APK_DOWNLOAD_URL =
  process.env.NEXT_PUBLIC_APK_DOWNLOAD_URL ||
  "https://github.com/IniRalfi/glicoo-app/releases/download/v1.0.1/Glicoo.apk";

const steps = [
  {
    number: "01",
    title: "Unduh file APK",
    desc: "Klik tombol unduh di bawah untuk mendapatkan file APK Glicoo.",
  },
  {
    number: "02",
    title: "Izinkan instalasi",
    desc: 'Buka Pengaturan → Keamanan → aktifkan "Sumber Tidak Dikenal".',
  },
  {
    number: "03",
    title: "Instal & mulai",
    desc: "Buka file APK yang diunduh, instal, lalu daftarkan akunmu.",
  },
];

const changelog = [
  "Peluncuran perdana Glicoo Beta",
  "Integrasi Iloo AI companion dengan Gemini",
  "Sistem misi harian & tracking kebiasaan",
  "Monitoring aktivitas via sensor ponsel",
  "Pencatatan makanan & estimasi kalori AI",
];

export default function DownloadPage() {
  const isMobile = useIsMobile();

  useEffect(() => {
    trackMetric("page_views");
  }, []);

  return (
    <main className="min-h-screen bg-background overflow-x-hidden">
      {/* ─── HERO ─── */}
      <section className="relative w-full pt-20 pb-16">
        {/* Background glow */}
        <div
          className="pointer-events-none absolute -top-32 left-1/2 -translate-x-1/2 w-[700px] h-[500px] rounded-full blur-3xl opacity-15"
          style={{
            background: "radial-gradient(ellipse, #ffb700 0%, #ff7b00 60%, transparent 100%)",
          }}
        />

        <div className="w-[90%] md:w-[80%] mx-auto px-4">
          {/* Top: Badge */}
          <motion.div
            {...getMotionProps(isMobile, {
              initial: { opacity: 0, y: 20 },
              animate: { opacity: 1, y: 0 },
              transition: { duration: 0.6, ease: "easeOut" },
            })}
            className="mb-8"
          >
            <span className="text-primary font-bold text-sm uppercase tracking-wider">
              Beta Tersedia Sekarang
            </span>
          </motion.div>

          {/* Two-column grid: Text | Image */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-10 items-center">
            {/* LEFT: Text */}
            <div className="flex flex-col gap-5">
              <motion.h1
                {...getMotionProps(isMobile, {
                  initial: { opacity: 0, y: 24 },
                  animate: { opacity: 1, y: 0 },
                  transition: { duration: 0.7, delay: 0.1, ease: "easeOut" },
                })}
                className="font-display text-5xl md:text-6xl text-foreground leading-tight"
              >
                Unduh <span className="text-primary">Glicoo</span>
              </motion.h1>

              <motion.p
                {...getMotionProps(isMobile, {
                  initial: { opacity: 0, y: 20 },
                  animate: { opacity: 1, y: 0 },
                  transition: { duration: 0.7, delay: 0.2, ease: "easeOut" },
                })}
                className="text-muted-foreground text-base md:text-lg leading-relaxed"
              >
                Mulai perjalanan hidup sehat bersama Iloo, AI companion yang memahami kebiasaanmu
                setiap hari.
              </motion.p>

              {/* Meta chips */}
              <motion.div
                {...getMotionProps(isMobile, {
                  initial: { opacity: 0, y: 16 },
                  animate: { opacity: 1, y: 0 },
                  transition: { duration: 0.6, delay: 0.3, ease: "easeOut" },
                })}
                className="flex flex-wrap gap-3"
              >
                {[
                  { icon: "🔖", label: `v${APP_VERSION}` },
                  { icon: "📦", label: APP_SIZE },
                  { icon: "📱", label: "Android 10+" },
                ].map(({ icon, label }) => (
                  <span
                    key={label}
                    className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium bg-[#f5f5f5] text-foreground"
                  >
                    {icon} {label}
                  </span>
                ))}
              </motion.div>

              {/* Buttons */}
              <motion.div
                {...getMotionProps(isMobile, {
                  initial: { opacity: 0, y: 16 },
                  animate: { opacity: 1, y: 0 },
                  transition: { duration: 0.6, delay: 0.4, ease: "easeOut" },
                })}
                className="flex flex-col sm:flex-row gap-3 pt-1"
              >
                <motion.a
                  href={APK_DOWNLOAD_URL}
                  download
                  onClick={() => {
                    trackMetric("apk_downloads");
                  }}
                  className="inline-flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-2xl text-white font-bold text-sm md:text-base"
                  style={{ backgroundColor: "#1a1a1a", fontFamily: "'Rammetto One', serif" }}
                  {...getMotionProps(isMobile, {
                    whileHover: { scale: 1.03 },
                    whileTap: { scale: 0.97 },
                  })}
                >
                  <svg
                    width="18"
                    height="18"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="white"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                    <polyline points="7 10 12 15 17 10" />
                    <line x1="12" y1="15" x2="12" y2="3" />
                  </svg>
                  Unduh APK
                </motion.a>

                <motion.div
                  {...getMotionProps(isMobile, {
                    whileHover: { scale: 1.02 },
                    whileTap: { scale: 0.97 },
                  })}
                >
                  <Link
                    href="/"
                    className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-2xl text-sm md:text-base font-semibold border-2 border-border text-foreground hover:border-primary hover:text-primary transition-colors"
                  >
                    ← Beranda
                  </Link>
                </motion.div>
              </motion.div>

              <motion.p
                {...getMotionProps(isMobile, {
                  initial: { opacity: 0 },
                  animate: { opacity: 1 },
                  transition: { duration: 0.5, delay: 0.55 },
                })}
                className="text-xs text-muted-foreground"
              >
                Diperbarui: {LAST_UPDATED} · Gratis selamanya
              </motion.p>
            </div>

            {/* RIGHT: Mascot */}
            <motion.div
              {...getMotionProps(isMobile, {
                initial: { opacity: 0, y: 30, scale: 0.92 },
                animate: { opacity: 1, y: 0, scale: 1 },
                transition: { duration: 0.9, delay: 0.25, ease: "easeOut" },
              })}
              className="flex justify-center md:justify-end"
            >
              <CloudinaryImage
                src={IMAGES.ilooLogo.url}
                alt="Iloo AI Mascot"
                width={400}
                height={400}
                quality={95}
                className="w-[220px] md:w-[300px] h-auto"
                objectFit="contain"
              />
            </motion.div>
          </div>
        </div>
      </section>

      {/* ─── CARA INSTALASI ─── */}
      <section className="w-full py-16 bg-background">
        <div className="w-[90%] md:w-[80%] mx-auto px-4">
          <motion.div
            {...getMotionProps(isMobile, {
              initial: { opacity: 0, y: 24 },
              whileInView: { opacity: 1, y: 0 },
              viewport: { once: true },
              transition: { duration: 0.6, ease: "easeOut" },
            })}
            className="mb-10"
          >
            <h2 className="font-display text-2xl md:text-3xl text-foreground">Cara Instalasi</h2>
            <p className="text-muted-foreground mt-2 text-sm md:text-base">
              3 langkah mudah untuk mulai menggunakan Glicoo
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {steps.map((step, i) => (
              <motion.div
                key={step.number}
                {...getMotionProps(isMobile, {
                  initial: { opacity: 0, y: 28 },
                  whileInView: { opacity: 1, y: 0 },
                  viewport: { once: true },
                  transition: { duration: 0.6, delay: i * 0.1, ease: "easeOut" },
                })}
                className="p-6 rounded-2xl border border-border bg-white hover:border-primary transition-colors group cursor-default"
              >
                <span
                  className="font-display text-6xl font-bold block mb-4"
                  style={{ color: "#eeeeee" }}
                >
                  {step.number}
                </span>
                <h3 className="font-semibold text-foreground text-base mb-2 group-hover:text-primary transition-colors">
                  {step.title}
                </h3>
                <p className="text-muted-foreground text-sm leading-relaxed">{step.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── CHANGELOG ─── */}
      <section className="w-full py-16 bg-[#FAFAFA]">
        <div className="w-[90%] md:w-[80%] mx-auto px-4">
          <motion.div
            {...getMotionProps(isMobile, {
              initial: { opacity: 0, y: 24 },
              whileInView: { opacity: 1, y: 0 },
              viewport: { once: true },
              transition: { duration: 0.6, ease: "easeOut" },
            })}
            className="mb-10"
          >
            <h2 className="font-display text-2xl md:text-3xl text-foreground">Apa yang Baru</h2>
            <p className="text-muted-foreground mt-2 text-sm md:text-base">
              Riwayat pembaruan aplikasi
            </p>
          </motion.div>

          <motion.div
            {...getMotionProps(isMobile, {
              initial: { opacity: 0, y: 24 },
              whileInView: { opacity: 1, y: 0 },
              viewport: { once: true },
              transition: { duration: 0.6, ease: "easeOut" },
            })}
            className="p-6 md:p-8 rounded-2xl bg-white border border-border"
          >
            {/* Header */}
            <div className="flex flex-wrap items-center gap-3 mb-6">
              <span className="font-display text-lg text-foreground">v{APP_VERSION}</span>
              <span
                className="text-xs font-bold px-2.5 py-1 rounded-full"
                style={{ backgroundColor: "#dcfce7", color: "#16a34a" }}
              >
                Terbaru
              </span>
              <span className="text-sm text-muted-foreground md:ml-auto">{LAST_UPDATED}</span>
            </div>

            {/* Items */}
            <ul className="flex flex-col gap-3">
              {changelog.map((item) => (
                <li key={item} className="flex items-start gap-3">
                  <span
                    className="flex-shrink-0 mt-0.5 w-5 h-5 rounded-full flex items-center justify-center text-xs font-bold"
                    style={{ backgroundColor: "#fff5e6", color: "#ff7b00" }}
                  >
                    ✓
                  </span>
                  <span className="text-sm md:text-base text-foreground leading-relaxed">
                    {item}
                  </span>
                </li>
              ))}
            </ul>
          </motion.div>
        </div>
      </section>

      {/* ─── BOTTOM CTA ─── */}
      <section className="w-full py-16 bg-background">
        <div className="w-[90%] md:w-[80%] mx-auto px-4">
          <motion.div
            {...getMotionProps(isMobile, {
              initial: { opacity: 0, y: 32, scale: 0.97 },
              whileInView: { opacity: 1, y: 0, scale: 1 },
              viewport: { once: true },
              transition: { duration: 0.8, ease: "easeOut" },
            })}
            className="rounded-3xl p-10 md:p-14 text-center flex flex-col items-center gap-5"
            style={{ background: "linear-gradient(135deg, #ff7b00 0%, #ffb700 100%)" }}
          >
            <h2 className="font-display text-white text-2xl md:text-3xl lg:text-4xl leading-tight max-w-[500px]">
              Siap Mulai Hidup Lebih Sehat?
            </h2>
            <p className="text-white/90 text-sm md:text-base max-w-[450px]">
              Download sekarang dan biarkan Iloo mendampingimu setiap hari.
            </p>
            <motion.a
              href={APK_DOWNLOAD_URL}
              download
              onClick={() => {
                trackMetric("apk_downloads");
              }}
              className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl font-bold text-sm md:text-base"
              style={{
                backgroundColor: "#fff",
                color: "#1a1a1a",
                fontFamily: "'Rammetto One', serif",
              }}
              {...getMotionProps(isMobile, {
                whileHover: { scale: 1.05 },
                whileTap: { scale: 0.97 },
              })}
            >
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="7 10 12 15 17 10" />
                <line x1="12" y1="15" x2="12" y2="3" />
              </svg>
              Unduh Sekarang · Gratis
            </motion.a>
          </motion.div>
        </div>
      </section>
    </main>
  );
}
