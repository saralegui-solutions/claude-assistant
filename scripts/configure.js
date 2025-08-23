#!/usr/bin/env node

import readline from 'readline';
import ConfigManager from './lib/config-manager.js';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const question = (prompt) => new Promise(resolve => rl.question(prompt, resolve));

async function main() {
  const configManager = new ConfigManager();
  
  console.log('Claude Assistant Configuration\n');
  console.log('This will set up a profile for your Anthropic API key.');
  console.log('Profiles allow multiple projects to use different API keys without conflicts.\n');

  const action = await question('Choose an action:\n1. Add new profile\n2. List profiles\n3. Set default profile\n4. Exit\n\nChoice: ');

  switch(action.trim()) {
    case '1':
      await addProfile(configManager);
      break;
    case '2':
      listProfiles(configManager);
      break;
    case '3':
      await setDefault(configManager);
      break;
    default:
      console.log('Exiting...');
  }

  rl.close();
}

async function addProfile(configManager) {
  const profileName = await question('\nProfile name (e.g., personal, work, project-x): ');
  const apiKey = await question('Anthropic API key: ');
  const model = await question('Model (press Enter for default claude-3-5-sonnet-20241022): ');
  
  try {
    await configManager.saveProfile(profileName.trim(), apiKey.trim(), {
      model: model.trim() || undefined
    });
    
    console.log(`\n✓ Profile '${profileName}' saved successfully!`);
    console.log('\nTo use this profile in a project, either:');
    console.log(`1. Set environment variable: export CLAUDE_PROFILE=${profileName}`);
    console.log(`2. Add to project's config/claude-assistant.config.json:`);
    console.log(`   { "profile": "${profileName}" }`);
  } catch (error) {
    console.error('\nError saving profile:', error.message);
  }
}

function listProfiles(configManager) {
  const profiles = configManager.listProfiles();
  
  if (profiles.length === 0) {
    console.log('\nNo profiles configured yet.');
    console.log('Run this tool with option 1 to add a profile.');
  } else {
    console.log('\nConfigured profiles:');
    profiles.forEach(profile => console.log(`  - ${profile}`));
  }
}

async function setDefault(configManager) {
  const profiles = configManager.listProfiles();
  
  if (profiles.length === 0) {
    console.log('\nNo profiles available. Please add a profile first.');
    return;
  }
  
  console.log('\nAvailable profiles:');
  profiles.forEach((profile, index) => console.log(`${index + 1}. ${profile}`));
  
  const choice = await question('\nSelect profile number: ');
  const index = parseInt(choice) - 1;
  
  if (index >= 0 && index < profiles.length) {
    configManager.setDefaultProfile(profiles[index]);
    console.log(`\n✓ Default profile set to '${profiles[index]}'`);
  } else {
    console.log('\nInvalid selection.');
  }
}

main().catch(console.error);