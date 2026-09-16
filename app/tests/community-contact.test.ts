import { describe, expect, test } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const community = readFileSync(
  resolve(process.cwd(), 'src/pages/community.astro'),
  'utf8',
);

const contact = readFileSync(
  resolve(process.cwd(), 'src/pages/contact.astro'),
  'utf8',
);

describe('Community page', () => {
  test('highlights AWS Community Builder involvement', () => {
    expect(community).toContain('AWS Community Builder');
    expect(community).toContain('Cloud Operations');
  });

  test('shows technical writing and mentoring activity', () => {
    expect(community).toContain('Technical Writing');
    expect(community).toContain('Mentoring');
    expect(community).toContain('Knowledge Sharing');
  });

  test('connects community work to practical engineering', () => {
    expect(community).toContain('AWS');
    expect(community).toContain('DevOps');
    expect(community).toContain('Cloud Security');
  });
});

describe('Contact page', () => {
  test('provides a professional contact form', () => {
    expect(contact).toContain('<form');
    expect(contact).toContain('name="name"');
    expect(contact).toContain('name="email"');
    expect(contact).toContain('name="subject"');
    expect(contact).toContain('name="message"');
  });

  test('includes accessible form labels', () => {
    expect(contact).toContain('Full name');
    expect(contact).toContain('Email address');
    expect(contact).toContain('Subject');
    expect(contact).toContain('Message');
  });

  test('includes basic client-side validation', () => {
    expect(contact).toContain('required');
    expect(contact).toContain('type="email"');
    expect(contact).toContain('minlength');
    expect(contact).toContain('maxlength');
  });

  test('includes anti-abuse honeypot protection', () => {
    expect(contact).toContain('company_website');
    expect(contact).toContain('autocomplete="off"');
  });

  test('does not expose a public email address', () => {
    expect(contact).not.toMatch(/mailto:/i);
  });

  test('makes the future serverless architecture clear', () => {
    expect(contact).toContain('API Gateway');
    expect(contact).toContain('AWS Lambda');
    expect(contact).toContain('Amazon SES');
  });
});
