'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

// Stub the SES SDK before loading the handler so no real AWS calls occur and
// no @aws-sdk dependency needs to be installed to run these tests.
const sesSends = [];
const originalResolve = Module._resolveFilename;
const originalLoad = Module._load;
Module._load = function patchedLoad(request, parent, isMain) {
  if (request === '@aws-sdk/client-sesv2') {
    return {
      SESv2Client: class {
        async send(command) {
          sesSends.push(command);
          return { MessageId: 'test-message-id' };
        }
      },
      SendEmailCommand: class {
        constructor(input) {
          this.input = input;
        }
      },
    };
  }
  return originalLoad.apply(this, [request, parent, isMain]);
};

process.env.SES_SENDER = 'no-reply@frankidugboe.com';
process.env.SES_RECIPIENT = 'private@frankidugboe.com';
process.env.RATE_LIMIT_MAX = '3';
process.env.RATE_LIMIT_WINDOW_MS = '60000';

const handlerModule = require('../index.js');
const { handler } = handlerModule;
const { validate } = handlerModule._internal;

Module._resolveFilename = originalResolve;

function event(body, headers = {}) {
  return {
    body: typeof body === 'string' ? body : JSON.stringify(body),
    headers: { 'x-forwarded-for': '203.0.113.10', ...headers },
    requestContext: { http: { sourceIp: '203.0.113.10' } },
  };
}

const valid = {
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  subject: 'Collaboration',
  message: 'I would like to discuss a cloud engineering collaboration opportunity.',
  company_website: '',
};

test.beforeEach(() => {
  sesSends.length = 0;
});

test('accepts a valid submission and sends one email', async () => {
  const res = await handler(event({ ...valid }, { 'x-forwarded-for': '198.51.100.1' }));
  assert.equal(res.statusCode, 200);
  assert.equal(JSON.parse(res.body).ok, true);
  assert.equal(sesSends.length, 1);
  const sent = sesSends[0].input;
  assert.equal(sent.Destination.ToAddresses[0], 'private@frankidugboe.com');
  assert.equal(sent.ReplyToAddresses[0], 'ada@example.com');
  assert.match(sent.Content.Simple.Subject.Data, /Collaboration/);
});

test('honeypot filled -> 200 but no email sent', async () => {
  const res = await handler(
    event({ ...valid, company_website: 'http://spam.example' }, { 'x-forwarded-for': '198.51.100.2' }),
  );
  assert.equal(res.statusCode, 200);
  assert.equal(sesSends.length, 0);
});

test('invalid body -> 400', async () => {
  const res = await handler(event('not json', { 'x-forwarded-for': '198.51.100.3' }));
  assert.equal(res.statusCode, 400);
  assert.equal(sesSends.length, 0);
});

test('validation failure -> 422 with offending fields', async () => {
  const res = await handler(
    event({ ...valid, email: 'bad', message: 'too short' }, { 'x-forwarded-for': '198.51.100.4' }),
  );
  assert.equal(res.statusCode, 422);
  const parsed = JSON.parse(res.body);
  assert.ok(parsed.fields.includes('email'));
  assert.ok(parsed.fields.includes('message'));
  assert.equal(sesSends.length, 0);
});

test('rate limit -> 429 after exceeding max for an IP', async () => {
  const ip = { 'x-forwarded-for': '198.51.100.5' };
  await handler(event({ ...valid }, ip));
  await handler(event({ ...valid }, ip));
  await handler(event({ ...valid }, ip));
  const res = await handler(event({ ...valid }, ip)); // 4th > max(3)
  assert.equal(res.statusCode, 429);
});

test('validate enforces field length bounds', () => {
  assert.deepEqual(validate({ ...valid }).errors, []);
  assert.ok(validate({ ...valid, name: 'A' }).errors.includes('name'));
  assert.ok(validate({ ...valid, subject: 'ab' }).errors.includes('subject'));
  assert.ok(
    validate({ ...valid, email: 'x'.repeat(250) + '@a.com' }).errors.includes('email'),
  );
});
