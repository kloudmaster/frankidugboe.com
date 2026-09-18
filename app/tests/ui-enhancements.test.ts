import { describe, expect, test } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const homepage = readFileSync(
  resolve(process.cwd(), 'src/pages/index.astro'),
  'utf8',
);

const footer = readFileSync(
  resolve(process.cwd(), 'src/components/SiteFooter.astro'),
  'utf8',
);

const githubSection = readFileSync(
  resolve(process.cwd(), 'src/components/GitHubSection.astro'),
  'utf8',
);

describe('homepage hero', () => {
  test('links to a downloadable CV', () => {
    expect(homepage).toContain('/cv/frank-osasere-idugboe-resume.pdf');
    expect(homepage).toContain('download');
  });

  test('shows the profile photo', () => {
    expect(homepage).toContain('/images/frank-idugboe.png');
    expect(homepage).toMatch(/alt="Frank Osasere Idugboe"/);
  });

  test('includes the GitHub section', () => {
    expect(homepage).toContain('GitHubSection');
  });
});

describe('GitHub section', () => {
  test('links to the GitHub profile', () => {
    expect(githubSection).toContain('https://github.com/kloudmaster');
  });

  test('embeds the self-hosted contribution graph with a fallback', () => {
    expect(githubSection).toContain('/images/github-contributions.svg');
    expect(githubSection).toContain('gh-fallback');
  });
});

describe('site footer', () => {
  test('links to GitHub, LinkedIn and the contact page', () => {
    expect(footer).toContain('https://github.com/kloudmaster');
    expect(footer).toContain('https://www.linkedin.com/in/kloudmaster/');
    expect(footer).toContain('/contact');
  });

  test('does not expose a public email address', () => {
    expect(footer).not.toMatch(/mailto:/i);
  });
});
