"use client";

import { ReactNode } from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

interface BentoCardProps {
  children: ReactNode;
  className?: string;
  /** Warna pastel untuk background card. Default: bg-[#FFF9F0] (pastel orange-yellow) */
  backgroundColor?: string;
  /** Arah hover animation. Default: none */
  hoverEffect?: "lift" | "glow" | "none";
  /** Judul card (opsional) */
  title?: string;
  /** Subtitle / deskripsi (opsional) */
  subtitle?: string;
}

/**
 * [ID]
 * Komponen Bento Card reusable dengan desain minimalist, rounded corners, dan warna pastel.
 * Menghindari desain neobrutalism (tanpa bayangan blok hitam tajam).
 *
 * [EN]
 * Reusable Bento Card component with minimalist, rounded corners, and pastel colors.
 * Avoids neobrutalism design (no hard blocky shadows).
 */
export default function BentoCard({
  children,
  className = "",
  backgroundColor = "bg-[#FFF9E6]", // pastel/soft yellow-orange
  hoverEffect = "lift",
  title,
  subtitle,
}: BentoCardProps) {
  const CardWrapper = hoverEffect !== "none" ? motion.div : "div";

  const motionProps =
    hoverEffect === "lift"
      ? {
          whileHover: { y: -4, transition: { duration: 0.2, ease: "easeOut" } },
          whileTap: { scale: 0.99 },
        }
      : hoverEffect === "glow"
        ? {
            whileHover: { scale: 1.01, boxShadow: "0 10px 30px -10px rgba(255, 183, 0, 0.15)" },
            whileTap: { scale: 0.99 },
          }
        : {};

  return (
    // @ts-ignore
    <CardWrapper
      {...motionProps}
      className={cn(
        "rounded-2xl border border-[#FFEBC2] p-6 flex flex-col justify-between overflow-hidden relative shadow-sm",
        backgroundColor,
        className
      )}
    >
      {(title || subtitle) && (
        <div className="mb-4 space-y-1">
          {title && <h3 className="font-display text-lg text-foreground">{title}</h3>}
          {subtitle && <p className="text-xs text-muted-foreground font-medium">{subtitle}</p>}
        </div>
      )}
      <div className="flex-1 flex flex-col justify-end w-full">{children}</div>
    </CardWrapper>
  );
}
