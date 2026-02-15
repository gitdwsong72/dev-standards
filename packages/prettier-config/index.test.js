import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const config = JSON.parse(readFileSync(join(__dirname, 'index.json'), 'utf-8'));

describe('Prettier Config', () => {
  it('uses single quotes', () => {
    assert.strictEqual(config.singleQuote, true);
  });

  it('uses 2-space indentation (no tabs)', () => {
    assert.strictEqual(config.tabWidth, 2);
    assert.strictEqual(config.useTabs, false);
  });

  it('uses trailing commas everywhere', () => {
    assert.strictEqual(config.trailingComma, 'all');
  });

  it('uses semicolons', () => {
    assert.strictEqual(config.semi, true);
  });

  it('sets print width to 100', () => {
    assert.strictEqual(config.printWidth, 100);
  });

  it('enables bracket spacing', () => {
    assert.strictEqual(config.bracketSpacing, true);
  });

  it('disables bracket same line', () => {
    assert.strictEqual(config.bracketSameLine, false);
  });

  it('always uses arrow function parentheses', () => {
    assert.strictEqual(config.arrowParens, 'always');
  });

  it('uses LF line endings', () => {
    assert.strictEqual(config.endOfLine, 'lf');
  });

  it('uses as-needed quote props', () => {
    assert.strictEqual(config.quoteProps, 'as-needed');
  });

  it('does not use single quotes in JSX', () => {
    assert.strictEqual(config.jsxSingleQuote, false);
  });

  it('places single attribute per line', () => {
    assert.strictEqual(config.singleAttributePerLine, true);
  });

  it('preserves prose wrap', () => {
    assert.strictEqual(config.proseWrap, 'preserve');
  });

  it('uses css html whitespace sensitivity', () => {
    assert.strictEqual(config.htmlWhitespaceSensitivity, 'css');
  });

  it('auto-formats embedded languages', () => {
    assert.strictEqual(config.embeddedLanguageFormatting, 'auto');
  });

  it('contains exactly 16 configuration keys', () => {
    const expectedKeys = [
      'semi',
      'singleQuote',
      'tabWidth',
      'trailingComma',
      'printWidth',
      'bracketSpacing',
      'bracketSameLine',
      'arrowParens',
      'endOfLine',
      'useTabs',
      'quoteProps',
      'jsxSingleQuote',
      'singleAttributePerLine',
      'proseWrap',
      'htmlWhitespaceSensitivity',
      'embeddedLanguageFormatting',
    ];
    const actualKeys = Object.keys(config);
    assert.strictEqual(actualKeys.length, expectedKeys.length);
    for (const key of expectedKeys) {
      assert.ok(key in config, `Missing expected key: ${key}`);
    }
  });
});
