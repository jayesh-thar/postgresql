# PostgreSQL Interview Questions & Answers

> Answers are simple and interview-focused. All examples use PostgreSQL syntax.
>
> Note: My practice database uses `products.categories_id`. Some projects use `category_id`; use the column name that exists in your table.

---

# PART 1: DATABASE AND TABLE BASICS

## Q1. What is DBMS? What is RDBMS? Why is RDBMS useful?

**Answer:**

- **DBMS (Database Management System):** Software used to store, retrieve, update, and manage data.
- **RDBMS (Relational DBMS):** Stores data in tables connected through relationships and keys.

Examples of RDBMS: PostgreSQL, MySQL, SQL Server, Oracle.

| DBMS | RDBMS |
| --- | --- |
| General database management concept | A type of DBMS based on the relational model |
| May use different data models | Uses tables, rows, and columns |
| Relationships depend on the system | Supports relationships using keys and constraints |
| Data integrity depends on the system | Provides relational constraints and transactions |

**Why is RDBMS useful?**

It is useful when data has relationships, such as customers, orders, products, and payments. Primary keys, foreign keys, constraints, and transactions help maintain data integrity.

RDBMS is not always better than every other database. The right choice depends on the application's requirements.

## Q2. What is the difference between SQL and NoSQL?

**Answer:**

| SQL / Relational | NoSQL |
| --- | --- |
| Usually stores data in related tables | May store documents, key-value pairs, graphs, etc. |
| Often uses a predefined schema | Some systems support more flexible schemas |
| Supports joins and foreign keys, depending on the system | Relationships are often handled differently |
| Good for structured, relational data | Can be useful for flexible data models and particular scaling patterns |

Examples: PostgreSQL is relational; MongoDB is document-oriented.

Neither is universally better. Choose based on data structure, consistency needs, query patterns, and scaling requirements.

## Q3. What are DDL, DML, DQL, DCL, and TCL?

**Answer:**

| Category | Purpose | Common commands |
| --- | --- | --- |
| DDL | Defines or changes database structure | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` |
| DML | Changes data | `INSERT`, `UPDATE`, `DELETE` |
| DQL | Retrieves data | `SELECT` |
| DCL | Controls permissions | `GRANT`, `REVOKE` |
| TCL | Manages transactions | `BEGIN`, `COMMIT`, `ROLLBACK` |

**Example:**

```sql
-- DDL: create a table
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

-- DML: insert data
INSERT INTO students VALUES (1, 'Jay');

-- DQL: retrieve data
SELECT * FROM students;

-- DML: update data
UPDATE students SET name = 'Jayesh' WHERE id = 1;

