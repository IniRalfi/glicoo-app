"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import CloudinaryImage from "@/components/CloudinaryImage";
import { IMAGES } from "@/lib/cloudinary-images";

/**
 * [ID]
 * Hero Section - Section pembuka landing page Glicoo
 * Layout: Tulisan di atas (center) + Gambar full-width di bawah
 *
 * [EN]
 * Hero Section - Glicoo landing page opener
 * Layout: Text on top (centered) + Full-width image below
 */
export default function HeroSection() {
  return (
    <section className="full-bleed relative w-full min-h-screen flex flex-col items-center justify-center overflow-hidden bg-background pt-12 pb-8">
      {/* Text Content - Center Top */}
      <motion.div
        initial={{ opacity: 0, y: 40 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }}
        className="text-center space-y-4 mb-10 max-w-3xl px-6 md:px-16 global-width-container"
      >
        <motion.h1
          className="font-display text-3xl md:text-4xl lg:text-5xl leading-tight"
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
        >
          <span className="text-foreground">Kebiasaan Sehat</span>
          <br />
          <motion.span
            className="text-primary"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.6, delay: 0.3, ease: "easeOut" }}
          >
            Hidup Hebat
          </motion.span>
        </motion.h1>

        <motion.p
          className="text-muted-foreground text-sm md:text-base lg:text-lg"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.4, ease: "easeOut" }}
        >
          Agentic AI untuk Pencegahan Diabetes Melitus Tipe 2
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 16, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.6, delay: 0.55, ease: "easeOut" }}
          whileHover={{ scale: 1.04 }}
          whileTap={{ scale: 0.97 }}
        >
          <Link
            href="/download"
            className="inline-flex items-center gap-2 px-6 py-3 bg-foreground text-surface font-semibold rounded-full hover:opacity-90 transition-opacity text-sm md:text-base"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M9 19l3 3m0 0l3-3m-3 3V10"
              />
            </svg>
            Unduh Aplikasi
          </Link>
        </motion.div>
      </motion.div>

      {/* Hero Image - Full Width Below */}
      <motion.div
        initial={{ opacity: 0, y: 50, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 1.1, delay: 0.35, ease: [0.16, 1, 0.3, 1] }}
        className="w-full"
      >
        <CloudinaryImage
          src={IMAGES.hero.main.url}
          alt="Glicoo App Preview"
          width={1920}
          height={969}
          priority
          className="w-full h-auto"
          objectFit="cover"
        />
      </motion.div>
    </section>
  );
}
