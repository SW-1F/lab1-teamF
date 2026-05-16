-- ============================================================
-- TEST: Constraint Violations
-- Tier: Database (PostgreSQL)
-- Description: Tests that integrity constraints are enforced.
-- ============================================================

-- Clean possible leftovers
DELETE FROM product_product
WHERE slug IN ('null-name-test', 'dup-slug-test', 'bad-fk-test');

-- Test 1: NOT NULL constraint on 'name'
-- Expect ERROR: null value in column "name" violates not-null constraint
DO $$
BEGIN
    BEGIN
        INSERT INTO product_product (name, product_type_id, slug)
        VALUES (
            NULL,
            (SELECT id FROM product_producttype WHERE name = 'Physical Product'),
            'null-name-test'
        );
        RAISE EXCEPTION 'FAILED: expected NOT NULL violation was not raised';
    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE 'PASSED: NOT NULL constraint enforced';
    END;
END $$;

-- Test 2: UNIQUE constraint on 'slug'
-- Insert the same slug twice — second should fail
DO $$
BEGIN
    INSERT INTO product_product (name, product_type_id, slug)
    VALUES (
        'Dup A',
        (SELECT id FROM product_producttype WHERE name = 'Physical Product'),
        'dup-slug-test'
    );
    BEGIN
        INSERT INTO product_product (name, product_type_id, slug)
        VALUES (
            'Dup B',
            (SELECT id FROM product_producttype WHERE name = 'Physical Product'),
            'dup-slug-test'
        );
        RAISE EXCEPTION 'FAILED: expected UNIQUE violation was not raised';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'PASSED: UNIQUE constraint enforced';
    END;
END $$;
-- Expect ERROR: duplicate key value violates unique constraint

-- Test 3: FK constraint — invalid product_type_id
DO $$
BEGIN
    BEGIN
        INSERT INTO product_product (name, product_type_id, slug)
        VALUES ('Bad FK', 99999, 'bad-fk-test');
        RAISE EXCEPTION 'FAILED: expected FK violation was not raised';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'PASSED: FK constraint enforced';
    END;
END $$;
-- Expect ERROR: insert or update on table "product_product" violates foreign key constraint

SELECT 'PASSED: constraint tests completed' AS result;
