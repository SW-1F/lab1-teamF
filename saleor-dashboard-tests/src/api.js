/**
 * api.js
 * ======
 * Simplified version of Saleor Dashboard's product API module.
 *
 * In production this is handled by Apollo Client with auto-generated
 * GraphQL hooks (saleor-dashboard/src/products/queries.ts).
 *
 * This standalone module is the Unit Under Test for Jest.
 * It exposes the same interface so components can be tested in isolation.
 */

const SALEOR_API_URL =
  process.env.REACT_APP_API_URL || "http://localhost:8000/graphql/";

// ── GraphQL query (mirrors ProductListQuery in saleor-dashboard) ──────────

const PRODUCTS_QUERY = `
  query ProductList($filter: ProductFilterInput, $channel: String) {
    products(first: 20, filter: $filter, channel: $channel) {
      edges {
        node {
          id
          name
          slug
          channelListings {
            isPublished
          }
          thumbnail {
            url
          }
          productType {
            name
          }
        }
      }
    }
  }
`;

// ── API functions (unit under test) ──────────────────────────────────────

/**
 * Fetch all products, optionally filtered.
 * @param {Object} filter - e.g. { isPublished: true }
 * @returns {Promise<Array>} array of product nodes
 */
export async function fetchProducts(filter = {}, token = null) {
  const headers = { "Content-Type": "application/json" };
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }
  const response = await fetch(SALEOR_API_URL, {
    method: "POST",
    headers,
    body: JSON.stringify({
      query: PRODUCTS_QUERY,
      variables: { filter, channel: "default-channel" },
    }),
  });

  if (!response.ok) {
    throw new Error(`GraphQL request failed: ${response.status}`);
  }

  const { data, errors } = await response.json();

  if (errors && errors.length > 0) {
    throw new Error(errors[0].message);
  }

  return data.products.edges.map((edge) => {
    const node = edge.node;
    return {
      ...node,
      isPublished: node.channelListings?.[0]?.isPublished ?? false,
    };
  });
}

/**
 * Fetch a single product by slug.
 * @param {string} slug
 * @returns {Promise<Object|null>}
 */
export async function fetchProductBySlug(slug, token = null) {
  const all = await fetchProducts({}, token);
  return all.find((p) => p.slug === slug) || null;
}

/**
 * Pure helper: filter locally by published status.
 * Used to demonstrate pure function unit testing (no fetch needed).
 * @param {Array} products
 * @param {boolean} published
 * @returns {Array}
 */
export function filterPublished(products, published) {
  return products.filter((p) => p.isPublished === published);
}

/**
 * Pure helper: sort products by name.
 * @param {Array} products
 * @param {"asc"|"desc"} direction
 * @returns {Array}
 */
export function sortByName(products, direction = "asc") {
  return [...products].sort((a, b) =>
    direction === "asc"
      ? a.name.localeCompare(b.name)
      : b.name.localeCompare(a.name)
  );
}
