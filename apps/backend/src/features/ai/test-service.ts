import { aiService } from './ai.service';

console.log('--- STATS BEFORE ---');
console.log(aiService.getStats());

async function run() {
  try {
    console.log('\n--- TESTING GENERATE TEXT ---');
    const text = await aiService.generateText('Siapa kamu? Jawab dalam satu kata.');
    console.log('Response text:', text);

    console.log('\n--- TESTING GENERATE JSON ---');
    const schema = {
      type: 'object',
      properties: {
        estimated_calories: { type: 'integer' },
        estimated_sugar_grams: { type: 'number' },
        ai_feedback: { type: 'string' }
      },
      required: ['estimated_calories', 'estimated_sugar_grams', 'ai_feedback']
    };
    const json = await aiService.generateJSON('Saya makan nasi goreng tadi malam.', schema);
    console.log('Response JSON:', json);

    console.log('\n--- STATS AFTER ---');
    console.log(aiService.getStats());
  } catch (err) {
    console.error('Test failed:', err);
  }
}

run();
