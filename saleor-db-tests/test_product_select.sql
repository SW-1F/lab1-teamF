-- ============================================================
-- TEST: Product SELECT / Filter queries
-- Tier: Database (PostgreSQL)
-- Description: Verifies SELECT queries correctly filter and
--              JOIN product data (mirrors Saleor's ORM queries).
-- ============================================================

-- 1) Count all published products
DO $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM product_product
        WHERE is_published = TRUE
    ) < 1 THEN
        RAISE EXCEPTION 'FAILED: expected at least 1 published product';
    END IF;
END $$;
-- Expected: >= 1

-- 2) Fetch a product by slug (Saleor uses slug as public identifier)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM product_product
        WHERE slug = 'saleor-test-laptop'
          AND name = 'Saleor Test Laptop'
          AND is_published = TRUE
    ) THEN
        RAISE EXCEPTION 'FAILED: expected product saleor-test-laptop to exist and be published';
    END IF;
END $$;
-- Expected: 1 row -> name='Saleor Test Laptop', is_published=true

-- 3) JOIN: product + category (mirrors Saleor's prefetch_related usage)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM product_product p
        JOIN product_category c ON p.category_id = c.id
        WHERE p.slug = 'saleor-test-laptop'
          AND p.name = 'Saleor Test Laptop'
          AND c.name = 'Electronics'
    ) THEN
        RAISE EXCEPTION 'FAILED: expected JOIN to return product/category pair Saleor Test Laptop / Electronics';
    END IF;
END $$;
-- Expected: 1 row -> product_name='Saleor Test Laptop', category_name='Electronics'

-- 4) Filter unpublished (draft) products (mirrors dashboard draft view)
DO $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM product_product
        WHERE is_published = FALSE
    ) <> 0 THEN
        RAISE EXCEPTION 'FAILED: expected 0 draft products before update test';
    END IF;
END $$;
-- Expected: 0 (none inserted as drafts yet)

SELECT 'PASSED: product select test' AS result;
