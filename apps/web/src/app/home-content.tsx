"use client";

import { motion } from "framer-motion";
import { Smartphone, Brain, LayoutDashboard, Search, BarChart3, Shield } from "lucide-react";

/* ─── Per-letter animation for COMING SOON ─── */
const heading = "COMING SOON";

const letterVariants = {
  hidden: { opacity: 0, y: 40, rotateX: -20 },
  visible: (i: number) =>
    ({
      opacity: 1,
      y: 0,
      rotateX: 0,
      transition: {
        type: "spring" as const,
        stiffness: 120,
        damping: 14,
        delay: 0.6 + i * 0.045,
      },
    }) as const,
};

/* ─── Staggered container ─── */
const containerVariants = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.18,
      delayChildren: 0.2,
    },
  },
} as const;

const blockVariants = {
  hidden: { opacity: 0, y: 40 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      type: "spring" as const,
      stiffness: 90,
      damping: 18,
    },
  },
} as const;

const cardVariants = {
  hidden: { opacity: 0, y: 50 },
  visible: (i: number) =>
    ({
      opacity: 1,
      y: 0,
      transition: {
        type: "spring" as const,
        stiffness: 80,
        damping: 16,
        delay: 1.4 + i * 0.1,
      },
    }) as const,
};

const cards = [
  {
    icon: Smartphone,
    title: "Mobile App",
    desc: "Aplikasi Flutter yang memanfaatkan sensor pasif smartphone.",
  },
  {
    icon: Brain,
    title: "Agentic AI",
    desc: "Intervensi proaktif via WhatsApp & Telegram.",
  },
  {
    icon: LayoutDashboard,
    title: "Dashboard",
    desc: "Monitoring data dan insight kesehatan.",
  },
  {
    icon: Search,
    title: "XAI",
    desc: "Setiap saran disertai alasan yang jelas.",
  },
  {
    icon: BarChart3,
    title: "Metacognitive",
    desc: "Pantau bias offloading & overconfidence.",
  },
  {
    icon: Shield,
    title: "Privasi",
    desc: "Data sensor terenkripsi & tidak ada data medis.",
  },
];

export default function HomeContent() {
  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-dot-pattern px-6 py-20">
      {/* ─── Subtle radial glow ─── */}
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(0,0,0,0.03)_0%,transparent_70%)]" />

      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="relative z-10 flex w-full max-w-6xl flex-col items-center gap-20"
      >
        {/* ═══════════ HERO ═══════════ */}
        <motion.section
          variants={blockVariants}
          className="flex flex-col items-center gap-6 text-center"
        >
          {/* Tagline */}
          <motion.p
            variants={blockVariants}
            className="text-xs font-medium uppercase tracking-[0.3em] text-neutral-400"
          >
            Agentic AI for Early Diabetes Prevention
          </motion.p>

          {/* ═══ PER-LETTER "COMING SOON" ═══ */}
          <h1 className="flex flex-wrap justify-center gap-x-4 text-[clamp(3rem,12vw,8rem)] font-black leading-[0.85] tracking-tight text-neutral-900">
            {heading.split("").map((char, i) => (
              <motion.span
                key={`${char}-${i}`}
                custom={i}
                variants={letterVariants}
                initial="hidden"
                animate="visible"
                className="inline-block"
              >
                {char === " " ? (
                  "\u00A0"
                ) : i >= 7 ? (
                  <span className="bg-gradient-to-r from-neutral-900 via-neutral-700 to-neutral-400 bg-clip-text text-transparent">
                    {char}
                  </span>
                ) : (
                  char
                )}
              </motion.span>
            ))}
          </h1>

          {/* Deskripsi */}
          <motion.p
            variants={blockVariants}
            className="max-w-lg text-base leading-relaxed text-neutral-400"
          >
            Kami sedang membangun asisten AI cerdas untuk deteksi dini risiko Diabetes Melitus Tipe
            2.
          </motion.p>
        </motion.section>

        {/* ═══════════ BENTO GRID ═══════════ */}
        <div className="grid w-full grid-cols-2 gap-3 md:grid-cols-4 md:gap-4">
          {cards.map((card, i) => (
            <motion.div
              key={card.title}
              custom={i}
              variants={cardVariants}
              initial="hidden"
              animate="visible"
              className={`rounded-2xl border border-neutral-200 bg-neutral-50/50 p-6 backdrop-blur-sm transition-colors hover:border-neutral-300 md:p-8 ${
                i === 0 ? "col-span-2" : "col-span-1"
              }`}
            >
              <card.icon className="mb-3 h-6 w-6 text-neutral-500" />
              <h3 className="mb-1 text-sm font-semibold uppercase tracking-widest text-neutral-400">
                {card.title}
              </h3>
              <p className="text-sm leading-relaxed text-neutral-500">{card.desc}</p>
            </motion.div>
          ))}
        </div>

        {/* ═══════════ FOOTER ═══════════ */}
        <motion.footer
          variants={blockVariants}
          className="flex flex-col items-center gap-4 text-center"
        >
          <div className="flex items-center gap-3 text-sm text-neutral-400">
            <span>© 2026 Glico</span>
            <span className="h-1 w-1 rounded-full bg-neutral-300" />
            <span>by comingsoon juga</span>
            <span className="h-1 w-1 rounded-full bg-neutral-300" />
            <span>PEKAN IT 2026</span>
          </div>
        </motion.footer>
      </motion.div>
    </div>
  );
}
