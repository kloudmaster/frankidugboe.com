import { describe, expect, test } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const homepage = readFileSync(
  resolve(process.cwd(), 'src/pages/index.astro'),
  'utf8',
);

const navigation = readFileSync(
  resolve(process.cwd(), 'src/data/navigation.ts'),
  'utf8',
);

describe('portfolio navigation', () => {
  test('exposes the primary portfolio sections', () => {
    const sections = [
      'About',
      'Experience',
      'Projects',
      'Research',
      'Articles',
      'Certifications',
      'Community',
      'Contact',
    ];

    for (const section of sections) {
      expect(navigation).toContain(section);
    }
  });
});

describe('featured DevOps projects', () => {
  test('features the Kubernetes and Karpenter incident case study', () => {
    expect(homepage).toContain('Kubernetes');
    expect(homepage).toContain('Karpenter');
  });

  test('features the EBS encryption automation case study', () => {
    expect(homepage).toContain('EBS Encryption Automation');
  });

  test('features the KEDA autoscaling case study', () => {
    expect(homepage).toContain('KEDA');
    expect(homepage).toContain('Event-Driven Autoscaling');
  });
});
