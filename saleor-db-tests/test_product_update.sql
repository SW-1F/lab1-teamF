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
DO $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM product_product
        WHERE slug = 'saleor-test-laptop'
          AND name = 'Saleor Test Laptop - Updated'
          AND is_published = FALSE
    ) <> 1 THEN
        RAISE EXCEPTION 'FAILED: expected updated product with new name and unpublished status';
    END IF;
END $$;
-- Expected: updated_count = 1

-- Verify: old name no longer exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM product_product
        WHERE slug = 'saleor-test-laptop'
          AND name = 'Saleor Test Laptop'
          AND is_published = TRUE
    ) THEN
        RAISE EXCEPTION 'FAILED: expected old product state to be gone after update';
    END IF;
END $$;
-- Expected: old_count = 0

SELECT 'PASSED: product update test' AS result;
