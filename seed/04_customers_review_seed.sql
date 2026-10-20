-- TRUNCATE TABLE reviews RESTART IDENTITY;


INSERT INTO reviews
    (customer_id, product_id, rating, body, reviewed_on)
VALUES
    (1, 12, 5, 'Great mouse', '2026-09-10'),
    (1, 15, 4, 'Sturdy stand', '2026-09-11'),
    (1, 14, 5, NULL, '2026-10-01'),
    (2, 17, 5, 'Best headphones', '2026-09-15'),
    (2, 18, 3, 'Charger gets warm', '2026-09-16'),
    (3, 16, 2, 'Never arrived', '2026-09-20'),
    (4, 13, 4, 'Nice keyboard', '2026-10-08'),
    (4, 30, 3, NULL, '2026-10-09'),
    (4, 38, 5, 'Perfect controller', '2026-10-09'),
    (5, 12, 4, 'Bought from a friend', '2026-10-10'),
    (2, 12, 4, 'Works well', '2026-10-11'),
    (6, 39, 1, 'Stopped working', '2026-10-12'),
    (1, 14, 3, 'Okay hub', '2026-10-13'),
    (3, 37, 4, 'Decent webcam', '2026-10-14'),
    (1, 31, 5, 'Demo product review', '2026-10-14'),
    (1, 12, 4, 'Update: still good', '2026-10-15');