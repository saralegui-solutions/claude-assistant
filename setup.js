#!/usr/bin/env node

import readline from 'readline';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import ConfigManager from './lib/config-manager.js';
import ModelUpdater from './lib/model-updater.js';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const question = (prompt) => new Promise(resolve => rl.question(prompt, resolve));

function printHeader() {
  console.clear();
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║         Claude Assistant - Complete Setup Wizard          ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log();
}

async function setupApiKeys() {
  console.log('📋 API Keys Configuration');
  console.log('─'.repeat(60));
  console.log();
  
  const configManager = new ConfigManager();
  
  console.log('This assistant can use multiple API keys through profiles.');
  console.log('You can set up different profiles for different projects.\n');
  
  const profiles = [];
  let addMore = true;
  
  while (addMore) {
    const profileName = await question(`Profile name (e.g., ${profiles.length === 0 ? 'default' : 'work, personal'}): `);
    
    if (!profileName.trim()) {
      if (profiles.length === 0) {
        console.log('❌ At least one profile is required.');
        continue;
      }
      break;
    }
    
    console.log(`\nSetting up profile: ${profileName}`);
    const apiKey = await question('Anthropic API Key (sk-ant-...): ');
    
    if (!apiKey.trim() || !apiKey.startsWith('sk-ant-')) {
      console.log('❌ Invalid API key format. Please enter a valid Anthropic API key.');
      continue;
    }
    
    const useCustomModel = await question('Use custom model? (y/N): ');
    let model = 'claude-3-5-sonnet-20241022';
    
    if (useCustomModel.toLowerCase() === 'y') {
      console.log('\nAvailable models:');
      console.log('1. claude-3-5-sonnet-20241022 (default, most capable)');
      console.log('2. claude-3-5-haiku-20241022 (faster, cheaper)');
      console.log('3. claude-3-opus-20240229 (previous flagship)');
      console.log('4. Custom model ID');
      
      const modelChoice = await question('Choice (1-4): ');
      
      switch(modelChoice) {
        case '2':
          model = 'claude-3-5-haiku-20241022';
          break;
        case '3':
          model = 'claude-3-opus-20240229';
          break;
        case '4':
          model = await question('Enter model ID: ');
          break;
      }
    }
    
    await configManager.saveProfile(profileName.trim(), apiKey.trim(), { model });
    profiles.push(profileName.trim());
    
    console.log(`✓ Profile '${profileName}' saved\n`);
    
    if (profiles.length === 1) {
      const addAnother = await question('Add another profile? (y/N): ');
      addMore = addAnother.toLowerCase() === 'y';
    } else {
      addMore = false;
    }
  }
  
  if (profiles.length > 0) {
    const defaultProfile = profiles[0];
    configManager.setDefaultProfile(defaultProfile);
    console.log(`\n✓ Set '${defaultProfile}' as default profile`);
  }
  
  return profiles;
}

async function setupPushover() {
  console.log('\n📱 Pushover Notifications (Optional)');
  console.log('─'.repeat(60));
  console.log('\nPushover enables mobile notifications for long-running tasks.');
  
  const setup = await question('Configure Pushover notifications? (y/N): ');
  
  if (setup.toLowerCase() === 'y') {
    const userKey = await question('Pushover User Key: ');
    const appToken = await question('Pushover App Token: ');
    
    if (userKey && appToken) {
      const configPath = path.join(process.env.HOME, '.pushover_config');
      const config = `USER_KEY="${userKey}"
APP_TOKEN="${appToken}"
`;
      fs.writeFileSync(configPath, config);
      fs.chmodSync(configPath, 0o600);
      console.log('✓ Pushover configured');
      return true;
    }
  }
  
  console.log('⏩ Skipping Pushover setup');
  return false;
}

async function setupModelUpdater() {
  console.log('\n🔄 Automatic Model Updates');
  console.log('─'.repeat(60));
  console.log('\nThis will check for deprecated models and update them automatically.');
  
  const enable = await question('Enable automatic model updates? (Y/n): ');
  
  if (enable.toLowerCase() !== 'n') {
    const autoCommit = await question('Auto-commit and push updates to git? (y/N): ');
    
    const config = {
      enabled: true,
      autoCommit: autoCommit.toLowerCase() === 'y',
      checkOnStartup: true
    };
    
    const configPath = path.join(process.env.HOME, '.claude-assistant', 'updater.json');
    const configDir = path.dirname(configPath);
    
    if (!fs.existsSync(configDir)) {
      fs.mkdirSync(configDir, { recursive: true });
    }
    
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    console.log('✓ Model updater configured');
    
    return config;
  }
  
  console.log('⏩ Skipping model updater setup');
  return null;
}

