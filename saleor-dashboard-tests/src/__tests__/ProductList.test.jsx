/**
 * ProductList.test.jsx
 * ====================
 * Component rendering tests for Saleor Dashboard's ProductList.
 *
 * Tier: Frontend — React component (mirrors saleor-dashboard)
 * Functional flow: component renders → calls api.js → displays data
 *
 * Test doubles applied
 * --------------------
 * - Mock (jest.mock("../api")): replaces the entire api module with a jest
 *   mock. Each test controls what fetchProducts() resolves to.
 *   Justification: components must not contact sq-be during unit testing.
 *   Mocking at the module boundary (not fetch) is more idiomatic for
 *   React component tests and aligns with the lab's isolation principle.
 */

import { render, screen, waitFor } from "@testing-library/react";
import "@testing-library/jest-dom";
import ProductList, { ProductCard } from "../ProductList";
import * as api from "../api";

// Mock the entire api module (Mock test double)
jest.mock("../api");

// ── Helper data ────────────────────────────────────────────────────────────

const PRODUCTS = [
  { id: "1", name: "Laptop Pro",    slug: "laptop-pro",    isPublished: true,  productType: { name: "Physical" } },
  { id: "2", name: "Wireless Mouse",slug: "wireless-mouse",isPublished: true,  productType: { name: "Physical" } },
  { id: "3", name: "Draft Keyboard",slug: "draft-keyboard",isPublished: false, productType: { name: "Physical" } },
];

// ── ProductCard ────────────────────────────────────────────────────────────

describe("ProductCard", () => {
  const product = PRODUCTS[0];

  test("renders product name", () => {
    render(<ProductCard product={product} />);
    expect(screen.getByTestId("product-name")).toHaveTextContent("Laptop Pro");
  });

  test("renders product slug", () => {
    render(<ProductCard product={product} />);
    expect(screen.getByTestId("product-slug")).toHaveTextContent("laptop-pro");
  });

  test("shows 'Published' for published product", () => {
    render(<ProductCard product={product} />);
    expect(screen.getByTestId("product-status")).toHaveTextContent("Published");
  });

  test("shows 'Draft' for unpublished product", () => {
    render(<ProductCard product={PRODUCTS[2]} />);
    expect(screen.getByTestId("product-status")).toHaveTextContent("Draft");
  });

  test("renders product type name", () => {
    render(<ProductCard product={product} />);
    expect(screen.getByTestId("product-type")).toHaveTextContent("Physical");
  });
});

// ── ProductList ────────────────────────────────────────────────────────────

describe("ProductList", () => {
  afterEach(() => jest.resetAllMocks());

  test("shows loading indicator initially", () => {
    // fetchProducts never resolves → component stays in loading state
    api.fetchProducts.mockReturnValue(new Promise(() => {}));
    render(<ProductList />);
    expect(screen.getByTestId("loading-indicator")).toBeInTheDocument();
  });

  test("renders list of products after fetch resolves", async () => {
    api.fetchProducts.mockResolvedValue(PRODUCTS);
    render(<ProductList />);

    await waitFor(() =>
      expect(screen.queryByTestId("loading-indicator")).not.toBeInTheDocument()
    );

    const cards = screen.getAllByTestId("product-card");
    expect(cards).toHaveLength(3);
  });

  test("displays correct product names", async () => {
    api.fetchProducts.mockResolvedValue(PRODUCTS);
    render(<ProductList />);

    expect(await screen.findByText("Laptop Pro")).toBeInTheDocument();
    expect(await screen.findByText("Wireless Mouse")).toBeInTheDocument();
    expect(await screen.findByText("Draft Keyboard")).toBeInTheDocument();
  });

  test("shows product count", async () => {
    api.fetchProducts.mockResolvedValue(PRODUCTS);
    render(<ProductList />);

    expect(await screen.findByTestId("product-count")).toHaveTextContent("3 product(s)");
  });

  test("shows empty state when no products returned", async () => {
    api.fetchProducts.mockResolvedValue([]);
    render(<ProductList />);

    expect(await screen.findByTestId("empty-state")).toBeInTheDocument();
  });

  test("shows error message when fetch fails", async () => {
    api.fetchProducts.mockRejectedValue(new Error("Network Error"));
    render(<ProductList />);

    expect(await screen.findByTestId("error-message")).toHaveTextContent(
      "Error: Network Error"
    );
  });

  test("calls fetchProducts with filter prop", async () => {
    api.fetchProducts.mockResolvedValue([PRODUCTS[0]]);
    render(<ProductList filter={{ isPublished: true }} />);

    await waitFor(() =>
      expect(api.fetchProducts).toHaveBeenCalled()
    );
    expect(api.fetchProducts.mock.calls[0][0]).toEqual({ isPublished: true });
  });

  test("does not call sq-be directly (mock intercepted)", async () => {
    api.fetchProducts.mockResolvedValue([]);
    render(<ProductList />);
    await screen.findByTestId("empty-state");
    // The real fetch was never called — the mock intercepted it
    expect(global.fetch).toBeUndefined();
  });
});
