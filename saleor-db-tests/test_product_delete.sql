-- ============================================================
-- TEST: Product DELETE (with ON DELETE CASCADE)
-- Tier: Database (PostgreSQL)
-- Description: Verifies product deletion also removes linked
--              variants due to the CASCADE constraint.
--              Mirrors Saleor's productDelete mutation behavior.
-- ============================================================

-- Setup: insert a variant for the existing product
INSERT INTO product_productvariant (sku, name, product_id)
VALUES (
    'LAPTOP-SKU-001',
    'Default Variant',
    (SELECT id FROM product_product WHERE slug = 'saleor-test-laptop')
);

-- Verify variant exists before delete
SELECT COUNT(*) AS variant_before
FROM product_productvariant WHERE sku = 'LAPTOP-SKU-001';
-- Expected: variant_before = 1

-- Delete the product
DELETE FROM product_product WHERE slug = 'saleor-test-laptop';

-- Verify: product is gone
SELECT COUNT(*) AS product_after
FROM product_product WHERE slug = 'saleor-test-laptop';
-- Expected: product_after = 0

-- Verify: variant was cascade-deleted automatically
SELECT COUNT(*) AS variant_after
FROM product_productvariant WHERE sku = 'LAPTOP-SKU-001';
-- Expected: variant_after = 0
