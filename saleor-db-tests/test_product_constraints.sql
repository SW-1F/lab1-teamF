-- ============================================================
-- TEST: Constraint Violations (optional, recommended)
-- Tier: Database (PostgreSQL)
-- Description: Tests that integrity constraints are enforced.
-- ============================================================

-- Test 1: NOT NULL constraint on 'name'
-- Expect ERROR: null value in column "name" violates not-null constraint
INSERT INTO product_product (name, product_type_id, slug)
VALUES (NULL, 1, 'null-name-test');

-- Test 2: UNIQUE constraint on 'slug'
-- Insert the same slug twice — second should fail
INSERT INTO product_product (name, product_type_id, slug) VALUES ('Dup A', 1, 'dup-slug-test');
INSERT INTO product_product (name, product_type_id, slug) VALUES ('Dup B', 1, 'dup-slug-test');
-- Expect ERROR: duplicate key value violates unique constraint

-- Test 3: FK constraint — invalid product_type_id
INSERT INTO product_product (name, product_type_id, slug)
VALUES ('Bad FK', 99999, 'bad-fk-test');
-- Expect ERROR: insert or update on table "product_product" violates foreign key constraint
