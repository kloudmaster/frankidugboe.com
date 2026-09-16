import { describe, expect, test } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const about = readFileSync(
  resolve(process.cwd(), 'src/pages/about.astro'),
  'utf8',
);

const experience = readFileSync(
  resolve(process.cwd(), 'src/pages/experience.astro'),
  'utf8',
);

describe('About page professional identity', () => {
  test('communicates Frank’s engineering experience', () => {
    expect(about).toContain('8+ years');
    expect(about).toContain('Cloud');
    expect(about).toContain('DevOps');
  });

  test('connects engineering with digital forensics research', () => {
    expect(about).toContain('Digital Forensics');
    expect(about).toContain('UNIFESSPA');
  });

  test('highlights the core engineering stack', () => {
    expect(about).toContain('AWS');
    expect(about).toContain('Kubernetes');
    expect(about).toContain('Terraform');
  });
});

describe('Experience page professional history', () => {
  test('includes the current OxygenX role', () => {
    expect(experience).toContain('OxygenX');
    expect(experience).toContain('DevOps Engineer');
    expect(experience).toContain('Oct 2024');
  });

  test('includes Yebox Technologies experience', () => {
    expect(experience).toContain('Yebox Technologies');
    expect(experience).toContain('Lead DevOps Engineer');
    expect(experience).toContain('Apr 2021');
  });

  test('includes The American Lotto experience', () => {
    expect(experience).toContain('The American Lotto');
    expect(experience).toContain('Oct 2023');
  });

  test('includes Intersource Global experience', () => {
    expect(experience).toContain('Intersource Global Inc.');
    expect(experience).toContain('DevSecOps Engineer');
    expect(experience).toContain('Feb 2021');
  });

  test('shows production engineering capabilities', () => {
    expect(experience).toContain('AWS');
    expect(experience).toContain('Kubernetes');
    expect(experience).toContain('Terraform');
    expect(experience).toContain('CI/CD');
  });
});
