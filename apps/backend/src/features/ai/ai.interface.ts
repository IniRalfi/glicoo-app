/**
 * Purpose:
 * Definisi kontrak interface untuk penyedia model LLM (Gemini, OpenAI, Groq, dll.)
 *
 * Used By:
 * ai.service.ts, gemini.provider.ts, groq.provider.ts
 *
 * Depends On:
 * None
 *
 * Impact:
 * Perubahan pada interface akan memengaruhi seluruh provider AI dan kelas AI Service.
 */

/**
 * [ID]
 * Antarmuka untuk penyedia layanan LLM.
 *
 * [EN]
 * Interface for LLM service providers.
 */
export interface ILLMProvider {
  name: string;
  generateText(prompt: string, systemInstruction?: string): Promise<string>;
  generateJSON<T>(prompt: string, schema: any, systemInstruction?: string): Promise<T>;
}
