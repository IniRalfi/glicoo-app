"use client";

import { useEffect, ReactNode } from "react";
import Lenis from "lenis";

/**
 * [ID]
 * Provider untuk smooth scrolling menggunakan Lenis
 * Memberikan pengalaman scroll yang buttery smooth
 *
 * [EN]
 * Provider for smooth scrolling using Lenis
 * Provides buttery smooth scroll experience
 */
export default function SmoothScrollProvider({ children }: { children: ReactNode }) {
  useEffect(() => {
    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)), // easeOutExpo
      smoothWheel: true,
      wheelMultiplier: 1,
      touchMultiplier: 2,
    });

    function raf(time: number) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }

    requestAnimationFrame(raf);

    return () => {
      lenis.destroy();
    };
  }, []);

  return <>{children}</>;
}
