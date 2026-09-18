import { describe, expect, test } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

function read(relativePath: string) {
  const path = resolve(process.cwd(), relativePath);

  if (!existsSync(path)) {
    return '';
  }

  return readFileSync(path, 'utf8');
}

const layout = read('src/layouts/BaseLayout.astro');
const astroConfig = read('astro.config.mjs');
const packageJson = read('package.json');
const robots = read('public/robots.txt');

describe('canonical SEO metadata', () => {
  test('uses the production domain as the Astro site URL', () => {
    expect(astroConfig).toContain('https://frankidugboe.com');
  });

  test('provides canonical URLs through the shared layout', () => {
    expect(layout).toContain('rel="canonical"');
    expect(layout).toContain('Astro.url');
  });

  test('provides standard page metadata', () => {
    expect(layout).toContain('name="description"');
    expect(layout).toContain('<title>');
  });
});

describe('social metadata', () => {
  test('provides Open Graph metadata', () => {
    expect(layout).toContain('property="og:title"');
    expect(layout).toContain('property="og:description"');
    expect(layout).toContain('property="og:url"');
    expect(layout).toContain('property="og:type"');
  });

  test('provides Twitter card metadata', () => {
    expect(layout).toContain('name="twitter:card"');
    expect(layout).toContain('name="twitter:title"');
    expect(layout).toContain('name="twitter:description"');
  });
});

describe('structured identity data', () => {
  test('includes Person, WebSite, and ProfilePage schema types', () => {
    expect(layout).toContain('"Person"');
    expect(layout).toContain('"WebSite"');
    expect(layout).toContain('"ProfilePage"');
  });

  test('uses the canonical professional identity', () => {
    expect(layout).toContain('Frank Osasere Idugboe');
    expect(layout).toContain('Cloud & DevOps Engineer');
    expect(layout).toContain('AWS Community Builder');
    expect(layout).toContain('Digital Forensics Researcher');
    expect(layout).toContain('UNIFESSPA');
  });

  test('includes the verified GitHub profile', () => {
    expect(layout).toContain('https://github.com/kloudmaster');
  });
});

describe('crawler discovery', () => {
  test('configures the Astro sitemap integration', () => {
    expect(packageJson).toContain('@astrojs/sitemap');
    expect(astroConfig).toContain('sitemap');
  });

  test('provides robots.txt', () => {
    expect(robots).toContain('User-agent: *');
    expect(robots).toContain('Allow: /');
  });

  test('advertises the production sitemap in robots.txt', () => {
    expect(robots).toContain(
      'Sitemap: https://frankidugboe.com/sitemap-index.xml',
    );
  });
});
