-- ============================================================
-- TEST: Product INSERT
-- Tier: Database (PostgreSQL)
-- Description: Verifies a product can be inserted with valid
--              required fields and is retrievable afterwards.
-- ============================================================

-- Insert a published product linked to existing type and category
INSERT INTO product_product (name, product_type_id, category_id, is_published, slug)
VALUES (
    'Saleor Test Laptop',
    (SELECT id FROM product_producttype WHERE name = 'Physical Product'),
    (SELECT id FROM product_category WHERE slug = 'electronics'),
    TRUE,
    'saleor-test-laptop'
);

-- Verify: product exists with correct data
SELECT COUNT(*) AS total
FROM product_product
WHERE name = 'Saleor Test Laptop'
  AND is_published = TRUE
  AND slug = 'saleor-test-laptop';
-- Expected output: total = 1
