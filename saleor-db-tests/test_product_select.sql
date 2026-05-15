-- ============================================================
-- TEST: Product SELECT / Filter queries
-- Tier: Database (PostgreSQL)
-- Description: Verifies SELECT queries correctly filter and
--              JOIN product data (mirrors Saleor's ORM queries).
-- ============================================================

-- 1) Count all published products
SELECT COUNT(*) AS published_count
FROM product_product
WHERE is_published = TRUE;
-- Expected: >= 1

-- 2) Fetch a product by slug (Saleor uses slug as public identifier)
SELECT name, slug, is_published
FROM product_product
WHERE slug = 'saleor-test-laptop';
-- Expected: 1 row -> name='Saleor Test Laptop', is_published=true

-- 3) JOIN: product + category (mirrors Saleor's prefetch_related usage)
SELECT p.name AS product_name, c.name AS category_name
FROM product_product p
JOIN product_category c ON p.category_id = c.id
WHERE p.slug = 'saleor-test-laptop';
-- Expected: 1 row -> product_name='Saleor Test Laptop', category_name='Electronics'

-- 4) Filter unpublished (draft) products (mirrors dashboard draft view)
SELECT COUNT(*) AS draft_count
FROM product_product
WHERE is_published = FALSE;
-- Expected: 0 (none inserted as drafts yet)
