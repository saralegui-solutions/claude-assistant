import Anthropic from '@anthropic-ai/sdk';
import readline from 'readline';
import ConfigManager from './lib/config-manager.js';

const configManager = new ConfigManager();
let config;

try {
  config = configManager.loadConfig();
  console.log(`Using API key from: ${config.source}${config.profile ? ` (profile: ${config.profile})` : ''}`);
} catch (error) {
  console.error('Configuration error:', error.message);
  process.exit(1);
}

const anthropic = new Anthropic({
  apiKey: config.apiKey,
});

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

class ClaudeAssistant {
  constructor(modelOverride = null) {
    this.conversationHistory = [];
    this.model = modelOverride || config.model || 'claude-3-5-sonnet-20241022';
  }

  async sendMessage(userMessage) {
    try {
      this.conversationHistory.push({ role: 'user', content: userMessage });
      
      const response = await anthropic.messages.create({
        model: this.model,
        max_tokens: 1024,
        messages: this.conversationHistory,
      });

      const assistantMessage = response.content[0].text;
      this.conversationHistory.push({ role: 'assistant', content: assistantMessage });
      
      return assistantMessage;
    } catch (error) {
      console.error('Error communicating with Claude:', error.message);
      return 'Sorry, I encountered an error. Please check your API key and try again.';
    }
  }

  clearHistory() {
    this.conversationHistory = [];
    console.log('Conversation history cleared.');
  }
}

async function main() {
  console.log('Claude Assistant initialized!');
  console.log('Type "exit" to quit, "clear" to reset conversation history.\n');

  const assistant = new ClaudeAssistant();

  const askQuestion = () => {
    rl.question('You: ', async (input) => {
      if (input.toLowerCase() === 'exit') {
        console.log('Goodbye!');
        rl.close();
        process.exit(0);
      }
      
      if (input.toLowerCase() === 'clear') {
        assistant.clearHistory();
        askQuestion();
        return;
      }

      console.log('\nClaude: Thinking...');
      const response = await assistant.sendMessage(input);
      console.log(`Claude: ${response}\n`);
      
      askQuestion();
    });
  };

  askQuestion();
}

main();