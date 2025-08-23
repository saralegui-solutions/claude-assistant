import fs from 'fs';
import path from 'path';
import os from 'os';
import dotenv from 'dotenv';

class ConfigManager {
  constructor() {
    this.globalConfigPath = path.join(os.homedir(), '.claude-assistant', 'config.json');
    this.localConfigPath = path.join(process.cwd(), 'config', 'claude-assistant.config.json');
    this.config = null;
  }

  loadConfig() {
    dotenv.config();
    
    const profile = process.env.CLAUDE_PROFILE || 'default';
    
    if (process.env.ANTHROPIC_API_KEY) {
      return {
        apiKey: process.env.ANTHROPIC_API_KEY,
        model: process.env.CLAUDE_MODEL || 'claude-3-5-sonnet-20241022',
        source: 'environment'
      };
    }
    
    const globalConfig = this.loadGlobalConfig();
    if (globalConfig && globalConfig.profiles && globalConfig.profiles[profile]) {
      return {
        ...globalConfig.profiles[profile],
        source: 'global-profile',
        profile
      };
    }
    
    const localConfig = this.loadLocalConfig();
    if (localConfig && localConfig.profile) {
      const profileConfig = globalConfig?.profiles?.[localConfig.profile];
      if (profileConfig) {
        return {
          ...profileConfig,
          ...localConfig.overrides,
          source: 'local-profile',
          profile: localConfig.profile
        };
      }
    }
    
    if (localConfig && localConfig.apiKey) {
      console.warn('Warning: Using API key from local config. Consider using profiles instead.');
      return {
        ...localConfig,
        source: 'local-direct'
      };
    }
    
    throw new Error('No API key found. Please configure using one of:\n' +
      '1. Set ANTHROPIC_API_KEY environment variable\n' +
      '2. Run: claude-assistant configure\n' +
      '3. Create ~/.claude-assistant/config.json with profiles');
  }

  loadGlobalConfig() {
    try {
      if (fs.existsSync(this.globalConfigPath)) {
        return JSON.parse(fs.readFileSync(this.globalConfigPath, 'utf8'));
      }
    } catch (error) {
      console.error('Error loading global config:', error.message);
    }
    return null;
  }

  loadLocalConfig() {
    try {
      if (fs.existsSync(this.localConfigPath)) {
        return JSON.parse(fs.readFileSync(this.localConfigPath, 'utf8'));
      }
    } catch (error) {
      console.error('Error loading local config:', error.message);
    }
    return null;
  }

  async saveProfile(profileName, apiKey, options = {}) {
    const configDir = path.dirname(this.globalConfigPath);
    if (!fs.existsSync(configDir)) {
      fs.mkdirSync(configDir, { recursive: true });
    }

    let config = this.loadGlobalConfig() || { profiles: {} };
    
    config.profiles[profileName] = {
      apiKey,
      model: options.model || 'claude-3-5-sonnet-20241022',
      ...options
    };

    fs.writeFileSync(this.globalConfigPath, JSON.stringify(config, null, 2));
    fs.chmodSync(this.globalConfigPath, 0o600);
    
    return config;
  }

  listProfiles() {
    const config = this.loadGlobalConfig();
    if (!config || !config.profiles) {
      return [];
    }
    return Object.keys(config.profiles);
  }

  setDefaultProfile(profileName) {
    const config = this.loadGlobalConfig();
    if (!config || !config.profiles || !config.profiles[profileName]) {
      throw new Error(`Profile '${profileName}' not found`);
    }
    
    config.defaultProfile = profileName;
    fs.writeFileSync(this.globalConfigPath, JSON.stringify(config, null, 2));
  }
}

export default ConfigManager;