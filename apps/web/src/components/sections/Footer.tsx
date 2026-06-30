"use client";

import { motion } from "framer-motion";
import CloudinaryImage from "@/components/CloudinaryImage";
import { IMAGES } from "@/lib/cloudinary-images";

/**
 * [ID]
 * Footer - bg gradient brand, logo kiri, kontak kanan, copyright di bawah logo,
 * star icon 3x besar nempel di paling bawah footer (absolute terhadap footer)
 *
 * [EN]
 * Footer - brand gradient bg, logo left, contacts right, copyright below logo,
 * 3x large star icon pinned at the very bottom of footer (absolute to footer)
 */

/* Ukuran star dari IMAGES atau default 80px */
/* Resolusi yang diminta ke CDN — harus >= ukuran render CSS terbesar */
const STAR_W = (IMAGES.footer.star.width ?? 80) * 10;
const STAR_H = (IMAGES.footer.star.height ?? 80) * 10;

export default function Footer() {
  return (
    /**
     * overflow-visible agar bintang yang nempel di bawah tidak terpotong.
     * padding-bottom diberi ruang cukup agar bintang tidak nabrak konten atas.
     */
    <footer
      className="full-bleed relative w-full overflow-visible"
      style={{ paddingBottom: `${STAR_H / 2 + 124}px`, minHeight: "720px" }}
    >
      {/* Background Gradient — hanya di area footer, bukan area luberan bintang */}
      <div
        className="absolute inset-0"
        style={{ background: "linear-gradient(180deg, #FF7B00 0%, #FFEA00 100%)" }}
      />

      {/* Content */}
      <div className="relative z-10 global-width-container px-6 md:px-16 pt-10 pb-6">
        <div className="max-w-7xl mx-auto">
          {/* Top row: Logo LEFT + Contacts RIGHT */}
          <div className="flex flex-col md:flex-row justify-between gap-10">
            {/* ─── LEFT: Logo + Team Info + Copyright ─── */}
            <motion.div
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
              className="flex flex-col gap-1"
            >
              <CloudinaryImage
                src={IMAGES.footer.glicooLogo.url}
                alt="Glicoo Logo"
                width={80}
                height={22}
                quality={95}
                className="w-[120px] h-auto mb-3"
                objectFit="contain"
              />

              <p className="text-white text-base md:text-lg font-medium">
                Dikembangkan oleh Tim Pemanasan
              </p>
              <p className="text-white text-base md:text-lg font-medium">Universitas Tanjungpura</p>
              <p className="text-white/90 mt-5 text-sm md:text-base font-normal">
                © 2026 Glicoo. Dibuat untuk National IT Competition.
              </p>
            </motion.div>

            {/* ─── RIGHT: Kontak Tim ─── */}
            <motion.div
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8, delay: 0.15, ease: [0.16, 1, 0.3, 1] }}
              className="flex flex-col items-start md:items-end gap-1"
            >
              <h3 className="text-white mb-2 text-xl md:text-2xl font-bold">Kontak Tim</h3>

              {[
                { href: "https://instagram.com/iniralfi", label: "@iniralfi" },
                { href: "https://instagram.com/erse.en", label: "@erse.en" },
                { href: "https://instagram.com/thimawtee", label: "@thimawtee" },
              ].map(({ href, label }) => (
                <motion.a
                  key={label}
                  href={href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-white text-base md:text-lg font-medium"
                  whileHover={{ opacity: 0.75, x: -4 }}
                  transition={{ duration: 0.2 }}
                >
                  {label}
                </motion.a>
              ))}
            </motion.div>
          </div>
        </div>
      </div>

      {/* ─── BOTTOM CENTER: Star Icon — absolute terhadap footer, nempel di dasar ─── */}
      <motion.div
        className="absolute left-1/2 -translate-x-1/2 z-20"
        style={{ bottom: 0 }}
        initial={{ opacity: 0, scale: 0.6, y: 50 }}
        whileInView={{ opacity: 1, scale: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 1.2, delay: 0.4, ease: [0.16, 1, 0.3, 1] }}
      >
        <CloudinaryImage
          src={IMAGES.footer.star.url}
          alt={IMAGES.footer.star.description}
          width={STAR_W}
          height={STAR_H}
          quality={95}
          className="w-[400px] md:w-[800px] lg:w-[1200px] h-auto"
          objectFit="contain"
        />
      </motion.div>
    </footer>
  );
}
