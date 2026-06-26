import { GoogleGenerativeAI } from '@google/generative-ai';
import type { ILLMProvider } from './ai.interface';

/**
 * Purpose:
 * Implementasi LLM Provider untuk Google Gemini API.
 *
 * Used By:
 * ai.service.ts
 *
 * Depends On:
 * @google/generative-ai
 *
 * Impact:
 * Digunakan sebagai AI Engine utama. Perubahan konfigurasi model atau parameter generasi
 * berdampak langsung pada respon chatbot dan analisis makanan.
 */
export class GeminiProvider implements ILLMProvider {
  readonly name = 'gemini';
  private genAI: GoogleGenerativeAI | null = null;
  private modelName: string;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    this.modelName = process.env.GEMINI_MODEL || 'gemini-1.5-flash';
    
    if (apiKey) {
      this.genAI = new GoogleGenerativeAI(apiKey);
    }
  }

  /**
   * [ID]
   * Menghasilkan teks biasa menggunakan prompt dan instruksi sistem.
   *
   * [EN]
   * Generates plain text using prompt and system instructions.
   */
  async generateText(prompt: string, systemInstruction?: string): Promise<string> {
    if (!this.genAI) {
      throw new Error('Gemini API Key is not configured.');
    }

    const model = this.genAI.getGenerativeModel({
      model: this.modelName,
      systemInstruction: systemInstruction,
    });

    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text();
  }

  /**
   * [ID]
   * Menghasilkan data terstruktur (JSON) berdasarkan skema yang diberikan.
   *
   * [EN]
   * Generates structured data (JSON) based on the provided schema.
   */
  async generateJSON<T>(prompt: string, schema: any, systemInstruction?: string): Promise<T> {
    if (!this.genAI) {
      throw new Error('Gemini API Key is not configured.');
    }

    const model = this.genAI.getGenerativeModel({
      model: this.modelName,
      systemInstruction: systemInstruction,
      generationConfig: {
        responseMimeType: 'application/json',
        responseSchema: schema,
      },
    });

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    return JSON.parse(text) as T;
  }
}
