import type { ILLMProvider } from './ai.interface';

/**
 * Purpose:
 * Implementasi LLM Provider untuk API yang kompatibel dengan OpenAI (OpenAI, Groq, OpenRouter, DeepSeek, Ollama, dll.)
 *
 * Used By:
 * ai.service.ts
 *
 * Depends On:
 * Native Fetch
 *
 * Impact:
 * Digunakan sebagai AI Engine cadangan (fallback). Dapat diarahkan ke Groq, DeepSeek, atau OpenAI
 * dengan mengubah URL base, model, dan API Key di .env.
 */
export class OpenAIProvider implements ILLMProvider {
  readonly name = 'openai';
  private apiKey: string;
  private baseURL: string;
  private modelName: string;

  constructor() {
    this.apiKey = process.env.OPENAI_API_KEY || '';
    this.baseURL = process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1';
    this.modelName = process.env.OPENAI_MODEL || 'gpt-4o-mini';
  }

  /**
   * [ID]
   * Menghasilkan teks biasa menggunakan prompt dan instruksi sistem via API OpenAI compatible.
   *
   * [EN]
   * Generates plain text using prompt and system instructions via OpenAI compatible API.
   */
  async generateText(prompt: string, systemInstruction?: string): Promise<string> {
    if (!this.apiKey) {
      throw new Error('OpenAI/Fallback API Key is not configured.');
    }

    const messages: any[] = [];
    if (systemInstruction) {
      messages.push({ role: 'system', content: systemInstruction });
    }
    messages.push({ role: 'user', content: prompt });

    const response = await fetch(`${this.baseURL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model: this.modelName,
        messages: messages,
        temperature: 0.7,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`OpenAI Compatible API failed: ${response.statusText} - ${errText}`);
    }

    const data: any = await response.json();
    return data.choices[0]?.message?.content || '';
  }

  /**
   * [ID]
   * Menghasilkan JSON terstruktur berdasarkan skema via API OpenAI compatible.
   *
   * [EN]
   * Generates structured JSON based on schema via OpenAI compatible API.
   */
  async generateJSON<T>(prompt: string, schema: any, systemInstruction?: string): Promise<T> {
    if (!this.apiKey) {
      throw new Error('OpenAI/Fallback API Key is not configured.');
    }

    const messages: any[] = [];
    if (systemInstruction) {
      messages.push({ role: 'system', content: systemInstruction });
    }
    
    // Memberikan petunjuk skema di prompt untuk menjamin keakuratan format
    const jsonPrompt = `${prompt}\n\nIMPORTANT: Respond ONLY with a raw JSON object matching this schema. Do not enclose in markdown code blocks:\n${JSON.stringify(schema, null, 2)}`;
    messages.push({ role: 'user', content: jsonPrompt });

    const response = await fetch(`${this.baseURL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model: this.modelName,
        messages: messages,
        response_format: { type: 'json_object' },
        temperature: 0.1,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`OpenAI Compatible API failed: ${response.statusText} - ${errText}`);
    }

    const data: any = await response.json();
    const text = data.choices[0]?.message?.content || '{}';
    return JSON.parse(text) as T;
  }
}
