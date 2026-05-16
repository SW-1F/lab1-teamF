-- ============================================================
-- TEST: Product DELETE (with ON DELETE CASCADE)
-- Tier: Database (PostgreSQL)
-- Description: Verifies product deletion also removes linked
--              variants due to the CASCADE constraint.
--              Mirrors Saleor's productDelete mutation behavior.
-- ============================================================

-- Ensure deterministic state for the variant
DELETE FROM product_productvariant WHERE sku = 'LAPTOP-SKU-001';

-- Setup: insert a variant for the existing product
INSERT INTO product_productvariant (sku, name, product_id)
VALUES (
    'LAPTOP-SKU-001',
    'Default Variant',
    (SELECT id FROM product_product WHERE slug = 'saleor-test-laptop')
);

-- Verify variant exists before delete
DO $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM product_productvariant
        WHERE sku = 'LAPTOP-SKU-001'
    ) <> 1 THEN
        RAISE EXCEPTION 'FAILED: expected variant LAPTOP-SKU-001 to exist before delete';
    END IF;
END $$;
-- Expected: variant_before = 1

-- Delete the product
DELETE FROM product_product
WHERE slug = 'saleor-test-laptop';

-- Verify: product is gone
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM product_product
        WHERE slug = 'saleor-test-laptop'
    ) THEN
        RAISE EXCEPTION 'FAILED: expected product saleor-test-laptop to be deleted';
    END IF;
END $$;
-- Expected: product_after = 0

-- Verify: variant was cascade-deleted automatically
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM product_productvariant
        WHERE sku = 'LAPTOP-SKU-001'
    ) THEN
        RAISE EXCEPTION 'FAILED: expected variant LAPTOP-SKU-001 to be cascade-deleted';
    END IF;
END $$;
-- Expected: variant_after = 0

SELECT 'PASSED: product delete cascade test' AS result;
