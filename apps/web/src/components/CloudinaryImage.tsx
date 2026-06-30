"use client";

import Image from "next/image";
import { useState } from "react";
import { cn } from "@/lib/utils";

/**
 * [ID]
 * Komponen gambar yang dioptimasi dengan Cloudinary
 * - Auto WebP conversion
 * - Responsive sizing
 * - Quality optimization
 * - Preload critical images
 *
 * [EN]
 * Optimized image component with Cloudinary
 * - Auto WebP conversion
 * - Responsive sizing
 * - Quality optimization
 * - Preload critical images
 */

interface CloudinaryImageProps {
  /** Public ID gambar di Cloudinary (contoh: "glico/hero-image") */
  src: string;
  /** Alt text untuk accessibility */
  alt: string;
  /** Width dalam px */
  width: number;
  /** Height dalam px */
  height: number;
  /** Kualitas gambar 1-100 (default: 85) */
  quality?: number;
  /** Priority loading untuk above-the-fold images */
  priority?: boolean;
  /** Custom className */
  className?: string;
  /** Object fit */
  objectFit?: "contain" | "cover" | "fill" | "none" | "scale-down";
}

export default function CloudinaryImage({
  src,
  alt,
  width,
  height,
  quality = 85,
  priority = false,
  className = "",
  objectFit = "cover",
}: CloudinaryImageProps) {
  const [isLoading, setIsLoading] = useState(true);

  // Cloudinary base URL
  const CLOUDINARY_CLOUD_NAME = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME || "ddyad5ucm";
  const CLOUDINARY_BASE_URL = `https://res.cloudinary.com/${CLOUDINARY_CLOUD_NAME}/image/upload`;

  /**
   * Transformasi Cloudinary untuk optimasi maksimal:
   * - f_auto: Format otomatis (WebP untuk browser support)
   * - q_${quality}: Quality setting
   * - w_${width},h_${height}: Dimensions
   * - c_fill,g_auto: Crop fill dengan auto gravity
   */

  // Jika src sudah full URL, gunakan langsung. Jika tidak, build dari base URL
  const isFullUrl = src.startsWith("http");
  const cloudinaryUrl = isFullUrl
    ? src
    : `${CLOUDINARY_BASE_URL}/f_auto,q_${quality},w_${width},h_${height},c_fill,g_auto/${src}`;

  const isSvg = src.toLowerCase().includes(".svg");

  if (isSvg) {
    return (
      <img
        src={cloudinaryUrl}
        alt={alt}
        width={width}
        height={height}
        style={{ height: "auto" }}
        className={cn(
          objectFit === "cover" && "object-cover",
          objectFit === "contain" && "object-contain",
          objectFit === "fill" && "object-fill",
          objectFit === "none" && "object-none",
          objectFit === "scale-down" && "object-scale-down",
          className
        )}
      />
    );
  }

  return (
    <Image
      src={cloudinaryUrl}
      alt={alt}
      width={width}
      height={height}
      quality={quality}
      priority={priority}
      style={{ height: "auto" }}
      className={cn(
        "duration-700 ease-in-out",
        isLoading ? "scale-105 blur-lg grayscale" : "scale-100 blur-0 grayscale-0",
        objectFit === "cover" && "object-cover",
        objectFit === "contain" && "object-contain",
        objectFit === "fill" && "object-fill",
        objectFit === "none" && "object-none",
        objectFit === "scale-down" && "object-scale-down",
        className
      )}
      onLoad={() => setIsLoading(false)}
    />
  );
}
