import { describe, expect, test } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const projects = [
  {
    name: 'Karpenter incident',
    file: 'src/pages/projects/karpenter-incident-debugging.astro',
    expectations: [
      'Kubernetes',
      'Karpenter',
      'AWS IAM',
      'EBS',
      'Problem',
      'Architecture',
      'Investigation',
      'Lessons',
    ],
  },
  {
    name: 'EBS encryption automation',
    file: 'src/pages/projects/ebs-encryption-automation.astro',
    expectations: [
      'EBS Encryption Automation',
      'AWS Config',
      'Systems Manager',
      'CloudFormation',
      'Problem',
      'Implementation',
      'Security',
      'Lessons',
    ],
  },
  {
    name: 'KEDA autoscaling',
    file: 'src/pages/projects/keda-autoscaling.astro',
    expectations: [
      'KEDA',
      'Event-Driven Autoscaling',
      'Kubernetes',
      'Observability',
      'Problem',
      'Implementation',
      'Results',
      'Lessons',
    ],
  },
];

describe('project case-study pages', () => {
  for (const project of projects) {
    test(`provides the ${project.name} case study`, () => {
      const path = resolve(process.cwd(), project.file);

      expect(existsSync(path)).toBe(true);

      if (!existsSync(path)) {
        return;
      }

      const source = readFileSync(path, 'utf8');

      expect(source).toContain('BaseLayout');
      expect(source).toContain('SiteHeader');

      for (const expectation of project.expectations) {
        expect(source).toContain(expectation);
      }
    });
  }
});
