"use client";

import { motion } from "framer-motion";
import CloudinaryImage from "@/components/CloudinaryImage";
import { IMAGES } from "@/lib/cloudinary-images";

import { useIsMobile, getMotionProps } from "@/lib/hooks";

export default function CTASection() {
  const isMobile = useIsMobile();

  return (
    <section className="full-bleed bg-[#F2F2F7] py-16 md:py-24">
      <div className="global-width-container px-6 md:px-16">
        <div className="max-w-7xl mx-auto">
          {/* Card tanpa border/stroke */}
          <div className="relative overflow-hidden rounded-3xl bg-[#F2F2F7]">
            <div className="flex flex-col md:flex-row items-center justify-between p-8 md:p-14 gap-8">
              {/* LEFT: Text */}
              <motion.div
                className="w-full md:w-[55%] flex flex-col gap-5"
                {...getMotionProps(isMobile, {
                  initial: { opacity: 0, x: -36 },
                  whileInView: { opacity: 1, x: 0 },
                  viewport: { once: true, amount: 0.3 },
                  transition: { duration: 0.9, ease: [0.16, 1, 0.3, 1] },
                })}
              >
                <motion.h2
                  className="font-display text-foreground leading-tight text-2xl md:text-3xl lg:text-4xl"
                  {...getMotionProps(isMobile, {
                    initial: { opacity: 0, y: 20 },
                    whileInView: { opacity: 1, y: 0 },
                    viewport: { once: true },
                    transition: { duration: 0.7, delay: 0.1 },
                  })}
                >
                  Kesehatan Dimulai dari Kebiasaan Kecil
                </motion.h2>

                <motion.p
                  className="text-foreground font-bold leading-snug text-sm md:text-base"
                  {...getMotionProps(isMobile, {
                    initial: { opacity: 0, y: 16 },
                    whileInView: { opacity: 1, y: 0 },
                    viewport: { once: true },
                    transition: { duration: 0.7, delay: 0.2 },
                  })}
                >
                  Mencegah Diabetes Melitus Tipe 2 tidak harus dimulai dengan perubahan besar.
                  Bangun kebiasaan sehat sedikit demi sedikit, dan biarkan Iloo mendampingimu setiap hari.
                </motion.p>

                <motion.a
                  href="/download"
                  className="inline-flex items-center gap-2 rounded-full text-white w-fit px-5 py-2.5 text-sm md:text-base hover:opacity-90 transition-opacity"
                  style={{ backgroundColor: "#000000", borderRadius: "100px", fontFamily: "'Rammetto One', serif" }}
                  {...getMotionProps(isMobile, {
                    initial: { opacity: 0, y: 12 },
                    whileInView: { opacity: 1, y: 0 },
                    viewport: { once: true },
                    transition: { duration: 0.6, delay: 0.35 },
                    whileHover: { scale: 1.05 },
                    whileTap: { scale: 0.97 },
                  })}
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                    <polyline points="7 10 12 15 17 10" />
                    <line x1="12" y1="15" x2="12" y2="3" />
                  </svg>
                  Unduh Aplikasi
                </motion.a>
              </motion.div>

              {/* RIGHT: Image */}
              <motion.div
                className="w-full md:w-[40%] flex items-center justify-center"
                {...getMotionProps(isMobile, {
                  initial: { opacity: 0, x: 36, scale: 0.95 },
                  whileInView: { opacity: 1, x: 0, scale: 1 },
                  viewport: { once: true, amount: 0.3 },
                  transition: { duration: 0.95, ease: [0.16, 1, 0.3, 1] },
                })}
              >
                <CloudinaryImage
                  src={IMAGES.ilooLogo.url}
                  alt="Iloo Logo"
                  width={320}
                  height={320}
                  quality={95}
                  className="w-full max-w-[280px] md:max-w-[320px] h-auto"
                  objectFit="contain"
                />
              </motion.div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
