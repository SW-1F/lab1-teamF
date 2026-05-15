/**
 * productApi.test.js
 * ==================
 * Unit tests for Saleor Dashboard's product API module.
 *
 * Tier: Frontend — React / Apollo / GraphQL client
 * Functional flow: Dashboard fires GraphQL query → API resolves → DB stores
 *
 * Test doubles applied
 * --------------------
 * - Stub (global.fetch): replaces the real HTTP fetch with a controlled
 *   function that returns deterministic JSON. Prevents any real network call
 *   to sq-be / Saleor API. Justification: unit tests must not depend on a
 *   running backend (isolation principle from the lab).
 */

import { fetchProducts, fetchProductBySlug, filterPublished, sortByName } from "../api";

// ── Helpers ────────────────────────────────────────────────────────────────

const MOCK_PRODUCTS = [
  { id: "UHJvZHVjdDox", name: "Laptop Pro",     slug: "laptop-pro",     isPublished: true,  productType: { name: "Physical" } },
  { id: "UHJvZHVjdDoy", name: "Wireless Mouse",  slug: "wireless-mouse", isPublished: true,  productType: { name: "Physical" } },
  { id: "UHJvZHVjdDoz", name: "Draft Keyboard",  slug: "draft-keyboard", isPublished: false, productType: { name: "Physical" } },
];

function makeFetchStub(products = MOCK_PRODUCTS) {
  return jest.fn(() =>
    Promise.resolve({
      ok: true,
      json: () =>
        Promise.resolve({
          data: {
            products: {
              edges: products.map((p) => ({ node: p })),
            },
          },
        }),
    })
  );
}

// ── fetchProducts ──────────────────────────────────────────────────────────

describe("fetchProducts", () => {
  beforeEach(() => {
    global.fetch = makeFetchStub();
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  test("calls the Saleor GraphQL endpoint via POST", async () => {
    await fetchProducts();
    expect(global.fetch).toHaveBeenCalledTimes(1);
    const [url, options] = global.fetch.mock.calls[0];
    expect(url).toContain("graphql");
    expect(options.method).toBe("POST");
  });

  test("returns an array of product nodes", async () => {
    const result = await fetchProducts();
    expect(Array.isArray(result)).toBe(true);
    expect(result).toHaveLength(3);
  });

  test("each product has expected fields", async () => {
    const [first] = await fetchProducts();
    expect(first).toHaveProperty("id");
    expect(first).toHaveProperty("name");
    expect(first).toHaveProperty("slug");
    expect(first).toHaveProperty("isPublished");
  });

  test("sends filter variable in GraphQL body", async () => {
    await fetchProducts({ isPublished: true });
    const body = JSON.parse(global.fetch.mock.calls[0][1].body);
    expect(body.variables.filter).toEqual({ isPublished: true });
  });

  test("throws when response is not ok", async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({ ok: false, status: 500 })
    );
    await expect(fetchProducts()).rejects.toThrow("GraphQL request failed: 500");
  });

  test("throws when response contains GraphQL errors", async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () =>
          Promise.resolve({ data: null, errors: [{ message: "Unauthorized" }] }),
      })
    );
    await expect(fetchProducts()).rejects.toThrow("Unauthorized");
  });
});

// ── fetchProductBySlug ─────────────────────────────────────────────────────

describe("fetchProductBySlug", () => {
  beforeEach(() => {
    global.fetch = makeFetchStub();
  });
  afterEach(() => jest.resetAllMocks());

  test("returns product matching the slug", async () => {
    const p = await fetchProductBySlug("wireless-mouse");
    expect(p).not.toBeNull();
    expect(p.name).toBe("Wireless Mouse");
  });

  test("returns null when slug does not exist", async () => {
    const p = await fetchProductBySlug("does-not-exist");
    expect(p).toBeNull();
  });
});

// ── Pure helpers ───────────────────────────────────────────────────────────

describe("filterPublished (pure function)", () => {
  test("returns only published products", () => {
    const result = filterPublished(MOCK_PRODUCTS, true);
    expect(result).toHaveLength(2);
    expect(result.every((p) => p.isPublished)).toBe(true);
  });

  test("returns only draft products", () => {
    const result = filterPublished(MOCK_PRODUCTS, false);
    expect(result).toHaveLength(1);
    expect(result[0].name).toBe("Draft Keyboard");
  });

  test("returns empty array for empty input", () => {
    expect(filterPublished([], true)).toEqual([]);
  });
});

describe("sortByName (pure function)", () => {
  test("sorts ascending by default", () => {
    const sorted = sortByName(MOCK_PRODUCTS);
    expect(sorted[0].name).toBe("Draft Keyboard");
    expect(sorted[2].name).toBe("Wireless Mouse");
  });

  test("sorts descending when specified", () => {
    const sorted = sortByName(MOCK_PRODUCTS, "desc");
    expect(sorted[0].name).toBe("Wireless Mouse");
  });

  test("does not mutate the original array", () => {
    const original = [...MOCK_PRODUCTS];
    sortByName(MOCK_PRODUCTS, "desc");
    expect(MOCK_PRODUCTS[0].name).toBe(original[0].name);
  });
});
