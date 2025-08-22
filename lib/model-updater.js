import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

class ModelUpdater {
  constructor() {
    this.modelsApiUrl = 'https://api.anthropic.com/v1/models';
    this.deprecatedModels = new Set([
      'claude-2',
      'claude-2.0',
      'claude-2.1',
      'claude-instant-1',
      'claude-instant-1.0',
      'claude-instant-1.1',
      'claude-instant-1.2',
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
      'claude-3-haiku-20240307'
    ]);
    
    this.modelMappings = {
      'claude-3-opus-20240229': 'claude-3-5-sonnet-20241022',
      'claude-3-sonnet-20240229': 'claude-3-5-sonnet-20241022',
      'claude-3-haiku-20240307': 'claude-3-5-haiku-20241022',
      'claude-2': 'claude-3-5-sonnet-20241022',
      'claude-2.0': 'claude-3-5-sonnet-20241022',
      'claude-2.1': 'claude-3-5-sonnet-20241022',
      'claude-instant-1': 'claude-3-5-haiku-20241022',
      'claude-instant-1.0': 'claude-3-5-haiku-20241022',
      'claude-instant-1.1': 'claude-3-5-haiku-20241022',
      'claude-instant-1.2': 'claude-3-5-haiku-20241022'
    };
    
    this.latestModels = {
      'sonnet': 'claude-3-5-sonnet-20241022',
      'haiku': 'claude-3-5-haiku-20241022',
      'opus': 'claude-3-opus-20240229'
    };
  }

  async checkForUpdates() {
    const filesToCheck = [
      'index.js',
      'config/claude-assistant.config.json',
      '.env',
      '.env.example'
    ];
    
    const updates = [];
    
    for (const file of filesToCheck) {
      const filePath = path.join(process.cwd(), file);
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        const foundModels = this.findModelsInContent(content);
        
        for (const model of foundModels) {
          if (this.deprecatedModels.has(model)) {
            updates.push({
              file,
              oldModel: model,
              newModel: this.modelMappings[model] || this.latestModels.sonnet,
              line: this.findLineNumber(content, model)
            });
          }
        }
      }
    }
    
    const globalConfigPath = path.join(process.env.HOME, '.claude-assistant', 'config.json');
    if (fs.existsSync(globalConfigPath)) {
      const content = fs.readFileSync(globalConfigPath, 'utf8');
      const foundModels = this.findModelsInContent(content);
      
      for (const model of foundModels) {
        if (this.deprecatedModels.has(model)) {
          updates.push({
            file: globalConfigPath,
            oldModel: model,
            newModel: this.modelMappings[model] || this.latestModels.sonnet,
            line: this.findLineNumber(content, model)
          });
        }
      }
    }
    
    return updates;
  }

  findModelsInContent(content) {
    const modelPattern = /claude-[\w\d.-]+/g;
    const matches = content.match(modelPattern) || [];
    return [...new Set(matches)];
  }

  findLineNumber(content, searchString) {
    const lines = content.split('\n');
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes(searchString)) {
        return i + 1;
      }
    }
    return null;
  }

  async applyUpdates(updates, autoCommit = false) {
    const fileChanges = {};
    
    for (const update of updates) {
      if (!fileChanges[update.file]) {
        fileChanges[update.file] = fs.readFileSync(
          update.file.startsWith('/') ? update.file : path.join(process.cwd(), update.file),
          'utf8'
        );
      }
      
      fileChanges[update.file] = fileChanges[update.file].replace(
        new RegExp(update.oldModel, 'g'),
        update.newModel
      );
    }
    
    for (const [file, content] of Object.entries(fileChanges)) {
      const filePath = file.startsWith('/') ? file : path.join(process.cwd(), file);
      fs.writeFileSync(filePath, content);
      console.log(`✓ Updated ${file}`);
    }
    
    if (autoCommit && this.isGitRepo()) {
      try {
        const changedFiles = Object.keys(fileChanges)
          .filter(f => !f.startsWith('/'))
          .join(' ');
        
        if (changedFiles) {
          execSync(`git add ${changedFiles}`, { stdio: 'pipe' });
          
          const commitMessage = `chore: Update deprecated Claude models to latest versions

Updated models:
${updates.map(u => `- ${u.oldModel} → ${u.newModel}`).join('\n')}

Auto-updated by claude-assistant model updater`;
          
          execSync(`git commit -m "${commitMessage}"`, { stdio: 'pipe' });
          console.log('✓ Changes committed');
          
          const currentBranch = execSync('git branch --show-current', { encoding: 'utf8' }).trim();
          execSync(`git push origin ${currentBranch}`, { stdio: 'pipe' });
          console.log('✓ Changes pushed to remote');
        }
      } catch (error) {
        console.error('Warning: Could not auto-commit changes:', error.message);
        console.log('Please commit the changes manually.');
      }
    }
    
    return true;
  }

  isGitRepo() {
    try {
      execSync('git rev-parse --git-dir', { stdio: 'pipe' });
      return true;
    } catch {
      return false;
    }
  }

  async fetchLatestModels(apiKey) {
    try {
      const response = await fetch(this.modelsApiUrl, {
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01'
        }
      });
      
      if (response.ok) {
        const data = await response.json();
        if (data.data) {
          const models = data.data.map(m => m.id);
          this.updateLatestModels(models);
        }
      }
    } catch (error) {
      console.log('Could not fetch latest models from API, using cached list');
    }
  }

  updateLatestModels(models) {
    for (const model of models) {
      if (model.includes('sonnet') && !this.deprecatedModels.has(model)) {
        this.latestModels.sonnet = model;
      } else if (model.includes('haiku') && !this.deprecatedModels.has(model)) {
        this.latestModels.haiku = model;
      } else if (model.includes('opus') && !this.deprecatedModels.has(model)) {
        this.latestModels.opus = model;
      }
    }
  }
}

export default ModelUpdater;