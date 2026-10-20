-- -- Casting

-- SELECT CAST('42' AS text);      -- standard way
-- SELECT '42'::text;              -- PostgreSQL shortcut


-- SELECT now();
-- SELECT now() + interval '7 days';
-- SELECT now() - interval '3 hours';

---------------------------------------------------------------------------







BEGIN;
delete from reviews 
ROLLBACK;




