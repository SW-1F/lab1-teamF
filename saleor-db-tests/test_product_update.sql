-- ============================================================
-- TEST: Product UPDATE
-- Tier: Database (PostgreSQL)
-- Description: Verifies product fields can be updated correctly.
--              Mirrors Saleor's productUpdate mutation behavior.
-- ============================================================

-- Update name and unpublish the product (set as draft)
UPDATE product_product
SET name = 'Saleor Test Laptop - Updated',
    is_published = FALSE
WHERE slug = 'saleor-test-laptop';

-- Verify: name was changed
SELECT COUNT(*) AS updated_count
FROM product_product
WHERE name = 'Saleor Test Laptop - Updated'
  AND slug = 'saleor-test-laptop';
-- Expected: updated_count = 1

-- Verify: old name no longer exists
SELECT COUNT(*) AS old_count
FROM product_product
WHERE name = 'Saleor Test Laptop';
-- Expected: old_count = 0

-- Verify: product is now unpublished
SELECT is_published
FROM product_product
WHERE slug = 'saleor-test-laptop';
-- Expected: is_published = false
