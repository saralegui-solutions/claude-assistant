#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import ModelUpdater from './lib/model-updater.js';
import ConfigManager from './lib/config-manager.js';

const args = process.argv.slice(2);
const silent = args.includes('--silent');
const force = args.includes('--force');

async function checkAndUpdate() {
  const updaterConfigPath = path.join(process.env.HOME, '.claude-assistant', 'updater.json');
  
  if (!fs.existsSync(updaterConfigPath) && !force) {
    if (!silent) {
      console.log('Model updater not configured. Run: npm run setup');
    }
    return;
  }
  
  let config = { enabled: true, autoCommit: false };
  
  if (fs.existsSync(updaterConfigPath)) {
    config = JSON.parse(fs.readFileSync(updaterConfigPath, 'utf8'));
  }
  
  if (!config.enabled && !force) {
    return;
  }
  
  const lastCheckFile = path.join(process.env.HOME, '.claude-assistant', '.last-update-check');
  
  if (!force && fs.existsSync(lastCheckFile)) {
    const lastCheck = fs.readFileSync(lastCheckFile, 'utf8');
    const lastCheckTime = new Date(lastCheck);
    const now = new Date();
    const hoursSinceLastCheck = (now - lastCheckTime) / (1000 * 60 * 60);
    
    if (hoursSinceLastCheck < 24) {
      if (!silent) {
        console.log('Model check already performed in the last 24 hours. Use --force to check anyway.');
      }
      return;
    }
  }
  
  const updater = new ModelUpdater();
  
  try {
    const configManager = new ConfigManager();
    const apiConfig = configManager.loadConfig();
    
    if (apiConfig.apiKey) {
      await updater.fetchLatestModels(apiConfig.apiKey);
    }
  } catch (error) {
    if (!silent) {
      console.log('Could not fetch latest models from API, using cached list');
    }
  }
  
  const updates = await updater.checkForUpdates();
  
  if (updates.length === 0) {
    if (!silent) {
      console.log('✓ All Claude models are up to date');
    }
    
    fs.writeFileSync(lastCheckFile, new Date().toISOString());
    return;
  }
  
  if (silent) {
    console.log('\n🔄 Claude Assistant: Deprecated models detected');
    console.log('Run "node check-updates.js" to view and apply updates\n');
    return;
  }
  
  console.log('\n🔄 Model Update Check');
  console.log('─'.repeat(40));
  console.log('\nFound deprecated models that need updating:');
  
  updates.forEach(update => {
    console.log(`\n📁 ${update.file}${update.line ? `:${update.line}` : ''}`);
    console.log(`   ${update.oldModel} → ${update.newModel}`);
  });
  
  console.log('\n' + '─'.repeat(40));
  
  if (!process.stdin.isTTY) {
    console.log('Non-interactive mode. Run manually to apply updates.');
    return;
  }
  
  const readline = await import('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  
  const answer = await new Promise(resolve => {
    rl.question('Apply these updates? (Y/n): ', resolve);
  });
  
  rl.close();
  
  if (answer.toLowerCase() !== 'n') {
    await updater.applyUpdates(updates, config.autoCommit);
    console.log('\n✅ All models have been updated successfully!');
    
    if (config.autoCommit && updater.isGitRepo()) {
      console.log('✅ Changes have been committed and pushed to git');
    }
  } else {
    console.log('Update cancelled. Your models remain unchanged.');
  }
  
  fs.writeFileSync(lastCheckFile, new Date().toISOString());
}

checkAndUpdate().catch(error => {
  if (!silent) {
    console.error('Error checking for updates:', error.message);
  }
  process.exit(1);
});