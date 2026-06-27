import type { ILLMProvider } from './ai.interface';
import { GeminiProvider } from './gemini.provider';
import { OpenAIProvider } from './openai.provider';
import { MockProvider } from './mock.provider';

/**
 * Purpose:
 * Layanan orkestrator AI (AIService) yang mengatur urutan prioritas provider LLM,
 * kegagalan failover (circuit-breaker), dan pencatatan statistik performa AI untuk admin.
 *
 * Used By:
 * food.routes.ts, bot.routes.ts, admin.routes.ts
 *
 * Depends On:
 * gemini.provider.ts, openai.provider.ts, mock.provider.ts
 *
 * Impact:
 * Titik masuk tunggal untuk semua interaksi AI di backend Glico.
 */

export interface AIStats {
  activeProvider: string;
  fallbackChain: string[];
  failuresToday: number;
  successToday: number;
  totalLatencyMs: number;
  callsCount: number;
}

class AIService {
  private providers: ILLMProvider[] = [];
  
  // Penyimpanan status performa AI di memori (in-memory)
  private stats: AIStats = {
    activeProvider: 'gemini',
    fallbackChain: [],
    failuresToday: 0,
    successToday: 0,
    totalLatencyMs: 0,
    callsCount: 0,
  };

  constructor() {
    // Inisialisasi provider berdasarkan urutan prioritas
    this.providers.push(new GeminiProvider());
    this.providers.push(new OpenAIProvider());
    this.providers.push(new MockProvider()); // Fallback terakhir (Mock)

    this.stats.fallbackChain = this.providers.map(p => p.name);
    this.stats.activeProvider = this.providers[0]?.name || 'mock';
  }

  /**
   * [ID]
   * Mengambil data statistik performa AI untuk dasbor admin.
   *
   * [EN]
   * Gets AI performance statistics for the admin dashboard.
   */
  getStats(): AIStats {
    return { ...this.stats };
  }

  /**
   * [ID]
   * Mengirim permintaan teks biasa dengan mekanisme perpindahan provider otomatis jika terjadi kegagalan.
   *
   * [EN]
   * Sends a plain text request with automatic provider failover if a failure occurs.
   */
  async generateText(prompt: string, systemInstruction?: string): Promise<string> {
    const startTime = Date.now();
    
    for (const provider of this.providers) {
      try {
        const text = await provider.generateText(prompt, systemInstruction);
        
        // Pencatatan statistik sukses
        this.stats.activeProvider = provider.name;
        this.stats.successToday++;
        this.stats.callsCount++;
        this.stats.totalLatencyMs += (Date.now() - startTime);
        
        return text;
      } catch (error) {
        console.warn(`[AI FAILOVER] Provider "${provider.name}" gagal:`, error instanceof Error ? error.message : error);
        this.stats.failuresToday++;
      }
    }
    
    throw new Error('Seluruh LLM Provider gagal memproses generateText.');
  }

  /**
   * [ID]
   * Mengirim permintaan data terstruktur (JSON) dengan mekanisme perpindahan provider otomatis jika terjadi kegagalan.
   *
   * [EN]
   * Sends a structured data (JSON) request with automatic provider failover if a failure occurs.
   */
  async generateJSON<T>(prompt: string, schema: any, systemInstruction?: string): Promise<T> {
    const startTime = Date.now();
    
    for (const provider of this.providers) {
      try {
        const json = await provider.generateJSON<T>(prompt, schema, systemInstruction);
        
        // Pencatatan statistik sukses
        this.stats.activeProvider = provider.name;
        this.stats.successToday++;
        this.stats.callsCount++;
        this.stats.totalLatencyMs += (Date.now() - startTime);
        
        return json;
      } catch (error) {
        console.warn(`[AI FAILOVER] Provider "${provider.name}" gagal:`, error instanceof Error ? error.message : error);
        this.stats.failuresToday++;
      }
    }
    
    throw new Error('Seluruh LLM Provider gagal memproses generateJSON.');
  }
}

export const aiService = new AIService();
export default aiService;
