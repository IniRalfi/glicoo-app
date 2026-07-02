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
    // Disable Lenis smooth scroll on mobile devices to prevent touch scroll crashes/momentum lag
    if (typeof window !== "undefined" && window.innerWidth < 768) {
      return;
    }

    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)), // easeOutExpo
      smoothWheel: true,
      wheelMultiplier: 1,
      touchMultiplier: 2,
    });

    let frameId: number;
    function raf(time: number) {
      lenis.raf(time);
      frameId = requestAnimationFrame(raf);
    }

    frameId = requestAnimationFrame(raf);

    return () => {
      cancelAnimationFrame(frameId);
      lenis.destroy();
    };
  }, []);

  return <>{children}</>;
}
