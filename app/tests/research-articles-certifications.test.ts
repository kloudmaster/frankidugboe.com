import { describe, expect, test } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const research = readFileSync(
  resolve(process.cwd(), 'src/pages/research.astro'),
  'utf8',
);

const articles = readFileSync(
  resolve(process.cwd(), 'src/pages/articles.astro'),
  'utf8',
);

const certifications = readFileSync(
  resolve(process.cwd(), 'src/pages/certifications.astro'),
  'utf8',
);

describe('Research page', () => {
  test('identifies the UNIFESSPA forensic science research context', () => {
    expect(research).toContain('UNIFESSPA');
    expect(research).toContain('Forensic Science');
  });

  test('describes the current forensic-ready IoT research direction', () => {
    expect(research).toContain('forensic-ready');
    expect(research).toContain('IoT');
    expect(research).toContain('livestock traceability');
  });

  test('connects the research to digital evidence disciplines', () => {
    expect(research).toContain('cloud forensics');
    expect(research).toContain('IoT forensics');
    expect(research).toContain('digital evidence');
    expect(research).toContain('chain of custody');
  });

  test('shows the research technology path', () => {
    expect(research).toContain('ESP32');
    expect(research).toContain('LoRa');
    expect(research).toContain('Raspberry Pi');
    expect(research).toContain('MQTT');
  });
});

describe('Articles page', () => {
  test('includes the published Kubernetes and Karpenter article', () => {
    expect(articles).toContain('Kubernetes');
    expect(articles).toContain('Karpenter');
    expect(articles).toContain(
      'https://dev.to/aws-builders/kubernetes-at-3-cpu-but-pods-still-pending-debugging-requests-karpenter-and-ebs-az-affinity-17jh',
    );
  });

  test('positions the writing around practical cloud engineering', () => {
    expect(articles).toContain('AWS');
    expect(articles).toContain('DevOps');
    expect(articles).toContain('Cloud Security');
  });
});

describe('Certifications page', () => {
  test('separates credential status clearly', () => {
    expect(certifications).toContain('Active Certifications');
    expect(certifications).toContain('In Progress');
    expect(certifications).toContain('Professional Training');
    expect(certifications).toContain('Previously Held');
  });

  test('includes current AWS recertification work', () => {
    expect(certifications).toContain('AWS recertification');
  });

  test('includes Mercor professional training', () => {
    expect(certifications).toContain('Mercor');
    expect(certifications).toContain('Introduction to Agents');
    expect(certifications).toContain('2026');
  });

  test('marks historical AWS and KCNA credentials transparently', () => {
    expect(certifications).toContain('AWS');
    expect(certifications).toContain('KCNA');
    expect(certifications).toContain('expired');
  });
});
