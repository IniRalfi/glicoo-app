"use client";

import { ReactNode, useEffect, useState } from "react";
import { MotionConfig } from "framer-motion";

/**
 * [ID]
 * Provider untuk mengatur animasi Framer Motion secara global.
 * Mematikan semua animasi secara dinamis pada perangkat mobile (lebar layar < 768px)
 * untuk menghemat performa, baterai, dan memberikan UX yang instan.
 *
 * [EN]
 * Provider to globally configure Framer Motion animations.
 * Dynamically disables all animations on mobile devices (screen width < 768px)
 * to save performance, battery, and provide an instant UX.
 */
export default function MotionConfigProvider({ children }: { children: ReactNode }) {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkIsMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };

    // Jalankan saat mount
    checkIsMobile();

    window.addEventListener("resize", checkIsMobile);
    return () => window.removeEventListener("resize", checkIsMobile);
  }, []);

  return (
    <MotionConfig reducedMotion={isMobile ? "always" : "user"}>
      {children}
    </MotionConfig>
  );
}
