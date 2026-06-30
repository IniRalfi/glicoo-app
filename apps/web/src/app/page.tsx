import HeroSection from "@/components/sections/HeroSection";
import FeaturesSection from "@/components/sections/FeaturesSection";
import FAQSection from "@/components/sections/FAQSection";
import CTASection from "@/components/sections/CTASection";
import Footer from "@/components/sections/Footer";

/**
 * [ID]
 * Landing Page Glicoo - Halaman utama dengan semua sections
 * FeaturesSection sudah include grid 2x2, Iloo, dan Telegram card
 *
 * [EN]
 * Glicoo Landing Page - Main page with all sections
 * FeaturesSection already includes 2x2 grid, Iloo, and Telegram card
 */
export default function HomePage() {
  return (
    <main className="flex flex-col">
      <div className="global-width-container flex flex-col gap-16 md:gap-20">
        <HeroSection />
        <FeaturesSection />
        <FAQSection />
        <CTASection />
        <Footer />
      </div>
    </main>
  );
}
