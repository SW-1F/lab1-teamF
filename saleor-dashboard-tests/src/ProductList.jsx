/**
 * ProductList.jsx
 * ===============
 * Simplified version of Saleor Dashboard's ProductList component.
 *
 * In production: saleor-dashboard/src/products/views/ProductList/
 *
 * This standalone component is the Unit Under Test for Jest +
 * React Testing Library.
 */
import { useState, useEffect } from "react";
import { fetchProducts } from "./api";

/**
 * ProductCard — renders a single product row.
 * (mirrors ProductListPage row in real dashboard)
 */
export function ProductCard({ product }) {
  return (
    <div data-testid="product-card" role="listitem">
      <span data-testid="product-name">{product.name}</span>
      <span data-testid="product-slug">{product.slug}</span>
      <span data-testid="product-status">
        {product.isPublished ? "Published" : "Draft"}
      </span>
      {product.productType && (
        <span data-testid="product-type">{product.productType.name}</span>
      )}
    </div>
  );
}

/**
 * ProductList — fetches and displays a list of products.
 * (mirrors ProductListPage in real dashboard)
 */
export default function ProductList({ filter = null, token = null }) {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Serialize filter to string so useEffect runs only when content changes,
  // not on every render (avoids infinite loop with default {} object ref).
  const filterKey = JSON.stringify(filter);

  useEffect(() => {
    setLoading(true);
    setError(null);
    fetchProducts(filter || {}, token)
      .then((data) => {
        setProducts(data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  }, [filterKey]); // eslint-disable-line react-hooks/exhaustive-deps

  if (loading) return <p data-testid="loading-indicator">Loading products…</p>;
  if (error)   return <p data-testid="error-message">Error: {error}</p>;
  if (products.length === 0)
    return <p data-testid="empty-state">No products found.</p>;

  return (
    <section aria-label="Product list">
      <h1>Products</h1>
      <div role="list" data-testid="product-list">
        {products.map((p) => (
          <ProductCard key={p.id} product={p} />
        ))}
      </div>
      <p data-testid="product-count">{products.length} product(s)</p>
    </section>
  );
}
