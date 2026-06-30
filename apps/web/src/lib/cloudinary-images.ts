/**
 * [ID]
 * Index terpusat untuk semua gambar Cloudinary
 * Memudahkan manajemen URL gambar dan menghindari hardcoded URL di component
 *
 * [EN]
 * Centralized index for all Cloudinary images
 * Makes image URL management easier and avoids hardcoded URLs in components
 *
 * Usage:
 * import { IMAGES } from "@/lib/cloudinary-images"
 * <CloudinaryImage src={IMAGES.hero.main.url} alt={IMAGES.hero.main.description} />
 */

interface ImageAsset {
  /** URL Cloudinary public ID (contoh: "glicoo/hero-main" atau full URL) */
  url: string;
  /** Deskripsi untuk alt text default */
  description: string;
  /** Width default (px) */
  width?: number;
  /** Height default (px) */
  height?: number;
}

/**
 * IMAGES INDEX
 *
 * Cara mengisi:
 * 1. Upload image ke Cloudinary
 * 2. Copy Public ID (contoh: glicoo/hero-main) atau full URL
 * 3. Tambahkan di section yang sesuai di bawah
 */

export const IMAGES = {
  // ═══════════════════════════════════════════════════════════
  // 🦸 HERO SECTION
  // ═══════════════════════════════════════════════════════════
  hero: {
    main: {
      url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782793175/Frame_2442_l5jjck.svg", // ← Ganti dengan URL kamu
      description: "Glicoo Hero Illustration",
      width: 1920,
      height: 969,
    },
  },

  // ═══════════════════════════════════════════════════════════
  // ✨ FEATURES SECTION 1 (Grid Cards)
  // ═══════════════════════════════════════════════════════════
  features: {
    monitoring: {
      url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782793340/Frame_2443_wwyggh.svg",
      description: "Monitoring Aktivitas",
      width: 1200,
      height: 900,
    },
    food: {
      url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782793340/Frame_2444_sft7uc.svg",
      description: "Pencatat Makanan",
      width: 1200,
      height: 900,
    },
    mission: {
      url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782793340/Frame_2443_1_v2hdfc.svg",
      description: "Misi Harian",
      width: 1200,
      height: 900,
    },
    ai: {
      url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782793340/Frame_2444_1_hrhwhv.svg",
      description: "Pendamping AI",
      width: 1200,
      height: 900,
    },
  },

  // ═══════════════════════════════════════════════════════════
  // 🎯 FEATURES SECTION 2 (Image + Text Layout)
  // ═══════════════════════════════════════════════════════════
  features2: {
    iloo: {
      url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782793489/Frame_2476_jntntn.svg",
      description: "Iloo Character - Pendamping AI",
      width: 800,
      height: 600,
    },
    telegramPhone: {
      url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782793492/Frame_2467_ojmope.svg",
      description: "Telegram Integration Preview",
      width: 600,
      height: 800,
    },
  },

  // ═══════════════════════════════════════════════════════════
  // 📲 CTA DOWNLOAD SECTION
  // ═══════════════════════════════════════════════════════════
  ilooLogo: {
    url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782794766/Frame_2490_q725xh.svg",
    description: "Iloo Logo - CTA Section",
    width: 400,
    height: 400,
  },
  cta: {
    qrCode: {
      url: "glicoo/qr-download",
      description: "QR Code untuk Download APK",
      width: 200,
      height: 200,
    },
    appPreview: {
      url: "glicoo/app-preview-mockup",
      description: "App Preview Mockup",
      width: 400,
      height: 800,
    },
  },

  // ═══════════════════════════════════════════════════════════
  // 📱 DOWNLOAD PAGE
  // ═══════════════════════════════════════════════════════════
  download: {
    qrCodeLarge: {
      url: "glicoo/qr-download-large",
      description: "QR Code Download (Large)",
      width: 400,
      height: 400,
    },
    appScreenshots: {
      screen1: {
        url: "glicoo/screenshot-home",
        description: "Home Screen",
        width: 400,
        height: 800,
      },
      screen2: {
        url: "glicoo/screenshot-chat",
        description: "Chatbot Screen",
        width: 400,
        height: 800,
      },
      screen3: {
        url: "glicoo/screenshot-dashboard",
        description: "Dashboard Screen",
        width: 400,
        height: 800,
      },
    },
  },

  // ═══════════════════════════════════════════════════════════
  // 🎨 BRAND ASSETS (Logo, Mascot, etc)
  // ═══════════════════════════════════════════════════════════
  brand: {
    logo: {
      url: "glicoo/logo",
      description: "Glicoo Logo",
      width: 200,
      height: 60,
    },
    logoSquare: {
      url: "glicoo/logo-square",
      description: "Glicoo Logo Square",
      width: 200,
      height: 200,
    },
    ilooMascot: {
      url: "glicoo/iloo-mascot",
      description: "Iloo AI Mascot",
      width: 300,
      height: 300,
    },
  },
  // ═══════════════════════════════════════════════════════════
  // 🦶 FOOTER ASSETS
  // ═══════════════════════════════════════════════════════════
  footer: {
    glicooLogo: {
      url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782795497/Frame_lm0u1u.svg",
      description: "Glicoo Logo Footer",
      width: 241,
      height: 65,
    },
    star: {
      url: "https://res.cloudinary.com/ddyad5ucm/image/upload/v1782795497/Vector_zsslqe.svg",
      description: "Star Icon Footer",
      width: 24,
      height: 24,
    },
  },
} as const;

/**
 * Helper untuk mendapatkan full Cloudinary URL dengan transformations
 *
 * @example
 * getCloudinaryUrl(IMAGES.hero.main.url, { width: 800, quality: 90 })
 */
export function getCloudinaryUrl(
  imageUrl: string,
  options?: {
    width?: number;
    height?: number;
    quality?: number;
    format?: "auto" | "webp" | "avif" | "jpg" | "png";
  }
) {
  const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME || "your-cloud-name";

  // Jika sudah full URL, return as-is
  if (imageUrl.startsWith("http")) {
    return imageUrl;
  }

  const baseUrl = `https://res.cloudinary.com/${cloudName}/image/upload`;
  const transformations = [];

  // Format optimization
  if (options?.format) transformations.push(`f_${options.format}`);
  else transformations.push("f_auto"); // auto format (WebP untuk browser yang support)

  // Quality optimization
  if (options?.quality) transformations.push(`q_${options.quality}`);
  else transformations.push("q_auto:good"); // auto quality dengan balance

  // Dimensions
  if (options?.width) transformations.push(`w_${options.width}`);
  if (options?.height) transformations.push(`h_${options.height}`);

  // Crop & gravity (smart crop)
  transformations.push("c_fill");
  transformations.push("g_auto");

  return `${baseUrl}/${transformations.join(",")}/${imageUrl}`;
}
