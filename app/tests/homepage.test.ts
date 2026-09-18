import { describe, expect, test } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

describe('portfolio homepage', () => {
  const homepage = readFileSync(
    resolve(process.cwd(), 'src/pages/index.astro'),
    'utf8',
  );

  test('identifies Frank Osasere Idugboe', () => {
    expect(homepage).toContain('Frank Osasere Idugboe');
  });

  test('positions the portfolio around Cloud and DevOps engineering', () => {
    expect(homepage).toContain('Cloud');
    expect(homepage).toContain('DevOps');
  });

  test('provides the primary View Projects call to action', () => {
    expect(homepage).toContain('View Projects');
  });

  test('provides a Download CV secondary action', () => {
    expect(homepage).toContain('Download CV');
  });
});