-- DML: delete data
DELETE FROM students WHERE id = 1;
```

**Remember:** DDL deals with structure; DML deals with actual data.

## Q4. How do you create a database and connect to it?

**Answer:**

```sql
CREATE DATABASE practice_db;
```

In `psql`, connect to it using:

```text
\c practice_db
```

Other useful `psql` commands:

```text
\l                  -- List databases
\dt                 -- List tables
\d products         -- Describe a table
\dn                 -- List schemas
\q                  -- Exit psql
```

`\c` and `\dt` are `psql` commands, not SQL statements.

## Q5. How do you create a table?

**Answer:**

```sql
CREATE TABLE students (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    age SMALLINT,
    fees NUMERIC(8,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    joined_on DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

- `CREATE TABLE` creates the structure.
- Each column has a name and datatype.
- Constraints define the rules.
- `DEFAULT` supplies a value when a value is omitted or `DEFAULT` is specified.

## Q6. What is the difference between column-level and table-level constraints?

**Answer:**

**Column-level:**

```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    email TEXT UNIQUE NOT NULL
);
```

**Table-level:**

```sql
CREATE TABLE enrollments (
    student_id INTEGER,
    course_id INTEGER,
    CONSTRAINT pk_enrollments
        PRIMARY KEY (student_id, course_id)
);
```

Column-level constraints are written beside a column. Table-level constraints are written separately and can cover multiple columns, such as a composite primary key.

## Q7. What are common PostgreSQL datatypes?

**Answer:**

| Datatype | Use |
| --- | --- |
| `SMALLINT` | Small whole numbers |
| `INTEGER` | General whole numbers |
| `BIGINT` | Large whole numbers |
| `NUMERIC(8,2)` | Exact decimal values, such as prices |
| `REAL`, `DOUBLE PRECISION` | Approximate decimal values |
| `VARCHAR(n)`, `TEXT` | Text |
| `BOOLEAN` | `TRUE`, `FALSE`, or `NULL` |
| `DATE` | Date without time |
| `TIMESTAMP` | Date and time without timezone semantics |
| `TIMESTAMPTZ` | Timestamp representing an instant |
| `UUID` | 128-bit identifier |

Choose a datatype based on the meaning, precision, and valid range of the value.

## Q8. How do you insert data?

**Answer:**

```sql
INSERT INTO products (name, price, stock)
VALUES ('Mouse', 799.00, 50);
```

Insert multiple rows:

```sql
INSERT INTO products (name, price, stock)
VALUES
    ('Keyboard', 1499.00, 20),
    ('USB Hub', 999.00, 10);
```

See the inserted rows:

```sql
INSERT INTO products (name, price, stock)
VALUES ('Webcam', 1999.00, 5)
RETURNING id, name, price;
```

**Edge case:** If a column has a default, omit it or specify `DEFAULT`. Explicitly inserting `NULL` does not automatically use the default.

## Q9. How do you retrieve and filter data?

**Answer:**

```sql
SELECT name, price
FROM products
WHERE price > 1000
ORDER BY price DESC
LIMIT 5;
```

- `SELECT`: chooses columns.
- `WHERE`: filters rows.
- `ORDER BY`: sorts rows.
- `LIMIT`: restricts the number of rows returned.

Use `SELECT *` for exploration; selecting specific columns is generally clearer in application queries.

## Q10. How do you update data?

**Answer:**

```sql
UPDATE products
SET price = 1200,
    stock = stock + 5
WHERE id = 12
RETURNING id, name, price, stock;
```

`UPDATE` changes existing rows.

**Important:** Without `WHERE`, all rows are updated.

## Q11. How do you delete a particular row?

**Answer:**

```sql
DELETE FROM products
WHERE id = 12
RETURNING *;
```

`DELETE` removes rows, not the table structure.

Without `WHERE`, all rows are deleted.

## Q12. What is `ALTER TABLE`?

**Answer:**

`ALTER TABLE` changes the structure of an existing table.

**Add a column:**

```sql
ALTER TABLE products
ADD COLUMN description TEXT;
```

**Rename a column:**

```sql
ALTER TABLE products
RENAME COLUMN description TO details;
```

**Rename a table:**

```sql
ALTER TABLE products
RENAME TO items;
```

**Drop a column:**

```sql
ALTER TABLE products
DROP COLUMN details;
```

## Q13. How do you add a `NOT NULL` constraint to an existing column?

**Answer:**

First check for existing NULL values:

```sql
SELECT *
FROM products
WHERE sku IS NULL;
```

If required, fill the missing values:

```sql
UPDATE products
SET sku = 'SKU-' || LPAD(id::TEXT, 4, '0')
WHERE sku IS NULL;
```

Then enforce the rule:

```sql
ALTER TABLE products
ALTER COLUMN sku SET NOT NULL;
```

**Edge case:** Adding `NOT NULL` fails if existing rows contain NULL values. A new `NOT NULL` column on a populated table also needs a suitable default or a safe backfill process.

## Q14. How do you add a constraint after creating a table?

**Answer:**

```sql
ALTER TABLE products
ADD CONSTRAINT ck_products_price
CHECK (price >= 0);
```

Other examples:

```sql
ALTER TABLE products
ADD CONSTRAINT uq_products_sku UNIQUE (sku);

ALTER TABLE products
ADD CONSTRAINT ck_products_rating
CHECK (rating BETWEEN 0 AND 5);
```

Adding a constraint can fail if existing rows violate it.

**Edge case:** A `CHECK` constraint accepts NULL because its condition evaluates to UNKNOWN. Use `NOT NULL` as well if a value is mandatory.

## Q15. What are the types of constraints?

**Answer:**

| Constraint | Purpose |
| --- | --- |
| `PRIMARY KEY` | Uniquely identifies each row; cannot be NULL |
| `FOREIGN KEY` | Ensures a referenced record exists |
| `UNIQUE` | Prevents duplicate values or combinations |
| `NOT NULL` | Requires a value |
| `CHECK` | Enforces a condition |
| `DEFAULT` | Supplies a default value |

Example:

```sql
CREATE TABLE employees (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    salary NUMERIC(10,2) CHECK (salary > 0),
    status TEXT DEFAULT 'active'
);
```

## Q16. What is the difference between a primary key and a foreign key?

**Answer:**

- **Primary key (PK):** Uniquely identifies a row in its own table.
- **Foreign key (FK):** References a unique key in another table, enforcing referential integrity.

Example:

```sql
CREATE TABLE customers (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE orders (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id)
);
```

`orders.customer_id` references `customers.id`.

**Edge case:** A foreign key can be NULL unless `NOT NULL` is specified. Multiple orders can reference the same customer because the FK does not need to be unique.

## Q17. What is the difference between `PRIMARY KEY` and `UNIQUE`?

**Answer:**

| Primary Key | Unique |
| --- | --- |
| Only one PK constraint per table | Multiple UNIQUE constraints are allowed |
| Never permits NULL | By default, PostgreSQL permits multiple NULLs in a UNIQUE column |
| Uniquely identifies rows | Prevents duplicates in the constrained columns |

A table can have a composite primary key containing multiple columns, but it still has only one primary key constraint.

## Q18. What are `SERIAL`, `IDENTITY`, and `UUID`?

**Answer:**

**IDENTITY:**

```sql
id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

Automatically generates numeric IDs.

**SERIAL:**

```sql
id SERIAL PRIMARY KEY
```

Older PostgreSQL shorthand that uses a sequence-backed default.

**UUID:**

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

Generates a UUID rather than a sequential number.

Use `IDENTITY` for many ordinary new PostgreSQL tables. UUIDs are useful when identifiers need to be generated independently or should not expose a simple sequence.

**Important:** IDENTITY alone does not guarantee uniqueness; a primary key or unique constraint does that.

## Q19. How do you change a column datatype?

**Answer:**

```sql
ALTER TABLE products
ALTER COLUMN price TYPE NUMERIC(10,2);
```

Explicit conversion:

```sql
ALTER TABLE some_table
ALTER COLUMN code TYPE INTEGER
USING code::INTEGER;
```

The existing values must be convertible and fit the new datatype.

For example, converting `'abc'` to an integer fails.

## Q20. How do you add a foreign key to an existing table?

**Answer:**

```sql
ALTER TABLE products
ADD CONSTRAINT fk_products_category
FOREIGN KEY (categories_id)
REFERENCES categories(id);
```

The existing values in `products.categories_id` must either be NULL or match existing category IDs. Otherwise, adding the constraint fails.

## Q21. What is the difference between `DELETE`, `TRUNCATE`, and `DROP`?

**Answer:**

| Command | Effect | `WHERE` allowed? | Table remains? |
| --- | --- | --- | --- |
| `DELETE` | Removes selected rows | Yes | Yes |
| `TRUNCATE` | Removes all rows efficiently | No | Yes |
| `DROP TABLE` | Removes table and its data | No | No |

Examples:

```sql
DELETE FROM products WHERE id = 12;

TRUNCATE TABLE products RESTART IDENTITY;

DROP TABLE products;
```

`TRUNCATE ... RESTART IDENTITY` resets associated identity sequences.

**Rollback:** PostgreSQL supports rolling back `DELETE`, `TRUNCATE`, and `DROP TABLE` when executed inside a transaction that is rolled back.

```sql
BEGIN;
DELETE FROM products;
ROLLBACK;
```

The deleted rows are restored.

Sequence operations have some special behavior: ordinary sequence increments are not rolled back and can leave gaps.

## Q22. What does `RETURNING` do?

**Answer:**

It returns the rows affected by an `INSERT`, `UPDATE`, or `DELETE`.

```sql
UPDATE products
SET price = price + 100
WHERE id = 12
RETURNING id, name, price;
```

This is useful in applications because you can get the updated values without running another query.

## Q23. What is the difference between `NULL` and `DEFAULT`?

**Answer:**

- `NULL` represents a missing or unknown value.
- `DEFAULT` requests the column's defined default value.

Example:

```sql
CREATE TABLE demo (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stock INTEGER DEFAULT 0
);

INSERT INTO demo (stock) VALUES (DEFAULT);
INSERT INTO demo (stock) VALUES (NULL);
```

The first row gets `0`; the second gets NULL if the column allows it.

## Q24. Why should `UPDATE` and `DELETE` use a `WHERE` clause?

**Answer:**

`WHERE` restricts which rows are affected.

```sql
UPDATE products
SET stock = 0
WHERE id = 12;
```

Without `WHERE`, every row is changed. Before a risky change, run a `SELECT` with the same condition to inspect the target rows.

## Q25. What is a transaction? Explain `COMMIT` and `ROLLBACK`

**Answer:**

A transaction groups database operations into one unit.

```sql
BEGIN;

UPDATE products
SET price = price + 100
WHERE id = 12;

SELECT * FROM products WHERE id = 12;

ROLLBACK;
```

- `BEGIN`: starts the transaction.
- `COMMIT`: saves the changes.
- `ROLLBACK`: undoes uncommitted transactional changes.

Use transactions when several operations must succeed or fail together.

## Q26. What is the difference between `DROP TABLE` and `ALTER TABLE ... DROP COLUMN`?

**Answer:**

```sql
DROP TABLE products;
```

Removes the entire table.

```sql
ALTER TABLE products
DROP COLUMN rating;
```

Removes only the `rating` column; the table and other columns remain.

## Q27. How do you remove a constraint?

**Answer:**

```sql
ALTER TABLE products
DROP CONSTRAINT ck_products_price;
```

Use `\d products` in `psql` to inspect the table and its constraint names.

## Q28. What is the difference between a database and a schema?

**Answer:**

A database is a logical database environment. A schema is a namespace inside a database that organizes objects such as tables, views, and functions.

PostgreSQL supports multiple schemas inside one database, such as `public` and `sales`.

## Q29. What is referential integrity?

**Answer:**

Referential integrity ensures that relationships between tables remain valid. A foreign key prevents a child row from referencing a missing parent row.

```sql
FOREIGN KEY (customer_id)
REFERENCES customers(id)
```

If a customer is referenced by an order, PostgreSQL normally prevents deleting that customer unless an appropriate delete rule is configured.

## Q30. What is the difference between `ON DELETE CASCADE` and `ON DELETE SET NULL`?

**Answer:**

- `ON DELETE CASCADE`: deletes dependent child rows when the parent is deleted.
- `ON DELETE SET NULL`: keeps the child row but sets its FK to NULL.

Example:

```sql
FOREIGN KEY (customer_id)
REFERENCES customers(id)
ON DELETE CASCADE
```

Use CASCADE only when deleting the parent should also delete the dependent data. For independent records or financial history, restricting deletion may be safer.

---

# PART 2: KEYS, RELATIONSHIPS, AND NORMALIZATION

## Q31. What are the different types of keys?

**Answer:**

| Key | Meaning |
| --- | --- |
| Super key | Any set of columns that uniquely identifies a row |
| Candidate key | Minimal super key |
| Primary key | Candidate key chosen to identify rows |
| Alternate key | Candidate key not selected as the primary key |
| Composite key | Key made from multiple columns |
| Foreign key | Column(s) referencing a key in another table |
| Natural key | Real-world identifier, such as an ISBN |
| Surrogate key | Artificial identifier, such as an identity ID |

Example: `(student_id, course_id)` can be a composite primary key for an enrollment table.

## Q32. What is relationship cardinality?

**Answer:**

Cardinality describes how many rows can relate between tables.

| Relationship | Example | Implementation |
| --- | --- | --- |
| One-to-one (1:1) | Person and passport | FK + UNIQUE |
| One-to-many (1:N) | Category and products | FK on the many side |
| Many-to-many (M:N) | Students and courses | Junction table with two FKs |

**One-to-one:**

```sql
CREATE TABLE passports (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_id INTEGER UNIQUE NOT NULL REFERENCES persons(id)
);
```

**One-to-many:**

```sql
CREATE TABLE products (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    categories_id INTEGER REFERENCES categories(id)
);
```

**Many-to-many:**

```sql
CREATE TABLE enrollments (
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    PRIMARY KEY (student_id, course_id)
);
```

## Q33. What is normalization? Why is it needed?

**Answer:**

Normalization organizes data to reduce unnecessary duplication and prevent inconsistencies.

It helps avoid:

- **Update anomaly:** The same fact is updated in one row but not another.
- **Insert anomaly:** A fact cannot be stored without an unrelated fact.
- **Delete anomaly:** Deleting one record accidentally removes another useful fact.

## Q34. Explain 1NF, 2NF, 3NF, and BCNF

**Answer:**

| Form | Main rule |
| --- | --- |
| 1NF | Each cell contains one atomic value; no repeating groups |
| 2NF | In 1NF, and non-key attributes depend on the whole candidate key |
| 3NF | In 2NF, and non-key attributes do not depend transitively on candidate keys |
| BCNF | Every determinant is a candidate key |

Example: Do not repeatedly store `customer_email` in every order row. Store customer details in `customers` and reference the customer using `customer_id`.

Normalization improves consistency. Sometimes read-heavy systems deliberately denormalize data after measuring performance needs.

---

# PART 3: QUERY CLAUSES AND FILTERING

## Q35. What is a clause in SQL?

**Answer:**

A clause is a part of an SQL statement that performs a particular job.

Common clauses:

| Clause | Purpose |
| --- | --- |
| `FROM` | Specifies source tables |
| `JOIN` / `ON` | Connects related rows |
| `WHERE` | Filters individual rows |
| `GROUP BY` | Forms groups |
| `HAVING` | Filters groups |
| `SELECT` | Specifies output columns and expressions |
| `ORDER BY` | Sorts results |
| `LIMIT` / `OFFSET` | Restricts or paginates results |

## Q36. In what order does SQL process a SELECT query?

**Answer:**

A simplified logical order is:

1. `FROM` and `JOIN`
2. `WHERE`
3. `GROUP BY`
4. `HAVING`
5. `SELECT`
6. `DISTINCT`
7. `ORDER BY`
8. `LIMIT` / `OFFSET`

This explains why a SELECT alias usually cannot be used in `WHERE`: the alias is defined later in the logical processing order.

## Q37. What is the difference between `WHERE` and `ORDER BY`?

**Answer:**

`WHERE` filters rows; `ORDER BY` sorts them.

```sql
SELECT name, price
FROM products
WHERE price > 1000
ORDER BY price DESC;
```

This first selects products priced over 1000, then sorts those products from highest price to lowest.

## Q38. What is the difference between `GROUP BY` and `ORDER BY`?

**Answer:**

`GROUP BY` combines rows with the same grouping values so aggregate functions can calculate a result per group. `ORDER BY` sorts the resulting rows.

```sql
SELECT categories_id, COUNT(*) AS total
FROM products
GROUP BY categories_id
ORDER BY total DESC;
```

This calculates the product count per category and then sorts categories by product count.

## Q39. What is `LIMIT` and `OFFSET`?

**Answer:**

- `LIMIT` specifies the maximum number of returned rows.
- `OFFSET` skips a number of rows before returning results.

```sql
SELECT id, name
FROM products
ORDER BY id
LIMIT 5 OFFSET 5;
```

This skips the first five ordered rows and returns the next five.

Always use a stable `ORDER BY` for predictable pagination.

## Q40. What are `LIKE` and `ILIKE`?

**Answer:**

They match text patterns.

- `%`: any number of characters.
- `_`: exactly one character.
- `LIKE`: case-sensitive pattern matching in PostgreSQL.
- `ILIKE`: case-insensitive pattern matching.

```sql
SELECT name FROM products WHERE name LIKE 'Gaming%';
SELECT name FROM products WHERE name LIKE '%Mouse%';
SELECT name FROM products WHERE name ILIKE '%webcam%';
```

`LIKE 'Gaming%'` matches names starting with `Gaming`. It is not the same as `= 'Gaming%'`, which looks for that literal text.

## Q41. What is `IN`?

**Answer:**

`IN` checks whether a value matches any value in a list or query result.

```sql
SELECT name
FROM customers
WHERE id IN (
    SELECT customer_id
    FROM orders
);
```

The subquery returns customer IDs that occur in orders. The outer query returns customers whose IDs belong to that set.

`IN` can evaluate to TRUE, FALSE, or NULL when NULL values are involved.

## Q42. What is `EXISTS`? Why use `SELECT 1`?

**Answer:**

`EXISTS` checks whether a subquery returns at least one row.

```sql
SELECT c.name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
);
```

The subquery finds orders belonging to each customer. Customers with at least one matching order pass the condition.

`SELECT 1` returns a constant for each matching row. `EXISTS` only cares whether rows exist, not what values they contain. `SELECT *` would also work here.

Use `EXISTS` for questions such as "Does this customer have an order?" without needing to return order details.

## Q43. What is the difference between `IN` and `EXISTS`?

**Answer:**

| `IN` | `EXISTS` |
| --- | --- |
| Checks whether a value belongs to a result set | Checks whether a matching row exists |
| Often compares a value or a pair | Often uses a correlated subquery |
| Useful for membership tests | Useful for existence tests |

Both can often express the same requirement. The optimizer chooses a plan based on the query and data.

## Q44. Why can `NOT IN` behave unexpectedly with NULL?

**Answer:**

If a `NOT IN` subquery returns NULL, comparisons can become UNKNOWN instead of TRUE.

For example, a comparison such as `5 NOT IN (1, 2, NULL)` is not TRUE, so it does not pass a `WHERE` filter.

For finding rows with no matching related record, `NOT EXISTS` is often safer:

```sql
SELECT c.name
FROM categories c
WHERE NOT EXISTS (
    SELECT 1
    FROM products p
    WHERE p.categories_id = c.id
);
```

## Q45. What is `DISTINCT`?

**Answer:**

`DISTINCT` removes duplicate output rows.

```sql
SELECT DISTINCT categories_id
FROM products;
```

It returns each distinct category ID only once. NULL is also treated as one distinct output value for this purpose.

---

# PART 4: AGGREGATION, GROUP BY, HAVING, AND NULL

## Q46. What are aggregate functions?

**Answer:**

Aggregate functions calculate one result from multiple rows.

| Function | Purpose |
| --- | --- |
| `COUNT(*)` | Counts all rows |
| `COUNT(column)` | Counts non-NULL values |
| `SUM(column)` | Adds non-NULL values |
| `AVG(column)` | Averages non-NULL values |
| `MIN(column)` | Smallest value |
| `MAX(column)` | Largest value |

Example:

```sql
SELECT
    COUNT(*) AS total_products,
    AVG(price) AS average_price,
    MIN(price) AS lowest_price,
    MAX(price) AS highest_price
FROM products;
```

## Q47. How does `GROUP BY` work with aggregates?

**Answer:**

`GROUP BY` creates one group for each distinct grouping value.

```sql
SELECT categories_id, COUNT(*) AS product_count
FROM products
GROUP BY categories_id;
```

This returns one row per category ID.

Every selected column must either appear in `GROUP BY` or be used inside an aggregate function, subject to PostgreSQL's functional-dependency rules.

## Q48. What is the difference between `WHERE` and `HAVING`?

**Answer:**

- `WHERE` filters individual rows before grouping.
- `HAVING` filters groups after grouping and aggregation.

```sql
SELECT categories_id, AVG(price) AS average_price
FROM products
WHERE price > 1000
GROUP BY categories_id
HAVING AVG(price) > 2000;
```

Processing:

1. `WHERE`: keeps products priced over 1000.
2. `GROUP BY`: groups the remaining products by category.
3. `HAVING`: keeps categories whose average price is over 2000.
4. `SELECT`: displays the category and average.

Use `WHERE` for row-level conditions and `HAVING` for aggregate conditions.

## Q49. What is `COALESCE()`?

**Answer:**

`COALESCE()` returns the first non-NULL expression.

```sql
SELECT name, COALESCE(rating, 0) AS rating
FROM products;
```

If `rating` is NULL, the query displays `0`. Otherwise, it displays the actual rating.

**Important:** This changes the query output, not the stored table value.

## Q50. How do aggregates handle NULL?

**Answer:**

```sql
SELECT
    COUNT(*) AS all_rows,
    COUNT(rating) AS rated_rows,
    AVG(rating) AS average_rating,
    AVG(COALESCE(rating, 0)) AS average_with_missing_as_zero
FROM products;
```

- `COUNT(*)` counts all rows.
- `COUNT(rating)` counts only non-NULL ratings.
- `AVG(rating)` ignores NULL ratings.
- `AVG(COALESCE(rating, 0))
