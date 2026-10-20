-- # ex:

-- \set ON_ERROR_STOP on

-- DROP TABLE IF EXISTS products;
-- DROP TABLE IF EXISTS categories;

-- \i schema/01_products.sql
-- \i schema/02_categories.sql
-- \i seed/01_products_seed.sql
-- \i seed/02_categories_seed.sql

-- SELECT (SELECT count(*) FROM categories) AS categories,
--        (SELECT count(*) FROM products)   AS products;

