"use client";

import { useState, useEffect } from "react";

/**
 * [ID]
 * Hook kustom untuk mendeteksi apakah viewport saat ini adalah perangkat mobile (lebar layar < 768px).
 *
 * [EN]
 * Custom hook to detect if the current viewport is a mobile device (screen width < 768px).
 */
export function useIsMobile() {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768);
    check();
    window.addEventListener("resize", check);
    return () => window.removeEventListener("resize", check);
  }, []);

  return isMobile;
}

interface MotionProps {
  initial?: any;
  animate?: any;
  whileInView?: any;
  whileHover?: any;
  whileTap?: any;
  variants?: any;
  transition?: any;
  viewport?: any;
  exit?: any;
}

/**
 * [ID]
 * Helper untuk menyaring props Framer Motion. Jika di perangkat mobile,
 * ia akan mengembalikan objek kosong sehingga elemen menjadi statis (tidak ada animasi, offset, atau sticky hover).
 *
 * [EN]
 * Helper to filter Framer Motion props. If on mobile,
 * it returns an empty object so the element remains static (no animation, offsets, or sticky hovers).
 */
export function getMotionProps(isMobile: boolean, props: MotionProps) {
  if (isMobile) {
    return {};
  }
  return props;
}
