import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import baseConfig from './index.js';
import reactConfig from './react.js';

describe('ESLint Base Config', () => {
  it('exports an array of config objects', () => {
    assert.ok(Array.isArray(baseConfig));
    assert.ok(baseConfig.length > 0);
  });

  it('includes config objects with rules', () => {
    const configWithRules = baseConfig.find((c) => c.rules);
    assert.ok(configWithRules, 'Should have a config object with rules');
  });

  it('enforces prefer-const rule as error', () => {
    const rulesConfig = baseConfig.find((c) => c.rules?.['prefer-const']);
    assert.ok(rulesConfig, 'Should have prefer-const rule');
    assert.strictEqual(rulesConfig.rules['prefer-const'], 'error');
  });

  it('enforces no-var rule as error', () => {
    const rulesConfig = baseConfig.find((c) => c.rules?.['no-var']);
    assert.ok(rulesConfig);
    assert.strictEqual(rulesConfig.rules['no-var'], 'error');
  });

  it('enforces eqeqeq as error with always option', () => {
    const rulesConfig = baseConfig.find((c) => c.rules?.['eqeqeq']);
    assert.ok(rulesConfig);
    assert.deepStrictEqual(rulesConfig.rules['eqeqeq'], ['error', 'always']);
  });

  it('warns on no-console with warn/error exceptions', () => {
    const rulesConfig = baseConfig.find((c) => c.rules?.['no-console']);
    assert.ok(rulesConfig, 'Should have no-console rule');
    const rule = rulesConfig.rules['no-console'];
    assert.ok(Array.isArray(rule));
    assert.strictEqual(rule[0], 'warn');
    assert.deepStrictEqual(rule[1], { allow: ['warn', 'error'] });
  });

  it('includes security plugin rules', () => {
    const rulesConfig = baseConfig.find(
      (c) => c.rules?.['security/detect-eval-with-expression'],
    );
    assert.ok(rulesConfig, 'Should have security plugin rules');
    assert.strictEqual(rulesConfig.rules['security/detect-eval-with-expression'], 'error');
    assert.strictEqual(rulesConfig.rules['security/detect-unsafe-regex'], 'error');
    assert.strictEqual(rulesConfig.rules['security/detect-buffer-noassert'], 'error');
    assert.strictEqual(rulesConfig.rules['security/detect-pseudoRandomBytes'], 'error');
    assert.strictEqual(rulesConfig.rules['security/detect-bidi-characters'], 'error');
  });

  it('disables security/detect-object-injection (too many false positives)', () => {
    const rulesConfig = baseConfig.find(
      (c) => c.rules?.['security/detect-object-injection'] !== undefined,
    );
    assert.ok(rulesConfig);
    assert.strictEqual(rulesConfig.rules['security/detect-object-injection'], 'off');
  });

  it('includes import-x plugin rules', () => {
    const rulesConfig = baseConfig.find((c) => c.rules?.['import-x/no-cycle']);
    assert.ok(rulesConfig, 'Should have import-x rules');
    assert.strictEqual(rulesConfig.rules['import-x/no-cycle'], 'error');
    assert.strictEqual(rulesConfig.rules['import-x/no-duplicates'], 'error');
  });

  it('configures import-x/order with alphabetize and newlines', () => {
    const rulesConfig = baseConfig.find((c) => c.rules?.['import-x/order']);
    assert.ok(rulesConfig);
    const orderRule = rulesConfig.rules['import-x/order'];
    assert.ok(Array.isArray(orderRule));
    assert.strictEqual(orderRule[0], 'error');
    assert.strictEqual(orderRule[1]['newlines-between'], 'always');
    assert.deepStrictEqual(orderRule[1].alphabetize, {
      order: 'asc',
      caseInsensitive: true,
    });
  });

  it('enforces no-eval, no-implied-eval, no-new-func as error', () => {
    const rulesConfig = baseConfig.find((c) => c.rules?.['no-eval']);
    assert.ok(rulesConfig);
    assert.strictEqual(rulesConfig.rules['no-eval'], 'error');
    assert.strictEqual(rulesConfig.rules['no-implied-eval'], 'error');
    assert.strictEqual(rulesConfig.rules['no-new-func'], 'error');
  });

  it('overrides @typescript-eslint/no-explicit-any to warn', () => {
    // The custom config block (last one with this rule) overrides the recommended preset
    const configsWithRule = baseConfig.filter(
      (c) => c.rules?.['@typescript-eslint/no-explicit-any'] !== undefined,
    );
    assert.ok(configsWithRule.length > 0);
    const lastConfig = configsWithRule[configsWithRule.length - 1];
    assert.strictEqual(lastConfig.rules['@typescript-eslint/no-explicit-any'], 'warn');
  });

  it('has ignores configuration for common directories', () => {
    const ignoresConfig = baseConfig.find((c) => c.ignores && !c.rules);
    assert.ok(ignoresConfig, 'Should have ignores config');
    assert.ok(ignoresConfig.ignores.includes('node_modules/'));
    assert.ok(ignoresConfig.ignores.includes('dist/'));
    assert.ok(ignoresConfig.ignores.includes('build/'));
  });

  it('includes security and import-x plugins', () => {
    const pluginsConfig = baseConfig.find(
      (c) => c.plugins?.['import-x'] && c.plugins?.security,
    );
    assert.ok(pluginsConfig, 'Should have both import-x and security plugins');
  });

  it('sets languageOptions with node and es2024 globals', () => {
    const langConfig = baseConfig.find((c) => c.languageOptions?.globals);
    assert.ok(langConfig, 'Should have languageOptions with globals');
    assert.strictEqual(langConfig.languageOptions.sourceType, 'module');
    assert.strictEqual(langConfig.languageOptions.ecmaVersion, 'latest');
  });
});

