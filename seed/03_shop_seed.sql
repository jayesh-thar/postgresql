-- INSERT INTO
--     customers (name, city, referred_by, joined_on)
-- VALUES
--     ('Aarav', 'Rajkot', NULL, '2026-01-10'),
--     ('Meera', 'Ahmedabad', 1, '2026-02-15'),
--     ('Karan', 'Rajkot', 1, '2026-03-20'),
--     ('Isha', 'Surat', 2, '2026-05-05'),
--     ('Rohan', 'Mumbai', NULL, '2026-06-18'),
--     ('Tanvi', 'Pune', 3, '2026-08-02');

-- INSERT INTO
--     orders (customer_id, ordered_at, status)
-- VALUES
--     (1, '2026-09-01', 'delivered'),
--     (1, '2026-09-20', 'shipped'),
--     (2, '2026-09-05', 'delivered'),
--     (2, '2026-10-02', 'placed'),
--     (3, '2026-09-12', 'cancelled'),
--     (4, '2026-10-05', 'delivered'),
--     (4, '2026-10-10', 'placed'),
--     (1, '2026-10-12', 'placed');

INSERT INTO
    order_items (order_id, product_id, quantity, unit_price)
VALUES
    (1, 12, 2, 799.00),
    (1, 15, 1, 999.00),
    (2, 13, 1, 3499.00),
    (2, 12, 1, 799.00),
    (3, 17, 1, 5999.00),
    (3, 18, 2, 599.00),
    (4, 30, 1, 1999.00),
    (5, 38, 1, 7499.00),
    (6, 21, 3, 349.00),
    (6, 37, 1, 2999.00),
    (6, 39, 1, 3499.00),
    (8, 12, 1, 799.00),
    (8, 14, 2, 1299.50);