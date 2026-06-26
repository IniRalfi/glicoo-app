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
    return `[MOCK RESPONSE] Halo! Ini adalah respon simulasi dari Glico Offline Engine. Kami menerima pesan Anda: "${prompt.substring(0, 50)}${prompt.length > 50 ? '...' : ''}"`;
  }

  async generateJSON<T>(prompt: string, schema: any, systemInstruction?: string): Promise<T> {
    const mockData: any = {
      estimated_calories: 250,
      estimated_sugar_grams: 8.5,
      ai_feedback: `[MOCK RESPONSE] Makanan Anda telah tercatat. Estimasi kalori: 250 kcal, estimasi gula: 8.5 gram. Bagus! Pertahankan pola makan seimbang dan jangan lupa bergerak aktif hari ini ya.`,
    };
    return mockData as T;
  }
}
