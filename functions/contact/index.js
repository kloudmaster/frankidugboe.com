'use strict';

/**
 * Contact form handler for frankidugboe.com.
 *
 * Fronted by CloudFront (WAF) -> API Gateway HTTP API. Validates input,
 * rejects bot submissions via a honeypot field, applies a lightweight
 * per-instance rate limit, and delivers the message through Amazon SES.
 *
 * Environment variables:
 *   SES_SENDER      Verified SES "From" address (e.g. no-reply@frankidugboe.com)
 *   SES_RECIPIENT   Private destination inbox (never exposed to clients)
 *   ALLOWED_ORIGIN  Expected Origin header value (defense in depth); optional
 *   RATE_LIMIT_MAX  Max submissions per IP per window (default 5)
 *   RATE_LIMIT_WINDOW_MS  Window size in ms (default 60000)
 */

const { SESv2Client, SendEmailCommand } = require('@aws-sdk/client-sesv2');

const sesClient = new SESv2Client({});

// Field length bounds mirror the client-side contract in contact.astro.
const LIMITS = {
  name: { min: 2, max: 100 },
  email: { max: 254 },
  subject: { min: 3, max: 150 },
  message: { min: 20, max: 5000 },
};

// Conservative email pattern: something@something.tld with no spaces.
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Best-effort per-instance rate limiting. This is a secondary control; the
// primary rate limiting is the WAF rate-based rule. The map is scoped to the
// warm Lambda execution environment and intentionally simple.
const rateState = new Map();

function rateLimit(ip, now, max, windowMs) {
  if (!ip) {
    return true;
  }
  const entry = rateState.get(ip);
  if (!entry || now - entry.start >= windowMs) {
    rateState.set(ip, { start: now, count: 1 });
    return true;
  }
  if (entry.count >= max) {
    return false;
  }
  entry.count += 1;
  return true;
}

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      'content-type': 'application/json',
      'cache-control': 'no-store',
    },
    body: JSON.stringify(body),
  };
}

function parseBody(event) {
  if (!event || typeof event.body !== 'string') {
    return event && typeof event.body === 'object' ? event.body : null;
  }
  let raw = event.body;
  if (event.isBase64Encoded) {
    raw = Buffer.from(raw, 'base64').toString('utf8');
  }
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function validate(payload) {
  const errors = [];
  const clean = {};

  const str = (v) => (typeof v === 'string' ? v.trim() : '');

  const name = str(payload.name);
  if (name.length < LIMITS.name.min || name.length > LIMITS.name.max) {
    errors.push('name');
  }
  clean.name = name;

  const email = str(payload.email);
  if (email.length > LIMITS.email.max || !EMAIL_PATTERN.test(email)) {
    errors.push('email');
  }
  clean.email = email;

  const subject = str(payload.subject);
  if (
    subject.length < LIMITS.subject.min ||
    subject.length > LIMITS.subject.max
  ) {
    errors.push('subject');
  }
  clean.subject = subject;

  const message = str(payload.message);
  if (
    message.length < LIMITS.message.min ||
    message.length > LIMITS.message.max
  ) {
    errors.push('message');
  }
  clean.message = message;

  return { errors, clean };
}

function getClientIp(event) {
  const headers = (event && event.headers) || {};
  const forwarded = headers['x-forwarded-for'] || headers['X-Forwarded-For'];
  if (forwarded) {
    return forwarded.split(',')[0].trim();
  }
  return (
    event &&
    event.requestContext &&
    event.requestContext.http &&
    event.requestContext.http.sourceIp
  );
}

async function sendEmail(clean, ip) {
  const sender = process.env.SES_SENDER;
  const recipient = process.env.SES_RECIPIENT;
  if (!sender || !recipient) {
    throw new Error('SES_SENDER and SES_RECIPIENT must be configured');
  }

  const textBody = [
    `Name: ${clean.name}`,
    `Email: ${clean.email}`,
    `Subject: ${clean.subject}`,
    `Source IP: ${ip || 'unknown'}`,
    '',
    clean.message,
  ].join('\n');

  const command = new SendEmailCommand({
    FromEmailAddress: sender,
    Destination: { ToAddresses: [recipient] },
    // Set Reply-To to the visitor so replies go to them, not the sender.
    ReplyToAddresses: [clean.email],
    Content: {
      Simple: {
        Subject: { Data: `[Contact] ${clean.subject}`, Charset: 'UTF-8' },
        Body: { Text: { Data: textBody, Charset: 'UTF-8' } },
      },
    },
  });

  await sesClient.send(command);
}

exports.handler = async (event) => {
  const now = Date.now();
  const max = Number(process.env.RATE_LIMIT_MAX || 5);
  const windowMs = Number(process.env.RATE_LIMIT_WINDOW_MS || 60000);

  const payload = parseBody(event);
  if (!payload || typeof payload !== 'object') {
    return response(400, { ok: false, error: 'Invalid request body.' });
  }

  // Honeypot: the hidden company_website field must be empty. A filled value
  // indicates a bot. Return 200 so bots get no signal that they were caught.
  if (typeof payload.company_website === 'string' && payload.company_website.trim() !== '') {
    return response(200, { ok: true });
  }

  const ip = getClientIp(event);
  if (!rateLimit(ip, now, max, windowMs)) {
    return response(429, {
      ok: false,
      error: 'Too many requests. Please try again shortly.',
    });
  }

  const { errors, clean } = validate(payload);
  if (errors.length > 0) {
    return response(422, {
      ok: false,
      error: 'Validation failed.',
      fields: errors,
    });
  }

  try {
    await sendEmail(clean, ip);
  } catch (err) {
    console.error('Failed to send contact email:', err);
    return response(502, {
      ok: false,
      error: 'Message could not be delivered. Please try again later.',
    });
  }

  return response(200, { ok: true });
};

// Exported for unit testing.
exports._internal = { validate, rateLimit, parseBody, getClientIp };
