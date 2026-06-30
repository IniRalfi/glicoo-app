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
