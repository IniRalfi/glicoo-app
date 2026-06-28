import type { ILLMProvider } from './ai.interface';

/**
 * Purpose:
 * Provider LLM tiruan (mock) untuk pengembangan offline dan fallback terakhir.
 *
 * Used By:
 * ai.service.ts
 *
 * Depends On:
 * None
 *
 * Impact:
 * Digunakan jika seluruh provider utama (Gemini & OpenAI) gagal atau tidak dikonfigurasi.
 */
export class MockProvider implements ILLMProvider {
  readonly name = 'mock';

  async generateText(prompt: string, systemInstruction?: string): Promise<string> {
    return `[MOCK RESPONSE] Halo! Ini adalah respon simulasi dari Glicoo Offline Engine. Kami menerima pesan Anda: "${prompt.substring(0, 50)}${prompt.length > 50 ? '...' : ''}"`;
  }

  async generateJSON<T>(prompt: string, schema: any, systemInstruction?: string): Promise<T> {
    const mockData: any = {
      estimated_calories: 350,
      estimated_sugar_grams: 8.5,
      carbohydrate_level: 'Sedang',
      sugar_level: 'Sedang',
      protein_level: 'Cukup',
      ai_feedback: `Wah, menu "${prompt}" kelihatan lezat banget Kak! 🍲 Estimasi energi makanan ini sekitar 350 kkal. Tetap imbangi dengan minum air putih dan jaga kebiasaan bergerak aktif ya! ✨`,
    };
    return mockData as T;
  }
}
