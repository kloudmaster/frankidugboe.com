import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

const functionPath = new URL("../viewer-request.js", import.meta.url);
const source = readFileSync(functionPath, "utf8");

function loadHandler() {
  const context = {};
  vm.createContext(context);
  vm.runInContext(source, context);

  return context.handler;
}

function createEvent(uri) {
  return {
    request: {
      uri,
      headers: {},
    },
  };
}

test("rewrites extensionless Astro routes to index.html", () => {
  const handler = loadHandler();
  const result = handler(createEvent("/about"));

  assert.equal(result.uri, "/about/index.html");
});

test("rewrites trailing-slash Astro routes to index.html", () => {
  const handler = loadHandler();
  const result = handler(createEvent("/about/"));

  assert.equal(result.uri, "/about/index.html");
});

test("leaves file requests unchanged", () => {
  const handler = loadHandler();
  const result = handler(createEvent("/assets/site.css"));

  assert.equal(result.uri, "/assets/site.css");
});

test("redirects www host to canonical apex", () => {
  const handler = loadHandler();

  const result = handler({
    request: {
      uri: "/about",
      headers: {
        host: {
          value: "www.frankidugboe.com",
        },
      },
      querystring: {},
    },
  });

  assert.equal(result.statusCode, 301);
  assert.equal(
    result.headers.location.value,
    "https://frankidugboe.com/about",
  );
});

test("preserves query parameters when redirecting www to apex", () => {
  const handler = loadHandler();

  const result = handler({
    request: {
      uri: "/projects",
      headers: {
        host: {
          value: "www.frankidugboe.com",
        },
      },
      querystring: {
        ref: {
          value: "github",
        },
        utm_source: {
          value: "profile",
        },
      },
    },
  });

  assert.equal(result.statusCode, 301);
  assert.equal(
    result.headers.location.value,
    "https://frankidugboe.com/projects?ref=github&utm_source=profile",
  );
});
