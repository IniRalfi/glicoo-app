import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * [ID]
 * Merge class names dengan smart conflict resolution
 *
 * [EN]
 * Merge class names with smart conflict resolution
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * [ID]
 * Mengirimkan hit (kunjungan halaman atau unduhan APK) ke proxy API untuk direkam.
 *
 * [EN]
 * Sends a hit (page view or APK download) to the API proxy to be recorded.
 */
export async function trackMetric(key: "page_views" | "apk_downloads") {
  try {
    await fetch("/api/hit", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ key }),
    });
  } catch (err) {
    console.error(`[TRACKING] Failed to track ${key}:`, err);
  }
}
