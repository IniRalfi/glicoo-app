"use client";

import { motion, type Variants } from "framer-motion";
import CloudinaryImage from "@/components/CloudinaryImage";
import { IMAGES } from "@/lib/cloudinary-images";

/**
 * [ID]
 * Features Section - Showcase fitur-fitur utama aplikasi
 * 1. Grid 2x2: 4 screenshot fitur utama
 * 2. Iloo Character: image + text
 * 3. Telegram Card: HP screenshot (cropped) + text
 *
 * [EN]
 * Features Section - Showcase main app features
 * 1. 2x2 grid: 4 main feature screenshots
 * 2. Iloo Character: image + text
 * 3. Telegram Card: Phone screenshot (cropped) + text
 */

const featureImages = [
  { key: "monitoring", data: IMAGES.features.monitoring },
  { key: "food", data: IMAGES.features.food },
  { key: "mission", data: IMAGES.features.mission },
  { key: "ai", data: IMAGES.features.ai },
];

const containerVariants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.12 },
  },
};

const cardVariants: Variants = {
  hidden: { opacity: 0, y: 36, scale: 0.97 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    // WHY: cubicBezier string → valid Easing type, bare number[] bukan
    transition: { duration: 0.65, ease: "easeOut" },
  },
};

export default function FeaturesSection() {
  return (
    <section className="relative w-full py-20 bg-background px-6 md:px-16">
      <div className="max-w-4xl mx-auto space-y-24">
        {/* ─── Part 1: Features Grid 2x2 ─── */}
        <motion.div
          className="grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-8"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.1 }}
        >
          {featureImages.map((feature) => (
            <motion.div
              key={feature.key}
              variants={cardVariants}
              className="w-full"
              whileHover={{ y: -6, transition: { duration: 0.3, ease: "easeOut" } }}
            >
              <CloudinaryImage
                src={feature.data.url}
                alt={feature.data.description}
                width={200}
                height={280}
                quality={95}
                className="w-full h-auto rounded-2xl"
                objectFit="cover"
              />
            </motion.div>
          ))}
        </motion.div>

        {/* ─── Part 2: Iloo Character ─── */}
        <div className="flex flex-col md:flex-row items-center gap-12">
          {/* Image Left */}
          <motion.div
            className="w-full md:w-[35%]"
            initial={{ opacity: 0, x: -40 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }}
          >
            <CloudinaryImage
              src={IMAGES.features2.iloo.url}
              alt={IMAGES.features2.iloo.description}
              width={800}
              height={600}
              quality={95}
              className="w-full h-auto"
              objectFit="contain"
            />
          </motion.div>

          {/* Text Right */}
          <motion.div
            className="w-full md:w-1/2 space-y-3"
            initial={{ opacity: 0, x: 40 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }}
          >
            <motion.div
              className="text-sm md:text-base font-bold text-primary"
              initial={{ opacity: 0, y: 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: 0.2 }}
            >
              Agentic AI
            </motion.div>

            <motion.h2
              className="font-display text-3xl md:text-4xl text-foreground leading-tight"
              initial={{ opacity: 0, y: 14 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.3 }}
            >
              Pendamping yang Memahami Kebiasaanmu.
            </motion.h2>

            <motion.p
              className="text-sm md:text-base text-muted-foreground leading-relaxed"
              initial={{ opacity: 0, y: 14 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.4 }}
            >
              Iloo adalah AI companion yang membantu kamu membangun kebiasaan sehat secara
              konsisten. Dengan pendekatan metacognitive, Iloo tidak hanya memberi saran, tapi
              membantu kamu memahami pola pikir dan perilakumu sendiri.
            </motion.p>

            <motion.ul
              className="space-y-2"
              variants={containerVariants}
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true, amount: 0.2 }}
            >
              {[
                "Pengingat yang proaktif",
                "Analisis pola kebiasaan",
                "Intervensi berbasis data",
                "Explainable AI",
                "Misi harian",
                "Progress kesehatan",
              ].map((item) => (
                <motion.li
                  key={item}
                  className="flex items-start gap-2"
                  variants={{
                    hidden: { opacity: 0, x: -12 },
                    visible: { opacity: 1, x: 0, transition: { duration: 0.45, ease: "easeOut" } },
                  }}
                >
                  <span className="text-primary text-lg font-bold mt-0.5">✓</span>
                  <span className="text-primary font-bold text-sm md:text-base">{item}</span>
                </motion.li>
              ))}
            </motion.ul>
          </motion.div>
        </div>

        {/* ─── Part 3: Telegram Integration Card ─── */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }}
          className="w-full max-w-[1200px] mx-auto"
        >
          <div
            className="relative overflow-hidden rounded-3xl bg-[#F2F2F7]"
          >
            {/* Mobile: stack vertikal, Desktop: row */}
            <div className="flex flex-col md:flex-row md:items-stretch md:h-[450px]">
              {/* Image — mobile: full width dengan max-height, desktop: fixed width column */}
              <motion.div
                className="w-full md:w-[37%] md:h-full overflow-hidden flex-shrink-0 flex items-end md:items-center pl-0 md:pl-8"
                initial={{ opacity: 0, x: -30 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
              >
                <CloudinaryImage
                  src={IMAGES.features2.telegramPhone.url}
                  alt={IMAGES.features2.telegramPhone.description}
                  width={400}
                  height={600}
                  quality={95}
                  className="w-full max-h-[280px] md:max-h-none md:h-full object-cover md:object-contain"
                  objectFit="cover"
                />
              </motion.div>

              {/* Text Right - Centered Vertically */}
              <motion.div
                className="flex-1 px-6 md:px-10 py-8 flex items-center justify-center"
                initial={{ opacity: 0, x: 30 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.8, delay: 0.35, ease: [0.16, 1, 0.3, 1] }}
              >
                <div className="w-full max-w-2xl space-y-3 text-center">
                  <h3 className="font-display text-2xl md:text-3xl text-foreground leading-tight">
                    Pendampingan di Aplikasi yang Sudah Kamu Gunakan
                  </h3>

                  <p className="text-sm md:text-base text-muted-foreground leading-relaxed">
                    Tidak perlu membuka aplikasi setiap saat. Iloo akan tetap mendampingimu melalui
                    WhatsApp atau Telegram.
                  </p>
                </div>
              </motion.div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
