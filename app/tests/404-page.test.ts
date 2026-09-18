import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

describe("custom 404 page", () => {
  const pagePath = resolve(process.cwd(), "src/pages/404.astro");

  it("provides a custom Astro 404 page", () => {
    expect(existsSync(pagePath)).toBe(true);
  });

  it("uses the shared site layout and provides a route home", () => {
    const source = readFileSync(pagePath, "utf8");

    expect(source).toContain("BaseLayout");
    expect(source).toMatch(/Page not found/i);
    expect(source).toMatch(/href=["']\/["']/);
  });
});
