-- ============================================================
-- TEST: Product INSERT
-- Tier: Database (PostgreSQL)
-- Description: Verifies a product can be inserted with valid
--              required fields and is retrievable afterwards.
-- ============================================================

-- Ensure deterministic state for this test target
DELETE FROM product_product WHERE slug = 'saleor-test-laptop';

-- Insert a published product linked to existing type and category
INSERT INTO product_product (name, product_type_id, category_id, is_published, slug)
VALUES (
    'Saleor Test Laptop',
    (SELECT id FROM product_producttype WHERE name = 'Physical Product'),
    (SELECT id FROM product_category WHERE slug = 'electronics'),
    TRUE,
    'saleor-test-laptop'
);

-- Assert exactly one matching product exists
DO $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM product_product
        WHERE name = 'Saleor Test Laptop'
          AND is_published = TRUE
          AND slug = 'saleor-test-laptop'
    ) <> 1 THEN
        RAISE EXCEPTION 'FAILED: expected exactly 1 inserted product with slug saleor-test-laptop';
    END IF;
END $$;
SELECT 'PASSED: product insert test' AS result;
