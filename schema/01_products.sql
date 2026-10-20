-- create table products (
-- 	id integer generated always as identity primary key,
-- 	name varchar(100) not null,
-- 	price numeric(8, 2) not null, 
-- 	stock smallint default 0,
-- 	rating numeric(2, 1),
-- 	is_active boolean default true,
-- 	launched_on date,
-- 	created_at timestamptz default now()
-- );


-- # Different way of writting with constraint and it's name specific.
-- 
-- CREATE TABLE products (
--     id           integer GENERATED ALWAYS AS IDENTITY,
--     name         varchar(100) NOT NULL,
--     price        numeric(8,2) NOT NULL,
--     stock        smallint DEFAULT 0,
--     rating       numeric(2,1),
--     is_active    boolean DEFAULT true,
--     launched_on  date,
--     category_id  integer,
--     created_at   timestamptz DEFAULT now(),
--     CONSTRAINT pk_products PRIMARY KEY (id),
--     CONSTRAINT uq_products_name UNIQUE (name),
--     CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories (id),
--     CONSTRAINT ck_products_price_non_negative CHECK (price >= 0),
--     CONSTRAINT ck_products_stock_non_negative CHECK (stock >= 0),
--     CONSTRAINT ck_products_rating_range CHECK (rating BETWEEN 0 AND 5)
-- );

-- select * from products;

-- DROP TABLE IF EXISTS products;

select * from products;













