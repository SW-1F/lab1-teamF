-- ============================================================
-- Saleor Platform - DB Unit Tests: Schema Setup
-- Tier: Database (PostgreSQL)
-- Functional Flow: Product Listing
-- Based on: saleor/saleor-platform -> saleor/product/models.py
-- ============================================================

DROP TABLE IF EXISTS product_productvariant CASCADE;
DROP TABLE IF EXISTS product_product CASCADE;
DROP TABLE IF EXISTS product_category CASCADE;
DROP TABLE IF EXISTS product_producttype CASCADE;

-- Product Type (dependency for Product FK)
CREATE TABLE product_producttype (
    id SERIAL PRIMARY KEY,
    name VARCHAR(250) NOT NULL,
    has_variants BOOLEAN NOT NULL DEFAULT TRUE,
    is_shipping_required BOOLEAN NOT NULL DEFAULT TRUE
);

-- Category
CREATE TABLE product_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(250) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description JSONB,
    parent_id INTEGER REFERENCES product_category(id) ON DELETE SET NULL
);

-- Product (core table under test)
CREATE TABLE product_product (
    id SERIAL PRIMARY KEY,
    name VARCHAR(250) NOT NULL,
    description JSONB,
    product_type_id INTEGER NOT NULL REFERENCES product_producttype(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES product_category(id) ON DELETE SET NULL,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    slug VARCHAR(255) NOT NULL UNIQUE,
    rating NUMERIC(5, 2)
);

-- Product Variant (to test ON DELETE CASCADE)
CREATE TABLE product_productvariant (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(255) UNIQUE,
    name VARCHAR(255) NOT NULL DEFAULT '',
    product_id INTEGER NOT NULL REFERENCES product_product(id) ON DELETE CASCADE
);

-- Seed base data used across all tests
INSERT INTO product_producttype (name, has_variants, is_shipping_required)
VALUES ('Physical Product', TRUE, TRUE);

INSERT INTO product_category (name, slug)
VALUES ('Electronics', 'electronics');
