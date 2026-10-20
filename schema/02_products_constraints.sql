-- -- create temp table demo (email text UNIQUE);
-- -- insert into demo(email) VALUES('jayesh@gmail.com');
-- -- select * from demo;

-- -- insert into demo(email) VALUES(NULL);
-- -- select * from demo;
-- -- insert into demo(email) VALUES('hi');
-- -- select * from demo;
-- insert into demo(email) VALUES('hi');
-- select * from demo;


-- alter table products 
--     ADD COLUMN categories_id integer REFERENCES categories(id);


UPDATE products set categories_id = 1 where name in ('Wireless Mouse', 'USB-C Hub', 'Laptop Stand', 'Phone Charger 20W');
update products set categories_id = 2 where name = 'Noise Cancelling Headphones';
update products set categories_id = 3 where name in ('Mechanical Keyboard', 'Webcam HD');






