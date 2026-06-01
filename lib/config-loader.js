// lib/config-loader.js
const fs = require('fs');
const yaml = require('js-yaml');

const DEFAULT_CONFIG = {
  autonomy: {
    level: 1,
    overrides: []
  },
  subagent: {
    timeout: 300000,
    retry_count: 1
  },
  requirement_discovery: {
    enabled: true,
    min_questions: 4,
    max_questions: 6,
    allow_skip: true
  },
  hybrid_notes: {
    max_types: 2
  }
};

function loadConfig(configPath) {
  try {
    if (fs.existsSync(configPath)) {
      const content = fs.readFileSync(configPath, 'utf8');
      const userConfig = yaml.load(content);
      return mergeConfig(DEFAULT_CONFIG, userConfig);
    }
  } catch (e) {
    console.warn(`Failed to load config from ${configPath}:`, e.message);
  }
  return DEFAULT_CONFIG;
}

function mergeConfig(defaults, user) {
  const result = { ...defaults };
  for (const key of Object.keys(user || {})) {
    if (typeof defaults[key] === 'object' && !Array.isArray(defaults[key])) {
      result[key] = mergeConfig(defaults[key], user[key]);
    } else {
      result[key] = user[key];
    }
  }
  return result;
}

function getAutonomyLevel(config, phase) {
  const override = config.autonomy.overrides.find(o => o.phase === phase);
  return override ? override.level : config.autonomy.level;
}

function getSubagentTimeout(config) {
  return config.subagent.timeout;
}

module.exports = { loadConfig, getAutonomyLevel, getSubagentTimeout, DEFAULT_CONFIG };