async function installStartupHooks() {
  console.log('\n🚀 Startup Hooks Installation');
  console.log('─'.repeat(60));
  console.log('\nThis will add startup checks to your shell configuration.');
  
  const install = await question('Install startup hooks? (Y/n): ');
  
  if (install.toLowerCase() !== 'n') {
    const hookScript = `
# Claude Assistant Auto-Update Check
if [ -f "$HOME/.claude-assistant/updater.json" ]; then
  if [ -f "${process.cwd()}/check-updates.js" ]; then
    node ${process.cwd()}/check-updates.js --silent 2>/dev/null &
  fi
fi
`;
    
    const shells = ['.bashrc', '.zshrc'];
    let installed = false;
    
    for (const shellConfig of shells) {
      const configPath = path.join(process.env.HOME, shellConfig);
      if (fs.existsSync(configPath)) {
        const content = fs.readFileSync(configPath, 'utf8');
        
        if (!content.includes('Claude Assistant Auto-Update Check')) {
          fs.appendFileSync(configPath, hookScript);
          console.log(`✓ Added startup hook to ${shellConfig}`);
          installed = true;
        } else {
          console.log(`⏩ Hook already exists in ${shellConfig}`);
        }
      }
    }
    
    if (!installed) {
      console.log('⚠️  No shell configuration found. Please add the hook manually.');
    }
    
    return installed;
  }
  
  console.log('⏩ Skipping startup hooks');
  return false;
}

async function runInitialModelCheck() {
  console.log('\n🔍 Checking for Deprecated Models');
  console.log('─'.repeat(60));
  
  const updater = new ModelUpdater();
  const updates = await updater.checkForUpdates();
  
  if (updates.length > 0) {
    console.log('\nFound deprecated models:');
    updates.forEach(u => {
      console.log(`  ${u.file}:${u.line} - ${u.oldModel} → ${u.newModel}`);
    });
    
    const apply = await question('\nApply these updates? (Y/n): ');
    
    if (apply.toLowerCase() !== 'n') {
      const configPath = path.join(process.env.HOME, '.claude-assistant', 'updater.json');
      let autoCommit = false;
      
      if (fs.existsSync(configPath)) {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        autoCommit = config.autoCommit;
      }
      
      await updater.applyUpdates(updates, autoCommit);
      console.log('\n✓ All models updated');
    }
  } else {
    console.log('✓ All models are up to date');
  }
}

async function main() {
  printHeader();
  
  try {
    console.log('This wizard will help you set up:');
    console.log('  • API key profiles for multiple projects');
    console.log('  • Optional Pushover notifications');
    console.log('  • Automatic model version updates');
    console.log('  • Shell startup hooks\n');
    
    const continueSetup = await question('Continue with setup? (Y/n): ');
    
    if (continueSetup.toLowerCase() === 'n') {
      console.log('\nSetup cancelled.');
      rl.close();
      return;
    }
    
    console.log();
    
    const profiles = await setupApiKeys();
    
    if (profiles.length === 0) {
      console.log('\n❌ No profiles configured. Setup incomplete.');
      rl.close();
      return;
    }
    
    const pushover = await setupPushover();
    const modelUpdater = await setupModelUpdater();
    const startupHooks = await installStartupHooks();
    
    await runInitialModelCheck();
    
    console.log('\n' + '═'.repeat(60));
    console.log('✅ Setup Complete!');
    console.log('═'.repeat(60));
    
    console.log('\n📝 Summary:');
    console.log(`  • Profiles configured: ${profiles.join(', ')}`);
    console.log(`  • Pushover: ${pushover ? 'Enabled' : 'Disabled'}`);
    console.log(`  • Model updater: ${modelUpdater ? 'Enabled' : 'Disabled'}`);
    console.log(`  • Startup hooks: ${startupHooks ? 'Installed' : 'Not installed'}`);
    
    console.log('\n🚀 Quick Start:');
    console.log('  npm start                      # Use default profile');
    console.log('  CLAUDE_PROFILE=work npm start  # Use specific profile');
    console.log('  npm run configure              # Manage profiles');
    console.log('  node check-updates.js          # Check for model updates');
    
    console.log('\n💡 Tips:');
    console.log('  • Your API keys are stored securely in ~/.claude-assistant/config.json');
    console.log('  • Model updates will run automatically on shell startup');
    console.log('  • Use different profiles for different projects to avoid conflicts');
    
  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
  } finally {
    rl.close();
  }
}

main().catch(console.error);