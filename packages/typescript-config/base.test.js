import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const baseConfig = JSON.parse(readFileSync(join(__dirname, 'base.json'), 'utf-8'));
const reactConfig = JSON.parse(readFileSync(join(__dirname, 'react.json'), 'utf-8'));

describe('TypeScript Base Config', () => {
  const co = baseConfig.compilerOptions;

  it('has a valid JSON schema reference', () => {
    assert.strictEqual(baseConfig.$schema, 'https://json.schemastore.org/tsconfig');
  });

  it('targets ES2022', () => {
    assert.strictEqual(co.target, 'ES2022');
  });

  it('includes ES2022 lib', () => {
    assert.deepStrictEqual(co.lib, ['ES2022']);
  });

  it('uses ESNext module system', () => {
    assert.strictEqual(co.module, 'ESNext');
  });

  it('uses bundler module resolution', () => {
    assert.strictEqual(co.moduleResolution, 'bundler');
  });

  it('enables esModuleInterop', () => {
    assert.strictEqual(co.esModuleInterop, true);
  });

  it('enables allowSyntheticDefaultImports', () => {
    assert.strictEqual(co.allowSyntheticDefaultImports, true);
  });

  describe('strict mode settings', () => {
    it('enables strict mode', () => {
      assert.strictEqual(co.strict, true);
    });

    it('enables strictNullChecks', () => {
      assert.strictEqual(co.strictNullChecks, true);
    });

    it('enables noImplicitAny', () => {
      assert.strictEqual(co.noImplicitAny, true);
    });

    it('enables noImplicitReturns', () => {
      assert.strictEqual(co.noImplicitReturns, true);
    });

    it('enables noUnusedLocals', () => {
      assert.strictEqual(co.noUnusedLocals, true);
    });

    it('enables noUnusedParameters', () => {
      assert.strictEqual(co.noUnusedParameters, true);
    });

    it('enables noFallthroughCasesInSwitch', () => {
      assert.strictEqual(co.noFallthroughCasesInSwitch, true);
    });

    it('enables noUncheckedIndexedAccess', () => {
      assert.strictEqual(co.noUncheckedIndexedAccess, true);
    });

    it('enables exactOptionalPropertyTypes', () => {
      assert.strictEqual(co.exactOptionalPropertyTypes, true);
    });
  });

  it('enables skipLibCheck', () => {
    assert.strictEqual(co.skipLibCheck, true);
  });

  it('enables resolveJsonModule', () => {
    assert.strictEqual(co.resolveJsonModule, true);
  });

  it('enables isolatedModules', () => {
    assert.strictEqual(co.isolatedModules, true);
  });

  it('enables verbatimModuleSyntax', () => {
    assert.strictEqual(co.verbatimModuleSyntax, true);
  });

  it('forces consistent casing in file names', () => {
    assert.strictEqual(co.forceConsistentCasingInFileNames, true);
  });

  it('generates declarations with source maps', () => {
    assert.strictEqual(co.declaration, true);
    assert.strictEqual(co.declarationMap, true);
    assert.strictEqual(co.sourceMap, true);
  });
});

describe('TypeScript React Config', () => {
  it('has a valid JSON schema reference', () => {
    assert.strictEqual(reactConfig.$schema, 'https://json.schemastore.org/tsconfig');
  });

  it('extends base config', () => {
    assert.strictEqual(reactConfig.extends, './base.json');
  });

  it('includes DOM libs alongside ES2022', () => {
    const libs = reactConfig.compilerOptions.lib;
    assert.ok(libs.includes('ES2022'));
    assert.ok(libs.includes('DOM'));
    assert.ok(libs.includes('DOM.Iterable'));
  });

  it('uses react-jsx transform', () => {
    assert.strictEqual(reactConfig.compilerOptions.jsx, 'react-jsx');
  });

  it('disables emit (bundler handles output)', () => {
    assert.strictEqual(reactConfig.compilerOptions.noEmit, true);
  });

  it('allows JavaScript files', () => {
    assert.strictEqual(reactConfig.compilerOptions.allowJs, true);
  });

  it('sets baseUrl to current directory', () => {
    assert.strictEqual(reactConfig.compilerOptions.baseUrl, '.');
  });

  describe('path aliases', () => {
    const paths = reactConfig.compilerOptions.paths;

    it('has @/* alias pointing to src/*', () => {
      assert.deepStrictEqual(paths['@/*'], ['src/*']);
    });

    it('has @shared/* alias pointing to src/shared/*', () => {
      assert.deepStrictEqual(paths['@shared/*'], ['src/shared/*']);
    });

    it('has @domains/* alias pointing to src/domains/*', () => {
      assert.deepStrictEqual(paths['@domains/*'], ['src/domains/*']);
    });
  });

  it('includes src directory and vite config', () => {
    assert.ok(reactConfig.include.includes('src/**/*'));
    assert.ok(reactConfig.include.includes('vite.config.ts'));
  });

  it('excludes node_modules and dist', () => {
    assert.ok(reactConfig.exclude.includes('node_modules'));
    assert.ok(reactConfig.exclude.includes('dist'));
  });
});