describe('ESLint React Config', () => {
  it('exports an array of config objects', () => {
    assert.ok(Array.isArray(reactConfig));
    assert.ok(reactConfig.length > 0);
  });

  it('extends base config (has more entries)', () => {
    assert.ok(
      reactConfig.length > baseConfig.length,
      'React config should have more entries than base config',
    );
  });

  it('includes react plugin rules', () => {
    const reactRulesConfig = reactConfig.find((c) => c.rules?.['react/jsx-key']);
    assert.ok(reactRulesConfig, 'Should have react rules');
    assert.strictEqual(reactRulesConfig.rules['react/jsx-key'], 'error');
    assert.strictEqual(reactRulesConfig.rules['react/self-closing-comp'], 'error');
    assert.strictEqual(reactRulesConfig.rules['react/prop-types'], 'off');
    assert.strictEqual(reactRulesConfig.rules['react/react-in-jsx-scope'], 'off');
  });

  it('includes react-hooks rules', () => {
    const hooksConfig = reactConfig.find(
      (c) => c.rules?.['react-hooks/rules-of-hooks'],
    );
    assert.ok(hooksConfig, 'Should have react-hooks rules');
    assert.strictEqual(hooksConfig.rules['react-hooks/rules-of-hooks'], 'error');
    assert.strictEqual(hooksConfig.rules['react-hooks/exhaustive-deps'], 'warn');
  });

  it('includes react security rules', () => {
    const securityConfig = reactConfig.find(
      (c) => c.rules?.['react/jsx-no-script-url'],
    );
    assert.ok(securityConfig, 'Should have react security rules');
    assert.strictEqual(securityConfig.rules['react/jsx-no-script-url'], 'error');
    assert.strictEqual(securityConfig.rules['react/jsx-no-target-blank'], 'error');
    assert.strictEqual(securityConfig.rules['react/no-danger'], 'warn');
  });

  it('targets JSX/TSX files', () => {
    const filesConfig = reactConfig.find((c) => c.files);
    assert.ok(filesConfig, 'Should have files pattern');
    assert.ok(
      filesConfig.files.some((f) => f.includes('jsx') || f.includes('tsx')),
    );
  });

  it('includes react and react-hooks plugins', () => {
    const pluginsConfig = reactConfig.find(
      (c) => c.plugins?.react && c.plugins?.['react-hooks'],
    );
    assert.ok(pluginsConfig, 'Should have react and react-hooks plugins');
  });

  it('enables JSX in parser options', () => {
    const langConfig = reactConfig.find(
      (c) => c.languageOptions?.parserOptions?.ecmaFeatures?.jsx,
    );
    assert.ok(langConfig, 'Should enable JSX parsing');
  });

  it('includes browser globals', () => {
    const langConfig = reactConfig.find((c) => c.languageOptions?.globals);
    // The react config has browser globals in its own block
    const reactLangConfig = reactConfig.find(
      (c) => c.plugins?.react && c.languageOptions?.globals,
    );
    assert.ok(reactLangConfig, 'Should have browser globals in react config');
  });

  it('auto-detects React version', () => {
    const settingsConfig = reactConfig.find((c) => c.settings?.react?.version);
    assert.ok(settingsConfig, 'Should have react version setting');
    assert.strictEqual(settingsConfig.settings.react.version, 'detect');
  });
});
