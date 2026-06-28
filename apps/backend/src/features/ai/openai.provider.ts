import type { ILLMProvider } from './ai.interface';

/**
 * Purpose:
 * Implementasi LLM Provider untuk API yang kompatibel dengan OpenAI (OpenAI, Groq, OpenRouter, DeepSeek, Ollama, dll.)
 * Serta secara cerdas mendeteksi dan menggunakan format Anthropic Messages jika diarahkan ke openmodel.ai.
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

  private isAnthropic(): boolean {
    return this.baseURL.includes('openmodel.ai') || this.apiKey.startsWith('om-');
  }

  /**
   * [ID]
   * Menghasilkan teks biasa menggunakan prompt dan instruksi sistem via API OpenAI / Anthropic compatible.
   *
   * [EN]
   * Generates plain text using prompt and system instructions via OpenAI / Anthropic compatible API.
   */
  async generateText(prompt: string, systemInstruction?: string): Promise<string> {
    if (!this.apiKey) {
      throw new Error('OpenAI/Fallback API Key is not configured.');
    }

    if (this.isAnthropic()) {
      const response = await fetch(`${this.baseURL}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: this.modelName,
          max_tokens: 4096,
          system: systemInstruction,
          messages: [{ role: 'user', content: prompt }],
          temperature: 0.7,
        }),
      });

      if (!response.ok) {
        const errText = await response.text();
        throw new Error(`OpenModel/Anthropic API failed: ${response.statusText} - ${errText}`);
      }

      const data: any = await response.json();
      const textBlock = data.content?.find((block: any) => block.type === 'text');
      return textBlock?.text || '';
    }

    // Default OpenAI completion
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
   * Menghasilkan JSON terstruktur berdasarkan skema via API OpenAI / Anthropic compatible.
   *
   * [EN]
   * Generates structured JSON based on schema via OpenAI / Anthropic compatible API.
   */
  async generateJSON<T>(prompt: string, schema: any, systemInstruction?: string): Promise<T> {
    if (!this.apiKey) {
      throw new Error('OpenAI/Fallback API Key is not configured.');
    }

    const jsonPrompt = `${prompt}\n\nIMPORTANT: Respond ONLY with a raw JSON object matching this schema. Do not enclose in markdown code blocks:\n${JSON.stringify(schema, null, 2)}`;

    if (this.isAnthropic()) {
      const response = await fetch(`${this.baseURL}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: this.modelName,
          max_tokens: 4096,
          system: systemInstruction,
          messages: [{ role: 'user', content: jsonPrompt }],
          temperature: 0.1,
        }),
      });

      if (!response.ok) {
        const errText = await response.text();
        throw new Error(`OpenModel/Anthropic API failed: ${response.statusText} - ${errText}`);
      }

      const data: any = await response.json();
      const textBlock = data.content?.find((block: any) => block.type === 'text');
      const text = textBlock?.text || '{}';
      // Clean up markdown block if present
      const cleaned = text.replace(/```json\s*/i, '').replace(/```\s*$/, '').trim();
      return JSON.parse(cleaned) as T;
    }

    // Default OpenAI completion
    const messages: any[] = [];
    if (systemInstruction) {
      messages.push({ role: 'system', content: systemInstruction });
    }
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
