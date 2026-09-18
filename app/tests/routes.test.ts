import { describe, expect, test } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const routes = [
  {
    name: 'About',
    file: 'src/pages/about.astro',
    heading: 'About',
  },
  {
    name: 'Experience',
    file: 'src/pages/experience.astro',
    heading: 'Experience',
  },
  {
    name: 'Projects',
    file: 'src/pages/projects/index.astro',
    heading: 'Projects',
  },
  {
    name: 'Research',
    file: 'src/pages/research.astro',
    heading: 'Research',
  },
  {
    name: 'Articles',
    file: 'src/pages/articles.astro',
    heading: 'Articles',
  },
  {
    name: 'Certifications',
    file: 'src/pages/certifications.astro',
    heading: 'Certifications',
  },
  {
    name: 'Community',
    file: 'src/pages/community.astro',
    heading: 'Community',
  },
  {
    name: 'Contact',
    file: 'src/pages/contact.astro',
    heading: 'Contact',
  },
];

describe('portfolio routes', () => {
  for (const route of routes) {
    test(`provides the ${route.name} page`, () => {
      const path = resolve(process.cwd(), route.file);

      expect(existsSync(path)).toBe(true);

      if (!existsSync(path)) {
        return;
      }

      const source = readFileSync(path, 'utf8');

      expect(source).toContain('BaseLayout');
      expect(source).toContain('SiteHeader');
      expect(source).toContain(route.heading);
    });
  }
});
