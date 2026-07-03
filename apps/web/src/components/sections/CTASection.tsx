"use client";

import CloudinaryImage from "@/components/CloudinaryImage";
import { IMAGES } from "@/lib/cloudinary-images";

export default function CTASection() {
  return (
    <section className="w-full bg-[#F2F2F7] py-12 mb-16">
      <div className="w-[90%] md:w-[70%] mx-auto flex flex-col md:flex-row items-center justify-between gap-8">
        {/* LEFT: Text container */}
        <div className="w-full md:w-[55%] flex flex-col gap-4">
          <h2 className="font-display text-foreground leading-tight text-2xl md:text-3xl lg:text-4xl">
            Kesehatan Dimulai dari Kebiasaan Kecil
          </h2>

          <p className="text-foreground font-bold leading-snug text-sm md:text-base">
            Mencegah Diabetes Melitus Tipe 2 tidak harus dimulai dengan perubahan besar. Bangun
            kebiasaan sehat sedikit demi sedikit, dan biarkan Iloo mendampingimu setiap hari.
          </p>

          <a
            href="/download"
            className="inline-flex items-center gap-2 rounded-full text-white transition-opacity hover:opacity-90 w-fit px-5 py-2.5 text-sm md:text-base mt-2"
            style={{
              backgroundColor: "#000000",
              borderRadius: "100px",
              fontFamily: "'Rammetto One', serif",
            }}
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="white"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="7 10 12 15 17 10" />
              <line x1="12" y1="15" x2="12" y2="3" />
            </svg>
            Unduh Aplikasi
          </a>
        </div>

        {/* RIGHT: Image */}
        <div className="w-full md:w-[40%] flex items-center justify-center">
          <CloudinaryImage
            src={IMAGES.ilooLogo.url}
            alt="Iloo Logo"
            width={320}
            height={320}
            quality={95}
            className="w-full max-w-[280px] md:max-w-[320px] h-auto"
            objectFit="contain"
          />
        </div>
      </div>
    </section>
  );
}
