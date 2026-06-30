"use client";

import { motion, AnimatePresence } from "framer-motion";
import { useState } from "react";
import { cn } from "@/lib/utils";

/**
 * [ID]
 * FAQ Section - Layout 2 kolom: judul kiri, accordion kanan
 * Icon + biru (#0095FF), jadi - saat expand
 *
 * [EN]
 * FAQ Section - 2-column layout: title left, accordion right
 * Blue + icon (#0095FF) turns to - on expand
 */

interface FAQItem {
  question: string;
  answer: string;
}

const faqs: FAQItem[] = [
  {
    question: "Apa itu Glicoo?",
    answer:
      "Glicoo adalah aplikasi mobile berbasis Agentic AI yang membantu kamu mendeteksi risiko Diabetes Melitus Tipe 2 secara dini. Dengan pendekatan proaktif dan personal, Glicoo memantau kebiasaan harianmu dan memberikan intervensi yang tepat waktu.",
  },
  {
    question: "Siapa yang cocok menggunakan Glicoo?",
    answer:
      "Glicoo dirancang untuk siapa saja yang ingin menjaga kesehatan metabolik dan mencegah diabetes sejak dini. Khususnya bagi kamu yang memiliki gaya hidup sedentari, riwayat keluarga diabetes, atau ingin lebih proaktif dalam memahami kondisi tubuh.",
  },
  {
    question: "Bagaimana Glicoo mengetahui kondisi saya?",
    answer:
      "Glicoo memanfaatkan sensor smartphone untuk memantau aktivitas harian seperti langkah kaki dan screen time. Data ini dianalisis oleh AI untuk mengenali pola kebiasaan dan memberikan rekomendasi yang personal sesuai kebutuhanmu.",
  },
  {
    question: "Bagaimana Iloo membantu saya setiap hari?",
    answer:
      "Iloo adalah AI companion-mu yang aktif setiap hari — mengingatkan misi harian, memberikan insight tentang kebiasaanmu, dan membantu kamu membangun pola hidup sehat secara konsisten melalui pendekatan metacognitive.",
  },
  {
    question: "Apakah Glicoo dapat menggantikan dokter?",
    answer:
      "Tidak. Glicoo adalah alat bantu untuk deteksi dini dan pendamping gaya hidup sehat, bukan pengganti konsultasi medis profesional. Jika kamu memiliki gejala atau kondisi tertentu, tetap konsultasikan dengan dokter.",
  },
];

function PlusIcon({ open }: { open: boolean }) {
  return (
    <div className="relative w-6 h-6 flex-shrink-0">
      {/* Horizontal line (always visible) */}
      <span
        className={cn(
          "absolute top-1/2 left-0 w-full h-0.5 -translate-y-1/2 rounded-full transition-colors duration-300",
          open ? "bg-[#0095FF]" : "bg-[#0095FF]"
        )}
      />
      {/* Vertical line (rotates on open → minus) */}
      <motion.span
        className="absolute top-0 left-1/2 w-0.5 h-full -translate-x-1/2 rounded-full bg-[#0095FF]"
        animate={{ rotate: open ? 90 : 0, opacity: open ? 0 : 1 }}
        transition={{ duration: 0.25, ease: "easeInOut" }}
      />
    </div>
  );
}

export default function FAQSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const toggleFAQ = (index: number) => {
    setOpenIndex(openIndex === index ? null : index);
  };

  return (
    <section className="relative w-full py-20 bg-background px-6 md:px-16">
      <div className="max-w-5xl mx-auto">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-10 md:gap-16">
          {/* Title - Left Column */}
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            className="md:col-span-4 text-center md:text-left"
          >
            <h2 className="font-display text-2xl md:text-3xl lg:text-4xl text-foreground leading-tight md:sticky md:top-8">
              Pertanyaan yang Sering Diajukan
            </h2>
          </motion.div>

          {/* FAQ Accordion - Right Column */}
          <div className="md:col-span-8 space-y-8">
            {faqs.map((faq, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.1 }}
                transition={{ duration: 0.55, delay: index * 0.08, ease: [0.16, 1, 0.3, 1] }}
              >
                {/* Question Button */}
                <motion.button
                  onClick={() => toggleFAQ(index)}
                  className="w-full flex items-start gap-4 text-left group"
                  whileTap={{ scale: 0.99 }}
                >
                  <PlusIcon open={openIndex === index} />
                  <span className="font-semibold text-base md:text-lg text-foreground leading-snug pt-0.5 group-hover:text-primary transition-colors duration-200">
                    {faq.question}
                  </span>
                </motion.button>

                {/* Answer */}
                <AnimatePresence initial={false}>
                  {openIndex === index && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
                      className="overflow-hidden"
                    >
                      <motion.div
                        initial={{ y: -8 }}
                        animate={{ y: 0 }}
                        exit={{ y: -8 }}
                        transition={{ duration: 0.3, ease: "easeOut" }}
                        className="pl-10 pr-4 pb-4 pt-2 text-muted-foreground text-sm md:text-base leading-relaxed"
                      >
                        {faq.answer}
                      </motion.div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
