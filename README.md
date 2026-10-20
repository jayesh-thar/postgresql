# MY POSTGRESQL NOTES

My own language notes, same sentences, just organised in one flow (basic -> intermediate).

---

## 0. How to read this file

- Lines I wrote are kept in my own words (only typo fixes in code).
- ➕ = topic added because it was missing in my notes. Keep it short, rewrite in own words when revising.
- ✏️ = something wrong in the old notes, corrected (reason is written next to it).
- Naming: my old practice table used `categories_id`, the project files (`reset_db.sql`) use `category_id`. Use the one that exists in your table, check with `\d products`.
  Rename if needed: `ALTER TABLE products RENAME COLUMN categories_id TO category_id;`
- Numbers in comments like `-- 20, 17, 4` come from the project seed data (20 products). My own DB has different rows, so my numbers can differ.
- Never write real passwords in notes.

## Contents

1. Basics, install, psql, pgAdmin, files, folders
2. Datatypes
3. Create table, CRUD, identity / uuid
4. Keys, constraints, foreign keys, ALTER TABLE
5. Relationships and normalization
6. NULL deep dive
7. Querying: order of execution, WHERE, LIKE, IN, ORDER BY, LIMIT, DISTINCT
8. Aggregates, FILTER, GROUP BY, HAVING
9. Functions: string, date/time, casting, CASE
10. Joins
11. Subqueries, EXISTS, CTE, set operations
12. Window functions
13. JSON / JSONB
14. Transactions (basic)
15. Interview quick facts
16. Common errors
17. Not covered yet

---

## 1. Basics, install, psql, pgAdmin, files, folders

### 1.1 DBMS, RDBMS, SQL vs NoSQL ➕

- DBMS: software to store, manage and read data.
- RDBMS: DBMS that keeps data in tables (rows + columns), tables are connected with keys, and we use SQL. ex: PostgreSQL, MySQL.

| | SQL (relational) | NoSQL (ex: MongoDB) |
| --- | --- | --- |
| Structure | fixed schema, tables | flexible: documents, key-value |
| Relations | joins + foreign keys | usually embedded or manual |
| Consistency | strong (ACID) | often relaxed for scale |
| Good for | data with many relations (banking, e-commerce, instagram-like app) | changing structure, huge scale, logs |

- PostgreSQL: most feature-rich (JSONB, window functions, CTE, extensions). MySQL: popular and simpler. SQLite: single file, no server (mobile apps, local testing).
- ACID (ex: transfer 500 from A to B):
  - Atomicity: both debit + credit happen, or neither.
  - Consistency: rules (constraints) never broken.
  - Isolation: two transfers at same time don't corrupt each other.
  - Durability: once committed, data survives a crash.

### 1.2 Install and tools ➕

Windows (what I have): download the installer from postgresql.org, it installs:

- PostgreSQL server (runs in background as a Windows service)
- pgAdmin 4 (GUI)
- Command Line Tools (`psql`, `pg_dump`, `pg_restore`)
- Stack Builder (not needed, skip)

During install: set the password of the `postgres` user (remember it), port 5432 (default), rest default.

Check:

```
psql --version        -> psql (PostgreSQL) 18.x
```

- "not recognized" -> add `C:\Program Files\PostgreSQL\18\bin` to PATH (Environment Variables -> Path -> New), then open a **new** terminal.
- without PATH, PowerShell: `& "C:\Program Files\PostgreSQL\18\bin\psql.exe" --version` (the `&` is needed when the path is in quotes).
- is server running? Windows: `services.msc` -> `postgresql-x64-18` -> Running. Start from admin terminal: `net start postgresql-x64-18`.

Alternatives:

- Mac: `brew install postgresql@18` (or Postgres.app), start: `brew services start postgresql@18`.
- Ubuntu: `sudo apt install postgresql`, login: `sudo -u postgres psql`.
- Docker (no install on laptop): `docker run --name pg -e POSTGRES_PASSWORD=yourpassword -p 5432:5432 -d postgres`. Data is lost if the container is removed unless a volume is used.
- GUI alternatives to pgAdmin: DBeaver, TablePlus, DataGrip, VS Code SQL extension.

Do I need to install anything else?

| for | install |
| --- | --- |
| only learning SQL | PostgreSQL (psql + pgAdmin come with it) + VS Code (SQL extension optional) |
| full stack (PERN / MERN) | Node.js LTS, Git, in server folder `npm i pg dotenv`; optional Docker; API tester (Postman / Thunder Client) |
| later, when project needs | migration tool or ORM (node-pg-migrate, Knex, Prisma, Drizzle) |

### 1.3 Connect with psql

```
psql -U postgres -h localhost -p 5432 -d postgres
```

```
-U user (role) name
-h host (where the server runs)
-p port (default 5432)
-d which database to connect to
```

You can also use a URI:

```
psql "postgresql://postgres@localhost:5432/postgres"
```

➕ if I skip a flag:

| skipped | default | problem |
| --- | --- | --- |
| `-U` | Windows user name (ex: `Lenovo`) | `role "Lenovo" does not exist`, so always write `-U postgres` |
| `-h` | localhost on Windows (local socket on Linux/Mac) | |
| `-p` | 5432 | wrong if another install uses 5433 |
| `-d` | same name as the user | `-U postgres` alone connects to db `postgres` |

- prompt shows where I am: `postgres=#` (superuser), `insta_practice=#`, `insta_practice=>` (normal user), `-#` = statement not finished (type `;`).
- start psql without database name and then `\c insta_practice` to switch.

Password ways (from simple to better):

1. type it every time (prompt asks)
2. `pgpass.conf` file (1.4) <- one time setup
3. env variable for this terminal only: PowerShell `$env:PGPASSWORD = "yourpassword"`, cmd `set PGPASSWORD=yourpassword`
4. `-W` always ask, `-w` never ask (for scripts, fails if no password is available)
5. full stack app: `DATABASE_URL=postgresql://user:password@localhost:5432/dbname` in `.env` (special characters in password must be URL encoded, `@` = `%40`)

### 1.4 Password setup so it doesn't ask every time (Windows)

```
PostgreSQL Password Setup (Windows)
-----------------------------------
Created: %APPDATA%\postgresql\pgpass.conf

Entry format:
localhost:5432:*:postgres:YOUR_PASSWORD

Replace YOUR_PASSWORD with the PostgreSQL password.

Purpose: Saves the password for matching local psql connections, so it usually
doesn't prompt every time. Setup is one-time for this Windows user account.

Connect:
psql -U postgres -d insta_practice

Run SQL file from PowerShell:
psql -U postgres -d insta_practice -f ".\schema\01_products.sql"

Note: Run the SQL-file command in PowerShell, not inside psql. The password
file stores the password as plaintext; keep it private and out of Git.
```

Create it (PowerShell, one time):

```powershell
mkdir $env:APPDATA\postgresql -Force
Set-Content -Path "$env:APPDATA\postgresql\pgpass.conf" -Value "localhost:5432:*:postgres:YOUR_PASSWORD"
```

➕ edge cases:

- format is `host:port:database:user:password`, `*` means any.
- host must match what I type: entry `localhost` does not work for `-h 127.0.0.1` (it asks the password again).
- password containing `:` or `\` -> put a `\` before it.
- Mac/Linux: file is `~/.pgpass` and needs `chmod 600 ~/.pgpass`, else it is ignored.
- password changed but old one is in the file -> `password authentication failed` and no prompt. Update the line.
- file is plaintext, so it stays outside project folder, Git, OneDrive, screenshots. Real servers use env variables / secret manager, never a file in the repo.

### 1.5 psql commands

```
\l  list all databases
\c dbname connect to that database
\dt  list tables in the current database
\d tablename describe a table (columns, types, constraints)
\dn  list schemas
\q  quit
```

OUTPUT:

```
postgres-# \l
                                                               List of databases
      Name      |  Owner   | Encoding | Locale Provider |      Collate       |       Ctype        | Locale | ICU Rules |   Access privileges
----------------+----------+----------+-----------------+--------------------+--------------------+--------+-----------+-----------------------
 insta_practice | postgres | UTF8     | libc            | English_India.1252 | English_India.1252 |        |           |
 postgres       | postgres | UTF8     | libc            | English_India.1252 | English_India.1252 |        |           |
 template0      | postgres | UTF8     | libc            | English_India.1252 | English_India.1252 |        |           | =c/postgres          +
                |          |          |                 |                    |                    |        |           | postgres=CTc/postgres
 template1      | postgres | UTF8     | libc            | English_India.1252 | English_India.1252 |        |           | =c/postgres          +
                |          |          |                 |                    |                    |        |           | postgres=CTc/postgres
(4 rows)


postgres-# \c insta_practice
You are now connected to database "insta_practice" as user "postgres".
insta_practice-# \d products
                                   Table "public.products"
   Column    |           Type           | Collation | Nullable |           Default
-------------+--------------------------+-----------+----------+------------------------------
 id          | integer                  |           | not null | generated always as identity
 name        | character varying(100)   |           | not null |
 price       | numeric(8,2)             |           | not null |
 stock       | smallint                 |           |          | 0
 rating      | numeric(2,1)             |           |          |
 is_active   | boolean                  |           |          | true
 launched_on | date                     |           |          |
 created_at  | timestamp with time zone |           |          | now()
Indexes:
    "products_pkey" PRIMARY KEY, btree (id)
```

➕ more psql commands:

```
\i schema/01_products.sql      -- run a file from inside psql (forward slashes)
\ir schema/01_products.sql     -- run file relative to the file that contains this line (inside scripts)
\cd C:/Users/me/postgresql_demo  -- change psql's current folder
\! cd                          -- show current folder (Mac/Linux: \! pwd)
\timing                        -- show time of each query
\x                             -- vertical view (good for wide rows), run again to turn off
\pset null '(null)'            -- show NULL as text instead of blank
\h CREATE TABLE                -- built-in syntax help
\?                             -- help for psql commands
\r                             -- clear a half written command
\! cls                         -- clear screen (Mac/Linux: \! clear)
\set ON_ERROR_STOP on          -- stop a script at first error
\copy products TO 'products.csv' CSV HEADER     -- export table to csv (client side)
```

Edge cases:

- Every SQL ends with `;`. If prompt shows `postgres-#` it is still waiting, type `;`. (typing `cls` or `clear` in psql makes this happen, they are not SQL)
- Commands starting with `\` are psql commands, not SQL, no `;` needed.
- `-- More --` is the pager: space = next page, `q` = quit, `\pset pager off` = disable.
- Can't `DROP DATABASE` the one I am connected to (`\c postgres` first) and pgAdmin connection also blocks it (`DROP DATABASE x WITH (FORCE)`).
- `\i` with backslash path (`\i schema\01.sql`) breaks, backslash is special in psql. Use forward slashes even on Windows.
- Windows warning `Console code page (437) differs from Windows code page (1252)`: run `chcp 1252` before `psql`, or ignore it if only English text.

### 1.6 Run SQL files (terminal and psql)

Folder example:

```
postgresql_demo/
├── demo.sql
├── schema/
│   └── 01_products.sql
└── seed/
    └── 01_products_seed.sql
```

Step 1: terminal in that folder (PowerShell):

```
cd C:\Users\<me>\Documents\postgresql_demo
```

**Way 1: from the terminal (not inside psql)**

```
psql -U postgres -d insta_practice -f demo.sql
psql -U postgres -d insta_practice -f schema/01_products.sql
psql -U postgres -d insta_practice -c "SELECT count(*) FROM products;"
```

-f runs a file
-c runs one command.

Run any SQL file from PowerShell:

```
psql -U postgres -d insta_practice -f ".\path\filename.sql"
```

Replace `path\filename.sql` with your SQL file's relative path.

Example:

```
psql -U postgres -d insta_practice -f ".\schema\01_products.sql"
```

**Way 2: inside psql (connect first, then `\i`)**

```
psql -U postgres -d insta_practice          <- start psql from the project folder
insta_practice=# \i demo.sql
insta_practice=# \i schema/01_products.sql
insta_practice=# \i seed/01_products_seed.sql
```

- `\i` path is relative to the folder where I **started psql** (or the one set with `\cd`), not relative to the sql file. Wrong folder = `No such file or directory`.
- absolute path also works: `\i C:/Users/me/postgresql_demo/demo.sql`.

**Way 3: other ways ➕**

- pgAdmin: right-click database -> Query Tool -> open file icon -> run (F5).
- VS Code: SQL extension -> run query. Or terminal inside VS Code with `-f`.
- redirect: `psql -U postgres -d insta_practice < demo.sql` works in cmd, **not in PowerShell** (`<` is not supported there). PowerShell: `Get-Content demo.sql | psql -U postgres -d insta_practice`.

Useful options:

```
psql -U postgres -d insta_practice -v ON_ERROR_STOP=1 -f demo.sql   -- stop at first error
psql -U postgres -d insta_practice -1 -f demo.sql                   -- whole file in ONE transaction (all or nothing)
psql -U postgres -d insta_practice -a -f demo.sql                   -- print every command while running
psql -U postgres -d insta_practice -f demo.sql -o result.txt        -- save output to file
psql -X -U postgres -d insta_practice                               -- ignore my psqlrc settings
```

One master file that runs the others (`reset_db.sql`):

```sql
\set ON_ERROR_STOP on
\ir schema/01_products.sql
\ir seed/01_products_seed.sql
```

- `\ir` (relative to this master file) works from any folder, `\i` needs me to start psql in the project root.

Edge cases:

- psql keeps going after an error by default (prints `file.sql:12: ERROR`), so later lines can run on a broken state. Use `ON_ERROR_STOP` or `-1`.
- run twice -> duplicate / already exists errors. Make files re-runnable: `DROP TABLE IF EXISTS`, `CREATE TABLE IF NOT EXISTS`, `INSERT ... ON CONFLICT DO NOTHING`.
- path with spaces needs quotes: `-f "C:\My Folder\demo.sql"`.
- file must be saved as **UTF-8** (VS Code default). Files created with PowerShell `>` can be UTF-16 and psql prints garbage / syntax errors.
- `-c` and quotes in PowerShell: JSON / double quotes inside `-c "..."` break. Put it in a `.sql` file instead.
- each `psql` command is a **new connection**: `psql -c "BEGIN;"` then `psql -c "ROLLBACK;"` does not work (transaction lives only in one session). Sandbox = same file or same psql session.

### 1.7 pgAdmin basics ➕

- first time: right-click **Servers** -> Register -> Server: name (any), Connection: host `localhost`, port `5432`, maintenance database `postgres`, username `postgres`, password (tick save password).
- Object Explorer: Servers -> PostgreSQL 18 -> Databases -> insta_practice -> Schemas -> public -> Tables.
- Query Tool: right-click database -> Query Tool (or Tools menu). Run = F5. **If some text is selected, only the selected text runs** (edge: accidental selection).
- Explain = F7, Explain Analyze = Shift+F7 (performance phase).
- view table data: Tables -> right-click -> View/Edit Data -> All Rows.
- ERD: right-click database -> ERD For Database (draws tables + arrows).
- **Auto-commit** is on by default in Query Tool, so `UPDATE` is saved at once. For sandbox write `BEGIN; ... ROLLBACK;` yourself (or switch auto-commit off in toolbar).
- after changing structure from terminal, refresh tree (right-click -> Refresh) to see it.
- before `DROP DATABASE`: right-click database -> Disconnect Database.
- Dashboard tab shows active sessions, useful to see who is connected.
- Backup / Restore buttons in pgAdmin just call `pg_dump` / `pg_restore`.

### 1.8 What to run where ➕

| task | best place | why |
| --- | --- | --- |
| quick check (`\dt`, `\d products`, `SELECT count(*)`) | psql terminal | fast |
| small `SELECT` | terminal or pgAdmin | both fine |
| `UPDATE` / `DELETE` (risky) | terminal or pgAdmin, but inside `BEGIN; ... ROLLBACK;` first | undo if wrong |
| create / alter tables (structure) | **file** in `schema/` | repeatable, can be committed to Git |
| seeding (sample data) | **file** in `seed/` | repeatable |
| sandbox test | **one** psql session or one file | transaction lives in one connection |
| practice queries | `.sql` file in VS Code, run with `\i` or `-f` | keeps my work saved |
| explore data, big results, ERD, explain plan | pgAdmin | visual grid |
| export / backup | terminal | `pg_dump`, `\copy` |

- rule: if I may want it again -> it goes in a file. If it is a quick check -> type in console.

Sandbox (same session):

```sql
BEGIN;
UPDATE products SET price = price * 2;
SELECT name, price FROM products LIMIT 3;     -- check
ROLLBACK;                                      -- nothing changed (COMMIT; to keep)
```

- error inside BEGIN -> `current transaction is aborted`, run `ROLLBACK;` and start again.

Seeding = putting sample / starting data in tables.

- dev seed: fake users, products (many rows with `generate_series` + `random()`).
- reference data (countries, roles) can be seeded in production too, fake data never.
- from csv: `\copy products FROM 'products.csv' CSV HEADER` (psql, reads file on my laptop). Plain `COPY` reads file on the **server** and needs high permission.
- re-runnable seed: `INSERT ... ON CONFLICT DO NOTHING`, or `TRUNCATE ... RESTART IDENTITY` first.

Backup and restore (comes with install):

```
pg_dump -U postgres -d insta_practice -f backup.sql              -- plain SQL backup
psql -U postgres -d insta_practice_copy -f backup.sql            -- restore (database must exist)
pg_dump -U postgres -d insta_practice -Fc -f backup.dump         -- compressed format
pg_restore -U postgres -d insta_practice_copy backup.dump
```

### 1.9 Folder structure

**A) Learning folder (what I use now)**

```
postgresql_practice/
├── README.md
├── PostgreSQL.md              roadmap + tracker
├── reset_db.sql               one command rebuilds everything
├── schema/                    CREATE / ALTER files   (01_categories.sql, 02_products.sql)
├── seed/                      INSERT sample data     (01_categories_seed.sql ...)
├── phase02_querying/          my practice queries    (01_filtering.sql ...)
├── practice30/
├── notes/
└── interview/
```

- names: lowercase, snake_case, number prefix for run order (`01_`, `02_`), name says what is inside.
- always run from the project root so relative paths work.

**B) Full stack project (PERN example)**

```
my-app/
├── client/                    React frontend
│   ├── src/
│   └── package.json
├── server/                    Express backend
│   ├── src/
│   │   ├── config/db.js       connection pool, reads DATABASE_URL from env
│   │   ├── routes/            URL -> controller
│   │   ├── controllers/       request / response
│   │   ├── services/          business logic
│   │   ├── queries/           SQL (or repositories)
│   │   └── index.js
│   ├── .env                   real secrets, NOT in Git
│   ├── .env.example           same keys, fake values, in Git
│   └── package.json
├── db/
│   ├── migrations/            001_create_users.sql, 002_create_posts.sql ...
│   ├── seeds/                 dev_seed.sql
│   └── reset_dev.sql          dev only
├── docs/
├── .gitignore                 .env, node_modules
├── docker-compose.yml         optional: postgres container for the team
└── README.md
```

How my learning folder maps to it:

| learning | full stack |
| --- | --- |
| `schema/` | `db/migrations/` (numbered, each change is a new file) |
| `seed/` | `db/seeds/` (dev only) |
| `reset_db.sql` | `db/reset_dev.sql` (never on production) |
| `phaseXX/` practice queries | `server/src/queries/` (SQL used by API) |
| `\i` / `-f` | migration runner script or tool |

Rules:

- migration = one numbered `.sql` file per change, **never edit one that is already applied**, add a new one (`003_add_bio_to_profiles.sql`).
- one connection string from env: `DATABASE_URL=postgresql://user:password@localhost:5432/myapp_dev`. Nothing hardcoded.
- separate databases: `myapp_dev`, `myapp_test`, production.
- `.env` in `.gitignore`, commit `.env.example`.
- app uses **one pool** for whole server (not a new connection per request).
- queries always parameterized (`$1`), never string concatenation (SQL injection).
- app should not connect as `postgres` superuser, make a limited role (roles topic later).
- production: backup first, no reset, no fake seed.

Connect from Node (ES modules, `"type": "module"` in package.json):

```js
// server/src/config/db.js
import pg from 'pg';
import 'dotenv/config';

export const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
```

```js
// using it
const { rows } = await pool.query('SELECT id, username FROM users WHERE id = $1', [userId]);
```

Run migrations without a tool: small Node script that reads `db/migrations/*.sql` in name order and runs each with the pool (works on every OS). Or a tool: node-pg-migrate, Knex, Prisma Migrate, Drizzle.

ORM = library that maps tables to objects / functions (Prisma, Sequelize, TypeORM, Drizzle). Good for speed of development, but I still must know SQL, joins and indexes to understand what it generates (topic later).

Tip: if the project is in a OneDrive / Google Drive synced folder, `node_modules` makes sync slow and can lock files. Keep full stack code outside synced folders (ex: `C:\dev\my-app`) and use Git for backup.

### 1.10 Setup errors and alternatives ➕

| error / problem | meaning, fix |
| --- | --- |
| `psql` is not recognized | PATH missing, add `...\PostgreSQL\18\bin` or use full path with `&` in PowerShell |
| `role "Lenovo" does not exist` | forgot `-U postgres` (default is Windows user name) |
| `database "x" does not exist` | typo, or never created. `\l` to check |
| `connection refused` / `could not connect to server` | server not running (start service `postgresql-x64-18`), or wrong port / host |
| `password authentication failed for user "postgres"` | wrong password (typed or old one in pgpass), or `-h 127.0.0.1` not matching the `localhost` pgpass line |
| `\i: No such file or directory` | psql started in another folder, `\cd` to project root or use full path |
| `syntax error` just after pasting a file | file saved as UTF-16, save as UTF-8 |
| prompt `postgres-#` | statement not finished, type `;` or `\r` |
| `cannot drop the currently open database` | `\c postgres` first |
| `database is being accessed by other users` | disconnect pgAdmin or `DROP DATABASE x WITH (FORCE)` |
| `permission denied for schema public` | normal (non superuser) role has no CREATE there on newer versions, create tables as owner / grant |
| `current transaction is aborted` | earlier error inside `BEGIN`, `ROLLBACK;` |
| file ran twice and gives duplicate errors | make files re-runnable (`IF EXISTS`, `ON CONFLICT DO NOTHING`) |
| password has `@` and URI fails | URL encode it (`@` -> `%40`) |
| `psql -c "..."` quotes break in PowerShell | put SQL in a `.sql` file and use `-f` |

Alternatives when something does not work:

- psql problem -> use **SQL Shell (psql)** from Start menu (asks host / db / port / user / password one by one, press Enter for defaults).
- terminal problem -> do the same in pgAdmin Query Tool.
- install problem -> Docker container with Postgres, connect with same `psql` / pgAdmin using `localhost:5432`.

---

## 2. Datatypes

```
Numeric: smallint, integer, bigint, numeric(10, 2), real, double precision.
Auto-increment: serial, generated always as identity (modern standard way)
text: char(2), varchar(225), text
Boolean: Boolean (true, false, null)
date & time: date, time, timestamp, timestamptz, interval
id generated: uuid (128-bit unique id)
```

➕ Short meaning:

| Type | Use when | Edge case |
| --- | --- | --- |
| smallint / integer / bigint | whole numbers (about ±32 thousand / ±2.1 billion / ±9 quintillion) | integer overflows at ~2.1 billion, use bigint for fast growing tables (likes) |
| numeric(p,s) | **exact** decimal (money, price). p = total digits, s = digits after point | numeric(8,2) max is 999999.99, more gives `numeric field overflow` |
| real / double precision | **approximate** decimals (science, GPS sensor) | never for money, 0.1 + 0.2 may not be exactly 0.3 |
| char(n) | fixed length | pads with spaces, rarely used |
| varchar(n) | up to n chars | use n only when it is a real rule (username 30) |
| text | any length | no speed difference from varchar in PostgreSQL |
| boolean | true / false / null | accepts `true`, `'yes'`, `'t'`, `'1'` |
| date / time | only date / only time | |
| timestamp | date + time, no timezone | confusing when users in different timezones |
| timestamptz | date + time with timezone (stored in UTC) | use this for created_at |
| interval | a duration, ex: `interval '7 days'` | |
| uuid | unguessable / public ids | 16 bytes, bigger than integer |

### Choosing data types (my answers)

```
- Price / wallet balance: NUMERIC
- Age / like count: SMALLINT / BIGINT
- Phone / PIN code: VARCHAR
- Verified flag: BOOLEAN
- Date of birth: DATE
- Created time: TIMESTAMPTZ
- Username (30 characters): VARCHAR(30)
- Caption (2200 characters): VARCHAR(2200)
- GPS coordinates: NUMERIC(9,6) with range checks
- Unguessable order ID: UUID generated securely
- Stars (1–5): SMALLINT with a CHECK constraint
- Video duration: INTEGER (seconds)
```

KEY PRINCIPLE: Choose data types based on the value's meaning, precision, range, and validation requirements.
(phone / PIN: not used for maths and leading zero can matter, so text not number)

---

## 3. Create table, CRUD, identity / uuid

### 3.1 CREATE TABLE

```sql
CREATE TABLE table_name (
 col_name datatype constraints,
 col_name datatype constraints,
 ...
);
```

ex:

```sql
CREATE TABLE students (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   varchar(80) NOT NULL,
    age         smallint,
    fees        numeric(8,2) DEFAULT 0,
    is_active   boolean DEFAULT true,
    joined_on   date,
    created_at  timestamptz DEFAULT now()
);
```

- order is: column name -> datatype -> constraints (`id serial PRIMARY KEY`, not `id primary key serial`).
- no comma after the last column.

### 3.2 INSERT, SELECT, UPDATE, DELETE + RETURNING ➕

```sql
INSERT INTO products (name, price, stock)
VALUES ('Mouse', 799, 50),
       ('Hub', 1299.50, DEFAULT)          -- multi-row insert
RETURNING id, created_at;                  -- gives back new rows

SELECT name, price FROM products WHERE price > 1000;       -- specific columns + filter
UPDATE products SET price = price * 1.10, stock = stock - 1 WHERE id = 3 RETURNING id, price;
DELETE FROM products WHERE id = 3 RETURNING *;
```

Edge cases:

- text and dates in single quotes `'hello'`, `'2025-01-15'`. Double quotes are for column/table names (avoid).
- column list and values list must match in count and order.
- skipped column -> DEFAULT is used (or NULL). In multi-row insert write the word `DEFAULT`.
- `UPDATE`/`DELETE` without `WHERE` changes ALL rows.
- no row matched -> `UPDATE 0`, not an error.
- deleted id is not reused, ids are labels not row numbers (gaps are normal).
- `RETURNING` = no second SELECT needed, APIs use it to get the new id.

Safe habit (sandbox):

```sql
BEGIN;
DELETE FROM products WHERE is_active = false;
SELECT id, name FROM products;      -- check result
ROLLBACK;                           -- undo everything (or COMMIT; to keep)
```

### 3.3 Serial vs identity (a common interview question)

```
serial: it silently create a sequence behind it and u can insert your own id manually/by mistake also
identity: modern and standard, protect id from manual inserts
```

### 3.4 DELETE vs TRUNCATE vs DROP

```
                         Removes             WHERE? Table stays? Identity counter
DELETE FROM products     chosen rows         yes     yes             keeps counting
TRUNCATE TABLE products     all rows, fast     no     yes             keeps counting, unless RESTART IDENTITY
DROP TABLE products         rows and the table no     no             gone
```

➕ edge: in PostgreSQL `TRUNCATE` and `DROP` can also be rolled back inside `BEGIN ... ROLLBACK` (not all databases allow it). `DROP TABLE IF EXISTS x;` avoids error if not there.

### 3.5 IDENTITY, UUID, SERIAL

```
3. IDENTITY
-----------
- Automatically generates numeric IDs using a sequence.
- Starts at 1 by default.
- PRIMARY KEY ensures uniqueness; IDENTITY alone does not.

A) GENERATED ALWAYS:
  CREATE TABLE test_always (
      id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
      name TEXT
  );

  Automatic ID:
  INSERT INTO test_always (name) VALUES ('Jay');

  Manual ID (normally rejected):
  INSERT INTO test_always (id, name) VALUES (100, 'Rahul');

  Manual ID with override (allowed if ID 100 is not already used):
  INSERT INTO test_always (id, name)
  OVERRIDING SYSTEM VALUE VALUES (100, 'Rahul');

B) GENERATED BY DEFAULT:
  CREATE TABLE test_default (
      id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
      name TEXT
  );

  Automatic ID:
  INSERT INTO test_default (name) VALUES ('Jay');

  Manual ID (allowed if ID 100 is not already used):
  INSERT INTO test_default (id, name) VALUES (100, 'Rahul');

Important: manually inserting ID 100 does not automatically move the sequence to 100.
Later generated IDs can conflict with manually inserted IDs unless the sequence is adjusted.


4. UUID
-------
- UUID = Universally Unique Identifier; a 128-bit identifier, usually shown in a
  format like 550e8400-e29b-41d4-a716-446655440000.
- Not a sequence starting at 0 or 1.
- Random UUIDs are very unlikely to collide, but PRIMARY KEY still enforces uniqueness.
- Useful for public-facing IDs or systems that generate IDs independently.
- Larger than INTEGER/BIGINT and less readable.

Example:
  CREATE TABLE public_items (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name TEXT NOT NULL
  );

  INSERT INTO public_items (name)
  VALUES ('Sample item')
  RETURNING *;


5. SERIAL vs IDENTITY
---------------------
- SERIAL is older PostgreSQL shorthand that uses a sequence-backed default.
- IDENTITY is the modern, SQL-standard approach for new tables.
- SERIAL and GENERATED BY DEFAULT generally allow manually supplied IDs.
- GENERATED ALWAYS rejects manually supplied IDs by default; use
  OVERRIDING SYSTEM VALUE to supply one explicitly.

QUICK SUMMARY
-------------
- PK: uniquely identifies a row.
- FK: ensures a reference points to an existing row.
- IDENTITY: automatically generates numeric IDs.
- UUID: stores a UUID identifier, not a sequential number.
- GENERATED ALWAYS: manual IDs rejected by default.
- GENERATED BY DEFAULT: manual IDs allowed.
```

➕ Identity vs UUID:

| | identity / serial | uuid |
| --- | --- | --- |
| size | 4 or 8 bytes | 16 bytes |
| guessable from outside (`/post/101`, `/post/102`) | yes | no |
| generated on many servers | needs coordination | each server can |
| index friendly | sequential, great | random ones scatter inserts (UUIDv7 is time ordered) |

- after importing explicit ids into a `BY DEFAULT` column, move the sequence forward (`setval`), else next insert collides. Classic production bug.

---

## 4. Keys, constraints, foreign keys, ALTER TABLE

### 4.1 KEYS

1. super key: any set of column which are unique:
   ex: {id}, {id, name}, {id, email}, {email}...
2. candidate key: minimal of super key (remove any column and it is not unique anymore)
   ex: {id}, {email}, {username} are candidate keys.
   ✏️ {id, name} is NOT a candidate key because {id} alone is already unique. (old note said "if super key {id, name} then candidate key id, name")
3. PRIMARY key: unique with not null and one per table only
   ex: id PRIMARY key -> then no one have P_key in table (only one)
   -> id: unique and not null
4. alternate key ➕: candidate keys which are not chosen as primary key (keep them `UNIQUE NOT NULL`). ex: email, username
5. Composite key: key made up of 2 or more column
   ex: likes(users, posts);
6. Foreign key: a column that must match with another table column, or be NULL
   ex: `post.user_id -> user.id`
   ✏️ old note said "with not null value", but FK can be NULL unless I add NOT NULL.
7. surrogate vs natural key ➕:
   - surrogate: artificial id with no meaning (identity, uuid). Usually best primary key.
   - natural: real world value (email, ISBN). Can change / long, so keep as UNIQUE column, not as PK. (ok for small stable lookup tables like country code `IN`)

### 4.2 Constraints (rules the database itself enforces) ➕

| Constraint | Rule | Edge case |
| --- | --- | --- |
| PRIMARY KEY | unique + not null, one per table (can be composite) | composite PK `(user_id, post_id)` blocks duplicate pair |
| NOT NULL | value required | adding it to a filled column fails if NULLs exist |
| UNIQUE | no duplicates | many NULLs allowed (NULL is not equal to NULL) |
| DEFAULT | value used when none given | `now()`, `true`, `0` |
| CHECK | any condition must be true | NULL passes a CHECK (only false is rejected), add NOT NULL too if required |
| FOREIGN KEY | value must exist in other table (or be NULL) | FK column is not indexed automatically |

Column level and table level (named, better error messages):

```sql
CREATE TABLE employees (
    id          integer GENERATED ALWAYS AS IDENTITY,
    email       text NOT NULL,
    salary      numeric(10,2) CHECK (salary > 0),
    start_date  date NOT NULL,
    end_date    date,
    CONSTRAINT pk_employees       PRIMARY KEY (id),
    CONSTRAINT uq_employees_email UNIQUE (email),
    CONSTRAINT ck_employees_dates CHECK (end_date IS NULL OR end_date >= start_date)
);
```

- name them `pk_`, `uq_`, `ck_`, `fk_` so error shows exactly which rule failed.
- primary key vs unique key: PK only 1 per table and never NULL, UNIQUE many per table and NULL allowed.
- types of integrity: entity (PK), referential (FK), domain (datatype/CHECK), business rule (CHECK/UNIQUE/trigger).

### 4.3 PRIMARY KEY and FOREIGN KEY

```
1. PRIMARY KEY (PK)
-------------------
- Uniquely identifies each row.
- Cannot contain NULL or duplicate values.
- Example:
  CREATE TABLE customers (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL
  );


2. FOREIGN KEY (FK)
-------------------
- Ensures a value refers to an existing row in another table (or the same table).
- The referenced column must have suitable uniqueness enforcement, usually a PRIMARY KEY or UNIQUE constraint.
- A foreign key can contain NULL unless NOT NULL is specified.
- The FK column does not need to be unique; many rows can reference the same parent.

Two ways to define a foreign key:

A) Inline / column-level:
  CREATE TABLE orders (
      id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
      customer_id INTEGER REFERENCES customers(id),
      amount NUMERIC(10,2) NOT NULL
  );

B) Table-level / named constraint:
  CREATE TABLE orders (
      id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
      customer_id INTEGER,
      amount NUMERIC(10,2) NOT NULL,
      CONSTRAINT fk_orders_customer
          FOREIGN KEY (customer_id)
          REFERENCES customers(id)
  );

Both define the same relationship. The second lets you choose a constraint name.
If you omit the name, PostgreSQL creates one automatically.
To rename a constraint:
  ALTER TABLE orders
  RENAME CONSTRAINT orders_customer_id_fkey TO fk_orders_customer;

Invalid reference example:
  INSERT INTO orders (customer_id, amount) VALUES (999, 500);
This fails if customer 999 does not exist.

Delete behavior:
- Default (NO ACTION): normally prevents deleting a referenced parent.
- ON DELETE CASCADE: deletes dependent child rows too.
- ON DELETE SET NULL: sets child FK to NULL; the column must allow NULL.
```

EX (try in sandbox):

```sql
-- A. default behaviour: blocked
DELETE FROM categories WHERE name = 'Audio';
-- ERROR: update or delete on table "categories" violates foreign key constraint
--        "fk_products_category" on table "products"

-- B. SET NULL
BEGIN;
ALTER TABLE products DROP CONSTRAINT fk_products_category;
ALTER TABLE products ADD CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL;
DELETE FROM categories WHERE name = 'Audio';
SELECT id, name, category_id FROM products WHERE id IN (6, 10, 17);   -- category_id is now NULL
ROLLBACK;

-- C. CASCADE
BEGIN;
ALTER TABLE products DROP CONSTRAINT fk_products_category;
ALTER TABLE products ADD CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE;
DELETE FROM categories WHERE name = 'Audio';
SELECT COUNT(*) FROM products;                                        -- 17, three products vanished
ROLLBACK;
SELECT COUNT(*) FROM products;                                        -- 20 again
```

(PostgreSQL even rolls back ALTER = transactional DDL, MySQL can't.)

➕ All FK delete rules:

| Rule | What happens when parent row is deleted |
| --- | --- |
| NO ACTION (default) | error (checked at end of statement, can be deferred) |
| RESTRICT | error immediately |
| CASCADE | child rows deleted too |
| SET NULL | child FK becomes NULL (column must allow NULL) |
| SET DEFAULT | child FK becomes its default (default must be valid parent) |

- how to choose: ownership (comment of a post, like of a post) -> CASCADE. Independent thing (product -> category) -> RESTRICT or SET NULL. Money / audit -> RESTRICT + soft delete (`deleted_at`).
- cascade chain: deleting a user can delete posts -> their comments -> their likes (also of other people). Test in sandbox first.
- FK column is not indexed automatically (parent PK is). Index it later (performance phase).
- adding FK to existing table checks old rows: if one orphan row exists, `ALTER TABLE ... ADD FOREIGN KEY` fails. Find orphan with LEFT JOIN ... `WHERE p.id IS NULL`, fix, add again.
- soft delete problem: plain UNIQUE (username) still blocks reuse by deleted user, fix = partial unique index `WHERE deleted_at IS NULL`.

### 4.4 UNIQUE and NULL

same values not allowed but null values is allowed

```sql
create temp table demo (email text UNIQUE);
insert into demo(email) VALUES('jayesh@gmail.com');
insert into demo(email) VALUES(NULL);
insert into demo(email) VALUES(NULL);     -- works, many NULLs allowed
insert into demo(email) VALUES('hi');
insert into demo(email) VALUES('hi');     -- ERROR duplicate key
select * from demo;
```

- the failed insert saves nothing, one statement is all or nothing.
- (PostgreSQL 15+: `UNIQUE NULLS NOT DISTINCT` makes NULL count as same.)

### 4.5 ALTER TABLE

ALTER TABLE: is a SQL command used to change the structure of an existing table without recreating the table.

- used when add/drop constraint and add/rename/drop/alter column

```sql
ALTER TABLE products
    ADD CONSTRAINT ck_product_price_negative CHECK(price>=0);
-- it will break for: INSERT INTO products (name, price) VALUES ('Bad Item', -5);

alter table products
    add constraint ck_rating_range check(rating between 0 and 5);

alter table products
    alter column stock set not null;

alter table products
    add constraint ck_stock_value_negative check(stock>=0);
```

➕ All ALTER forms:

```sql
ALTER TABLE t ADD COLUMN col type [constraints];
ALTER TABLE t DROP COLUMN col [CASCADE];
ALTER TABLE t RENAME COLUMN old_name TO new_name;
ALTER TABLE t RENAME TO new_table_name;
ALTER TABLE t ALTER COLUMN col TYPE new_type [USING expression];
ALTER TABLE t ALTER COLUMN col SET DEFAULT value;   -- or DROP DEFAULT
ALTER TABLE t ALTER COLUMN col SET NOT NULL;        -- or DROP NOT NULL
ALTER TABLE t ADD CONSTRAINT name ...;              -- or DROP CONSTRAINT name
```

Safe 3 step for new required column (test in BEGIN ... ROLLBACK):

```sql
ALTER TABLE products ADD COLUMN sku varchar(20);                  -- 1. add nullable
UPDATE products SET sku = 'SKU-' || LPAD(id::text, 4, '0');       -- 2. fill old rows
ALTER TABLE products ALTER COLUMN sku SET NOT NULL;               -- 3. now enforce
```

Edge cases:

- `ADD COLUMN x ... NOT NULL` on filled table fails (`contains null values`), unless it has a DEFAULT.
- `SET NOT NULL` fails if NULLs already exist. `ADD CONSTRAINT CHECK/UNIQUE` fails if old rows break it (find them with a query, fix, add again).
- type change that PostgreSQL can't cast by itself needs `USING`: `ALTER COLUMN code TYPE integer USING code::integer`.
- shrinking type fails if data doesn't fit (`price TYPE numeric(6,2)` with 15999.00 -> overflow).
- one failed statement inside `BEGIN` aborts the whole transaction, `ROLLBACK;` and start again.
- big tables: ALTER takes a lock (blocks queries). Constant DEFAULT is instant (PG 11+), type change rewrites the table. Use `NOT VALID` then `VALIDATE CONSTRAINT` for FK/CHECK on huge tables.
- real projects keep each change as numbered migration file, never edit old one.

---

## 5. Relationships and normalization

### 5.1 Relationships

```
Main idea:
Relationships describe how rows in tables connect. Cardinality describes how many rows
can be connected.

1. ONE-TO-ONE (1:1)
-------------------
Main rule: Use a foreign key (FK) referencing the parent table's primary key (PK).
Make the FK UNIQUE so multiple rows cannot reference the same parent. Use NOT NULL
when every child row must have a parent.

Example: One person has at most one passport record.

CREATE TABLE passports (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_id INTEGER UNIQUE NOT NULL REFERENCES persons(id)
);

- UNIQUE: prevents two passport rows from referencing the same person.
- NOT NULL: every passport row must reference a person.


2. ONE-TO-MANY (1:N)
--------------------
Main rule: The FK is on the many-side (child) table and is NOT UNIQUE, so multiple
child rows can reference the same parent. Use NOT NULL if every child must have a parent.

Example: One category can have many products.

CREATE TABLE products (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    category_id INTEGER NOT NULL REFERENCES categories(id)
);

- Many products can share the same category_id.
- No UNIQUE constraint on category_id, because that would limit each category to one product.


3. MANY-TO-MANY (M:N)
---------------------
Main rule: Create a junction table with two FKs, one referencing each parent table.
Make the pair of FKs a composite PK to prevent duplicate relationships.

Example: Students can take many courses, and each course can have many students.

CREATE TABLE enrollments (
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    PRIMARY KEY (student_id, course_id)
);

- student_id is an FK to students(id).
- course_id is an FK to courses(id).
- Together, (student_id, course_id) form ONE composite primary key.
- This prevents the same student-course pair from being inserted twice.
- Each student and each course can still appear in multiple different pairs.

QUICK COMPARISON
----------------
1:1  -> FK + UNIQUE; add NOT NULL when the child must have a parent.
1:N  -> FK on the many-side; FK is not UNIQUE; add NOT NULL if required.
M:N  -> Junction table + two FKs + composite PK made from the pair.

Remember:
- PK uniquely identifies a row.
- FK ensures a reference points to an existing row.
- UNIQUE prevents duplicate values/pairs.
- NOT NULL prevents missing values.
- Cardinality is about how many rows can relate, not just about the number of FK columns.
```

➕ Extra:

- 1:1 can also use shared primary key: `profiles.user_id` is PK and FK both -> second profile for same user is impossible.
- junction table can hold own columns (`created_at`, `status`, `quantity`). Column order in composite PK matters (`(user_id, post_id)` is fast for "what did this user like", other direction needs an index).
- self reference: `comments.parent_comment_id -> comments.id` (replies), `follows(follower_id, following_id)` both point to users, `customers.referred_by -> customers.id`.
- optional vs required: FK nullable = optional (`products.category_id`), FK NOT NULL = required (`posts.user_id`).

### 5.2 Normalization ➕

Normalization = each fact stored once. It stops 3 bugs:

- update anomaly: same fact in many rows, update only some (email in 30 rows)
- insert anomaly: can't add a thing without another thing (user without posts)
- delete anomaly: deleting one thing loses another fact (last post deleted = user email lost)

Functional dependency: `A -> B` means if I know A I know exactly one B (`user_id -> email`).

- 1NF: every cell one atomic value, no repeating groups. Bad: `hashtags = 'travel,sunset'` (search with LIKE '%travel%' also matches 'travelling'). Fix: one row per post + tag (`post_hashtags`).
- 2NF: 1NF + no partial dependency (only matters when key has 2+ columns). Bad: `likes(user_id, post_id, username, post_caption)`, username depends only on user_id. Fix: keep them in `users` and `posts`.
- 3NF: 2NF + no transitive dependency (non-key must not depend on another non-key). Bad: `posts(post_id, user_id, user_email)`, post_id -> user_id -> user_email. Fix: email only in `users`.
- memory trick: every non-key attribute depends on **the key, the whole key, and nothing but the key**.
- BCNF: 3NF without exceptions (every determinant is a candidate key). Most 3NF designs are already BCNF.
- denormalization (break rules on purpose): `posts.like_count`. Faster reads but two places to keep correct (trigger / same transaction). Rule: normalize first, denormalize only after measuring.
- special case: `order_items.unit_price` (price at purchase time) is history, not duplication.

---

## 6. NULL deep dive

(Outputs below are examples from my products data. Exact counts depend on current data.)

### 6.1 Checking for NULL

QUERY 1 — WRONG WAY

```sql
SELECT name, rating
FROM products
WHERE rating = NULL;
```

OUTPUT: `(0 rows)`

EXPLANATION: Comparing a value with NULL using = does not evaluate to TRUE. Use IS NULL to find missing values.

QUERY 2 — CORRECT WAY

```sql
SELECT name, rating
FROM products
WHERE rating IS NULL;
```

OUTPUT (example):

```
USB-C Hub          | NULL
Phone Charger 20W  | NULL
```

EXPLANATION: IS NULL finds rows where the rating is missing. Use IS NOT NULL to find rows where it is present.

➕ NULL rules in short:

- `NULL = NULL` is NULL (unknown), not true. `WHERE` keeps only rows where condition is TRUE.
- `5 + NULL` is NULL.

| expression | result |
| --- | --- |
| TRUE AND NULL | NULL |
| FALSE AND NULL | FALSE |
| TRUE OR NULL | TRUE |
| FALSE OR NULL | NULL |
| NOT NULL | NULL |

### 6.2 COALESCE() — replace NULL in the query output

```sql
SELECT name, COALESCE(rating, 0) AS rating_or_zero
FROM products;
```

OUTPUT (example):

```
Wireless Mouse      | 4.3
Mechanical Keyboard | 4.6
USB-C Hub           | 0
Phone Charger 20W   | 0
```

EXPLANATION: COALESCE(value1, value2, ...) returns the first non-NULL value. Here, it displays rating when present; otherwise, it displays 0. It changes only the query result, not the stored table data.

### 6.3 Aggregate functions and NULL

QUERY 1 — COUNT AND AVG

```sql
SELECT COUNT(*), COUNT(rating), AVG(rating)
FROM products;
```

OUTPUT (example format):

```
count | count | avg
------+-------+---------
8     | 6     | 4.2167
```

EXPLANATION:

- COUNT(*) counts every row.
- COUNT(rating) counts only rows where rating is not NULL.
- AVG(rating) calculates the average of known ratings and ignores NULL values.
- The numbers above are illustrative; run the query to see the current database values.

QUERY 2 — TREAT NULL RATINGS AS ZERO

```sql
SELECT AVG(COALESCE(rating, 0))
FROM products;
```

OUTPUT (example format): `3.1625`

EXPLANATION: COALESCE replaces each NULL rating with 0 before AVG calculates the average. This gives a different answer because missing ratings are now included as zeros. Use this only if treating a missing rating as zero makes sense for your analysis.

OTHER AGGREGATE FUNCTIONS

```sql
SELECT SUM(stock) FROM products;   -- Total stock
SELECT MIN(price) FROM products;   -- Lowest price
SELECT MAX(price) FROM products;   -- Highest price
```

EXPLANATION: Aggregate functions calculate a summary from multiple rows. Common examples are COUNT, SUM, AVG, MIN, and MAX. Most aggregates ignore NULL input values; COUNT(*) is the exception because it counts rows.

### 6.4 Sorting NULL values

```sql
SELECT name, rating FROM products ORDER BY rating ASC;            -- NULL last (default)
SELECT name, rating FROM products ORDER BY rating DESC;           -- NULL first (default)
SELECT name, rating FROM products ORDER BY rating DESC NULLS LAST;  -- NULL at the end
```

EXPLANATION: In PostgreSQL, ASC places NULL values last by default and DESC places them first. Use NULLS FIRST or NULLS LAST to control the placement explicitly.

### 6.5 `<>` vs IS DISTINCT FROM

```sql
SELECT name, rating FROM products WHERE rating <> 4.3;                 -- NULL ratings excluded
SELECT name, rating FROM products WHERE rating IS DISTINCT FROM 4.3;   -- NULL ratings included
```

EXPLANATION: A comparison with NULL evaluates to UNKNOWN, and WHERE keeps only rows whose condition is TRUE. IS DISTINCT FROM treats NULL as a comparable value. When compared with 4.3, a NULL rating is considered distinct from 4.3.

### 6.6 NULLIF() — avoid division by zero

```sql
SELECT name,
       ROUND(price / NULLIF(stock, 0), 2) AS price_per_unit
FROM products;
```

OUTPUT (example):

```
Wireless Mouse | 15.98
USB-C Hub       | NULL
```

EXPLANATION: NULLIF(a, b) returns NULL when a equals b; otherwise, it returns a. If stock is 0, NULLIF(stock, 0) returns NULL, so the query avoids dividing by zero. The result for that row becomes NULL instead of raising a division-by-zero error.

DISPLAY 1 INSTEAD OF NULL:

```sql
SELECT name,
       COALESCE(ROUND(price / NULLIF(stock, 0), 2), 1) AS price_per_unit
FROM products;
```

EXPLANATION: NULLIF prevents division by zero. COALESCE then replaces a NULL result with 1. This is a display fallback; it does not mean the actual calculated value is 1.

### 6.7 Joining text when a value is NULL

```sql
SELECT name || ' rated ' || rating AS label_1 FROM products;                -- NULL rating -> whole label NULL
SELECT CONCAT(name, ' rated ', rating) AS label_2 FROM products;            -- CONCAT ignores NULL
SELECT CONCAT(name, ' rated ', COALESCE(rating::text, 'Not rated')) AS label FROM products;
```

OUTPUT (example):

```
Wireless Mouse rated 4.3
USB-C Hub rated Not rated
```

EXPLANATION: With the || operator, if one part is NULL, the entire result becomes NULL. CONCAT() ignores NULL arguments. rating::text converts the numeric rating to text, COALESCE replaces NULL with 'Not rated'.

### 6.8 QUICK REVISION

```
IS NULL                    Finds missing values.
COALESCE(value, fallback)  Returns the first non-NULL value.
COUNT(*)                   Counts all rows.
COUNT(column)              Counts non-NULL values in that column.
AVG(column)                Calculates the average of non-NULL values.
ORDER BY ... NULLS LAST    Explicitly places NULL values at the end.
<>                         Checks inequality, but NULL comparisons are UNKNOWN.
IS DISTINCT FROM           Compares values while handling NULL safely.
NULLIF(value, 0)           Returns NULL when value is 0; useful to avoid division by zero.
||                         Concatenates text; a NULL operand makes the result NULL.
CONCAT()                   Concatenates values while ignoring NULL arguments.
::text                     Converts a value to text in PostgreSQL.
```

---

## 7. Querying: order of execution, WHERE, LIKE, IN, ORDER BY, LIMIT, DISTINCT

### 7.1 How a query is really processed

```
1. FROM             which table(s)
2. WHERE            filter ROWS
3. GROUP BY         make groups
4. HAVING           filter GROUPS
5. SELECT           choose / compute columns (aliases are created here)
6. DISTINCT         remove duplicates
7. ORDER BY         sort
8. LIMIT/OFFSET     cut the result
```

➕ because of this order:

- can't use SELECT alias in WHERE (WHERE runs before SELECT creates it), but can use it in ORDER BY (and in GROUP BY in PostgreSQL).
- `COUNT(*)` can be in HAVING, never in WHERE.
- window functions run after HAVING, before SELECT finishes (so can't be used in WHERE, wrap in a subquery).

### 7.2 WHERE operators ➕

```sql
=  <>  !=  <  >  <=  >=                -- single =, not ==
BETWEEN a AND b                         -- inclusive on both ends
IN (1, 2, 3)   /   NOT IN (1, 2)
LIKE / ILIKE
IS NULL / IS NOT NULL
AND / OR / NOT
```

```sql
SELECT name, price FROM products WHERE price BETWEEN 999 AND 1999;    -- includes 999 and 1999
SELECT name FROM products WHERE is_active;                            -- same as = true
SELECT name FROM products WHERE NOT is_active;
```

### 7.3 Pattern matching: LIKE and ILIKE

- % means any number of characters (including none).
- _ means exactly one character.
- LIKE is case-sensitive. ILIKE is case-insensitive (PostgreSQL only).

```sql
SELECT name FROM products WHERE name LIKE 'Gaming%';     -- starts with: 3 rows
SELECT name FROM products WHERE name LIKE '%Mouse%';     -- contains: 2 rows
SELECT name FROM products WHERE name LIKE '%webcam%';    -- 0 rows (case matters)
SELECT name FROM products WHERE name ILIKE '%webcam%';   -- 3 rows
SELECT name FROM products WHERE name LIKE '_ebcam%';     -- 'Webcam HD', 'Webcam 4K'
```

- To search for a literal % or _, escape it with a backslash:

```sql
SELECT name FROM products WHERE name LIKE '%\%%';    -- 1 row: Cable_Organizer 50% Pack
SELECT name FROM products WHERE name LIKE '%_%';     -- 20 rows! (_ means "any one character")
```

➕ pro tip: `LIKE '%text%'` (leading %) can't use normal index, slow on big tables (index topic later).

### 7.4 Logical operators: AND, OR, NOT

-> Precedence: NOT first, then AND, then OR. Use brackets whenever you mix AND with OR.

```sql
SELECT name, category_id, is_active FROM products
WHERE category_id = 3 OR category_id = 4 AND is_active = false;     -- 5 rows

SELECT name, category_id, is_active FROM products
WHERE (category_id = 3 OR category_id = 4) AND is_active = false;   -- 1 row
```

### 7.5 IN and NOT IN

```
1=1 -> true
1=2 -> false
but, 1=(1, 2, 3) -> error | invalid syntax
```

```sql
select * from orders where status in ('delivered', 'placed');
```

```
 id | customer_id | ordered_at |  status
----+-------------+------------+-----------
  1 |           1 | 2026-09-01 | delivered
  3 |           2 | 2026-09-05 | delivered
  4 |           2 | 2026-10-02 | placed
  6 |           4 | 2026-10-05 | delivered
  7 |           4 | 2026-10-10 | placed
  8 |           1 | 2026-10-12 | placed
```

LLy for: NOT IN -> work opposite

```sql
select * from orders where status not in ('delivered', 'placed');
```

```
 id | customer_id | ordered_at |  status
----+-------------+------------+-----------
  2 |           1 | 2026-09-20 | shipped
  5 |           3 | 2026-09-12 | cancelled
```

➕ edge: `category_id NOT IN (1, 2)` drops rows where category_id is NULL (NULL NOT IN anything = unknown). And `NOT IN (subquery)` with a NULL inside the subquery returns 0 rows (see 11.3).

### 7.6 LIMIT and OFFSET

-> sorted id: 12 13 14 15 16 17 18 19 21 30

```sql
SELECT id, name FROM products ORDER BY id LIMIT 5;
-- id: 12 13 14 15 16

SELECT id, name FROM products ORDER BY id LIMIT 5 OFFSET 5;
-- id: 17 18 19 21 30
```

- OFFSET 5 skips the first 5 rows
- LIMIT 5 then returns the next 5 rows

➕ edge cases:

- OFFSET counts rows, not ids (ids have gaps). page formula: `OFFSET = (page - 1) * page_size`.
- no ORDER BY = no guaranteed order (UPDATE moves rows physically). Always ORDER BY, add `id` as last tie-breaker.
- if rows inserted/deleted between page 1 and page 2, a row can repeat or skip. Big OFFSET is slow too (keyset pagination later).
- `FETCH FIRST 5 ROWS ONLY` is standard SQL way of LIMIT.

### 7.7 DISTINCT: unique value

```sql
select distinct categories_id from products;
```

```
 categories_id
---------------

             1
             3
             2
```

```sql
select count(distinct rating) from products;
-- count = 9
```

DISTINCT treats NULLs as same (one NULL row), unlike `=`.

ex: Most expensive product per category:

```sql
SELECT DISTINCT categories_id, name, price FROM products order by categories_id, price desc;
```

```
 categories_id |            name             |  price
---------------+-----------------------------+---------
             1 | USB-C Hub                   | 1429.45
             1 | wireless headphone          | 1318.90
             1 | Laptop Stand                | 1098.90
             1 | Wireless Mouse              |  878.90
             1 | Phone Charger 20W           |  658.90
             2 | Noise Cancelling Headphones | 6598.90
             3 | Webcam 4K                   | 4499.00
             3 | Mechanical Keyboard         | 3848.90
             3 | Gaming Controller           | 3499.00
             3 | Gaming Headset              | 2999.00
             3 | Webcam HD                   | 2418.90
               | Wireless Mouses             | 6111.84
               | Old Webcam v1               |  548.90
               | demo item                   |  100.00
(14 rows)
```

-> but still we have some more product in same categories to remove we will use distinct on:
-> DISTINCT ON (PostgreSQL special) keeps the first row of each group, where "first" is decided by ORDER BY.
-> Most expensive product per category:

```sql
SELECT DISTINCT on (categories_id) categories_id, name, price FROM products order by categories_id, price desc;
```

```
 categories_id |            name             |  price
---------------+-----------------------------+---------
             1 | USB-C Hub                   | 1429.45
             2 | Noise Cancelling Headphones | 6598.90
             3 | Webcam 4K                   | 4499.00
               | Wireless Mouses             | 6111.84
(4 rows)
```

➕ edge: `ORDER BY` must start with the `DISTINCT ON` column(s). NULL category is its own group (last in ASC).

---

## 8. Aggregates, FILTER, GROUP BY, HAVING

### 8.1 Aggregates

An aggregate function turns many rows into one value. -> help in to calculate values from multiple rows

```
    @Function         @Result
    COUNT(*)         number of rows
    COUNT(col)         rows where col is not NULL
    COUNT(DISTINCT col) unique non-NULL values
    SUM, AVG, MIN, MAX ignore NULLs
```

```sql
SELECT COUNT(*), COUNT(rating), COUNT(DISTINCT category_id) FROM products;   -- 20, 17, 4
SELECT SUM(stock) FROM products;                                              -- 699
SELECT MIN(price), MAX(price) FROM products;                                  -- 199.00, 15999.00
SELECT ROUND(AVG(rating), 2) FROM products;                                   -- about 4.18
```

# NOTE: SUM & AVG ignore NULL, so do like

```
SUM(COALESCE(x, 0)) -> 0+x... dosn't mater but whole sum = null then use: COALESCE(sum(x), 0)
AVG(COALESCE(x, 0)) -> include null to 0 and consider & avg => null then: COALESCE(avg(x), 0)
```

➕ edge: aggregate over zero rows: COUNT = 0 but SUM / AVG = NULL. Can't mix plain column and aggregate in SELECT unless the plain column is in GROUP BY.

### 8.2 FILTER

FILTER is used with aggregate functions like COUNT(), SUM(), and AVG() to apply a condition to the rows used by that particular aggregate.

without filter;

```sql
SELECT
    COUNT(*) AS total_products,
    COUNT(*) AS active_products
FROM products
WHERE is_active = TRUE;
```

first it filter out the table and then count
but we want from total where how many are active
then use:
`select count(*) filter(condition) from table_name;`

```sql
select count(*) as total from products;
-- total = 14

select count(*) filter (where is_active) as active from products;
-- active = 12

select count(*) filter (where not is_active) as active from products;
-- active = 2
```

### 8.3 GROUP BY

GROUP BY combines rows that have the same value in a column into groups, so you can calculate something for each group using aggregate functions like COUNT(), SUM(), and AVG().

Imagine we have a students table:

```
    student_name department marks
    Rahul             IT       80
    Priya             CS       90
    Amit             IT       70
    Neha             CS       85
    Jay                 IT       95
```

- Without GROUP BY, AVG(marks) calculates one average across all students.

```sql
SELECT AVG(marks)
FROM students;
```

- but we want average for IT and CS

```sql
SELECT department, AVG(marks) AS average_marks
FROM students
GROUP BY department;
```

Result:

```
    department average_marks
    CS            87.5
    IT            81.67
```

ex:

```sql
select rating, count(*) as product from products group by rating order by rating;
```

```
 rating | product
--------+---------
    2.9 |       1
    3.8 |       1
    4.1 |       1
    4.2 |       1
    4.3 |       2
    4.5 |       1
    4.6 |       1
    4.7 |       1
    5.0 |       1
        |       4
(10 rows)
```

➕ rule: every column in SELECT must be in GROUP BY or inside an aggregate. Error `column "x" must appear in the GROUP BY clause or be used in an aggregate function` = this. NULL values form their own group.

### 8.4 HAVING ➕

- WHERE filters rows **before** grouping. HAVING filters groups **after** grouping.

```sql
-- WHERE: remove rows first, then group
SELECT category_id, COUNT(*) FROM products WHERE is_active GROUP BY category_id;

-- HAVING: group first, then remove groups
SELECT category_id, COUNT(*) FROM products GROUP BY category_id HAVING COUNT(*) > 3;
SELECT category_id, ROUND(AVG(price),2) FROM products GROUP BY category_id HAVING AVG(price) > 3000;
```

- find duplicates: `SELECT price, COUNT(*) FROM products GROUP BY price HAVING COUNT(*) > 1;`

---

## 9. Functions: string, date/time, casting, CASE

### 9.1 String functions

```
upper(), lower() initcap()
length()
left(name, 2), right(name, 2)
concat('hello', 'world')
concat_ws(' ', 'hello', 'world') -> with seperation
concat_ws(' + ', 'hello', 'world') -> with seperation
TRIM, LTRIM, RTRIM: trim('  hi   ') -> result: 'hi'
REPLACE REPLACE(name, 'Webcam', 'Camera') text replaced
substring(name FROM 1 FOR 4)  or  substring(name, 1, 4)   -> positions start at 1  ➕
position('Cam' IN name)  -> where it starts, 0 if not found  ➕
```

- the first word:

```sql
select SPLIT_PART(name, ' ', 1) from products;
```

```
 split_part
------------
 Old
 Wireless
 wireless
 Wireless
 USB-C
 Laptop
 ...
(14 rows)
```

-> with gaming how many:

```sql
select SPLIT_PART(name, ' ', 1) as first, count(*) from products group by first;
```

```
   first    | count
------------+-------
 Webcam     |     2
 wireless   |     1
 Gaming     |     2
 Old        |     1
 Noise      |     1
 demo       |     1
 Mechanical |     1
 Laptop     |     1
 Wireless   |     2
 Phone      |     1
 USB-C      |     1
```

➕ edge: `||` with NULL gives NULL, `concat` ignores NULL. Case-insensitive exact search: `WHERE LOWER(name) = LOWER('EARBUDS LITE')`.

### 9.2 Date and time

```sql
select current_time;
--      current_time
-- -----------------------
--  00:26:37.882587+05:30

select now();
--                now
-- ----------------------------------
--  2026-10-16 00:26:43.878188+05:30

select current_date;
--  2026-10-16

select now() + interval '7 day';       -- 2026-10-23 00:28:47
select now() + interval '5hr';         -- 2026-10-16 05:29:03
select now() + interval '5hour';       -- same
select now() + interval '5min';        -- 2026-10-16 00:34:33
```

➕ more:

| function | use | ex |
| --- | --- | --- |
| `EXTRACT(YEAR FROM col)` | pull a part (YEAR, MONTH, DAY, DOW, HOUR) | `EXTRACT(YEAR FROM launched_on)` |
| `DATE_TRUNC('month', col)` | cut to start of month/day/hour | group by month |
| `AGE(now(), col)` | human style difference | |
| `TO_CHAR(col, 'DD Mon YYYY')` | format for display | `05 Jan 2026` |
| `col::date` | timestamp -> date | |
| date - date | gives number of days | `'2026-09-20'::date - '2026-09-01'::date = 19` |

```sql
SELECT DATE_TRUNC('month', created_at) AS month, COUNT(*) FROM products GROUP BY month ORDER BY month;
SHOW timezone;       -- session timezone, DATE_TRUNC on timestamptz uses it
```

### 9.3 BETWEEN trap (dates)

```sql
-- looks right, but loses a row
SELECT name, created_at FROM products
WHERE created_at BETWEEN '2026-10-01' AND '2026-10-13';        -- 1 row

-- correct: start inclusive, end exclusive (the next day at 00:00)
SELECT name, created_at FROM products
WHERE created_at >= '2026-10-01' AND created_at < '2026-10-14';   -- 2 rows
```

-> '2026-10-13' means midnight at the start of the 13th, so the Monitor created at 23:30 on the 13th is missed. Use the >= start AND < next day pattern for time ranges every time.
-> lly launched_on >= '2024-01-01' AND launched_on < '2025-01-01'
-> (also index friendly, `EXTRACT(YEAR FROM launched_on) = 2024` is not)

### 9.4 Cast / casting: convert one datatype to another datatype

-> two way:

1.

```sql
select '123'::integer;

select '123'::text ;
```

- even though look same but type text

1.

```sql
select cast('123' as text);

select cast('123' as numeric);
```

```
@Syntax                 @Meaning
value::TYPE             PostgreSQL's shorthand syntax
CAST(value AS TYPE)     Standard SQL syntax
```

# why imp

```sql
select 7/2;            -- 3 but actual 3.5
select 7::numeric / 2; -- 3.5
select 7 / 2.0;        -- 3.5
```

➕ edge: integer / integer = integer (percentage trap), use `* 100.0`. Wrong text -> number gives error (`'abc'::int`).

### 9.5 CASE: if/else in PostgreSQL

```sql
select case when 10>5 then 'true' else 'false' end as result;

select
    case
        when 10>5 then 'true'
        else 'false'
    end as result;
```

- both same just look different...

```sql
select name, price, case when price<=1000 then 'less' when price <=2000 then 'medium' else 'more' end as amount from products;
```

```
            name             |  price  | amount
-----------------------------+---------+--------
 Old Webcam v1               |  548.90 | less
 Wireless Mouses             | 6111.84 | more
 wireless headphone          | 1318.90 | medium
 Wireless Mouse              |  878.90 | less
 USB-C Hub                   | 1429.45 | medium
 Laptop Stand                | 1098.90 | medium
 Phone Charger 20W           |  658.90 | less
 Noise Cancelling Headphones | 6598.90 | more
 ...
(14 rows)
```

=> What if you omit ELSE?

- there is no ELSE, so the result is NULL.
- first matching WHEN wins, so order matters.

# Group by a case

```sql
select case when price<=1000 then 'less' when price <=2000 then 'medium' else 'more' end as amount from products group by amount;
```

```
 amount
--------
 more
 medium
 less
(3 rows)
```

```sql
select case when price<=1000 then 'less' when price <=2000 then 'medium' else 'more' end as amount, count(*) from products group by amount;
```

```
 amount | count
--------+-------
 more   |     7
 medium |     3
 less   |     4
(3 rows)
```

# Conditional aggregation (very common in reports and interviews)

```sql
SELECT category_id,
       SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_count,
       SUM(CASE WHEN NOT is_active THEN 1 ELSE 0 END) AS inactive_count
FROM products GROUP BY category_id;
```

---

## 10. Joins

### 10.1 What a join is (and the tiny A / B example) ➕

- join = put rows of two tables side by side using a related column.
- mental model: pair every row of A with every row of B, keep pairs where `ON` is true (INNER). For outer joins add back rows with no partner, filled with NULL.

```sql
-- A has ids 1,2,3. B has ids 2,3,4.
SELECT a.id AS a_id, a.val AS a_val, b.id AS b_id, b.val AS b_val
FROM (VALUES (1,'x'), (2,'y'), (3,'z')) AS a(id, val)
INNER JOIN (VALUES (2,'p'), (3,'q'), (4,'r')) AS b(id, val) ON a.id = b.id;
```

| join | rows |
| --- | --- |
| INNER | ids 2, 3 |
| LEFT | ids 1, 2, 3 (1 has NULL on B side) |
| RIGHT | ids 2, 3, 4 |
| FULL | ids 1, 2, 3, 4 |
| CROSS (no ON) | 9 rows (every A with every B) |

### 10.2 JOIN types (my notes)

JOIN:
Combines rows from two tables using a related column.
Example tables:

- products: categories_id
- categories: id

INNER JOIN:
Returns only rows with a match in both tables.
Example:

```sql
SELECT p.name, c.name AS category
FROM products p
INNER JOIN categories c ON p.categories_id = c.id;
```

Our example: 11 rows.

LEFT JOIN:
Returns every row from the left table (products) and matching rows from categories.
No match on the right -> right-side columns are NULL.
Our example: 14 rows.

RIGHT JOIN:
Returns every row from the right table (categories) and matching rows from products.
No match on the left -> left-side columns are NULL.
Our example: 13 rows.

FULL OUTER JOIN:
Returns all rows from both tables, matching where possible.
Unmatched rows have NULLs for the other table's columns.
Our example: 16 rows.

QUICK COMPARISON:

```
INNER = matching rows only
LEFT  = all left-table rows + matches
RIGHT = all right-table rows + matches
FULL  = all rows from both tables
```

Find products without a category:

```sql
SELECT p.id, p.name
FROM products p
LEFT JOIN categories c ON p.categories_id = c.id
WHERE c.id IS NULL;
```

Find categories without products:

```sql
SELECT c.id, c.name
FROM categories c
LEFT JOIN products p ON p.categories_id = c.id
WHERE p.id IS NULL;
```

NOTES:

- ON specifies how the tables are related.
- p and c are table aliases.
- ORDER BY sorts the output; it does not change which rows the JOIN returns.
- LEFT OUTER JOIN = LEFT JOIN; RIGHT OUTER JOIN = RIGHT JOIN.

➕ edge cases:

- same column name in both tables (`name`) -> must write `p.name`, else `column reference "name" is ambiguous`. After aliasing a table use only the alias.
- NULL never matches in `ON a.x = b.x` (that is why products with NULL category vanish in INNER JOIN).
- RIGHT JOIN is rare, swap table order and use LEFT.
- `NATURAL JOIN` joins on all same named columns automatically (id + name here), avoid, always write ON.
- **COUNT trap**: after LEFT JOIN use `COUNT(p.id)` (right table column), not `COUNT(*)`, else empty category shows 1.
- **ON vs WHERE in outer join**: filter on right table inside `ON` keeps unmatched left rows; same filter in `WHERE` removes them (LEFT turns into INNER).

```sql
-- all customers, only their delivered orders
SELECT c.name, o.id FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id AND o.status = 'delivered';      -- 6 rows
-- same filter in WHERE
... LEFT JOIN orders o ON o.customer_id = c.id WHERE o.status = 'delivered';  -- 3 rows
```

- FULL JOIN use: reconcile, `WHERE p.id IS NULL OR c.id IS NULL` = rows on only one side.
- CROSS JOIN: all combinations (old `FROM a, b` without WHERE does it by mistake).

### 10.3 Self join ➕

table joined to itself, alias twice (`c` = customer, `r` = referrer):

```sql
SELECT c.name AS customer, COALESCE(r.name, 'direct') AS referred_by
FROM customers c
LEFT JOIN customers r ON r.id = c.referred_by;
```

- LEFT because first customers have no referrer.
- interview: employees who earn more than their manager:

```sql
SELECT e.name FROM employees e JOIN employees m ON m.id = e.manager_id WHERE e.salary > m.salary;
```

### 10.4 MULTI-JOIN in PostgreSQL

1. Meaning
Multi-JOIN means joining three or more tables in one SQL query to get related information.

2. Example table relationships

```
customers.id = orders.customer_id
orders.id = order_items.order_id
order_items.product_id = products.id
```

1. Example: Join four tables

```sql
SELECT
    c.name AS customer_name,
    o.id AS order_id,
    p.name AS product_name,
    oi.quantity,
    p.price
FROM customers c
JOIN orders o
    ON o.customer_id = c.id
JOIN order_items oi
    ON oi.order_id = o.id
JOIN products p
    ON p.id = oi.product_id
ORDER BY o.id;
```

Explanation:

- First JOIN connects customers with their orders.
- Second JOIN connects orders with their order items.
- Third JOIN connects order items with product details.
- SELECT chooses the columns to display.
- Each ON condition tells PostgreSQL how the tables are related.

1. Example: Three-table JOIN
To show each customer's name, order ID, and order status:

```sql
SELECT
    c.name,
    o.id AS order_id,
    o.status
FROM customers c
JOIN orders o
    ON o.customer_id = c.id;
```

1. JOIN types

- INNER JOIN (or JOIN): returns only matching rows.
- LEFT JOIN: keeps every row from the left table, even if no matching row exists on the right.
- RIGHT JOIN: keeps every row from the right table, even if no matching row exists on the left.

1. Example: LEFT JOIN
Show all orders, including orders that have no order items:

```sql
SELECT
    o.id AS order_id,
    o.status,
    oi.product_id,
    oi.quantity
FROM orders o
LEFT JOIN order_items oi
    ON oi.order_id = o.id;
```

Important:
With multiple JOINs, the JOIN type matters. A later INNER JOIN can remove rows that an earlier LEFT JOIN preserved.

1. Practice question
Display every customer's name, order ID, and order status. Include customers who have never placed an order.

Solution:

```sql
SELECT c.name, o.id AS order_id, o.status
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.id
ORDER BY c.id, o.id;
```

KEY POINT
For each additional table, add a JOIN and specify how it relates to the existing tables using ON.

➕ **fan-out trap**: joining parent to child repeats parent once per child. Aarav has 3 orders but 6 rows after joining items, so `COUNT(*)` = 6, use `COUNT(DISTINCT o.id)` = 3. Summing an order-level column after joining items counts it once per item. Instagram version: post with 3 likes + 4 comments = 12 rows if both joined together. Fix: aggregate each child separately first (subquery/CTE), then join.

### 10.5 Aggregating over a JOIN

Combining related rows from multiple tables and then calculating a summary using aggregate functions such as SUM(), COUNT(), AVG(), MIN(), or MAX().

ex:

categories:

- id: category's primary key
- name: category name

products:

- id: product's primary key
- name: product name
- price: product price
- categories_id: foreign key referencing categories.id

Relationship: products.categories_id = categories.id

```sql
SELECT
    c.id,
    c.name,
    SUM(p.price) AS total_price
FROM categories c
JOIN products p
    ON p.categories_id = c.id
GROUP BY c.id, c.name
ORDER BY total_price DESC; --optional to order
```

-> group by only c.id or c.name both work for this example but:
Why GROUP BY both id and name?

- c.id uniquely identifies a category.
- c.name is included to display the category name and make the grouping explicit.
- Grouping by ID avoids accidentally combining two different categories if they share the same name.
- In PostgreSQL, grouping by a primary key alone may allow selecting its dependent name, but GROUP BY c.id, c.name is explicit and portable across databases.

JOIN versus LEFT JOIN
INNER JOIN (written as JOIN):

- Includes only categories that have matching products.
- Categories without products do not appear.

Query to include categories with no products and show their total as 0:

```sql
SELECT
    c.id,
    c.name,
    COALESCE(SUM(p.price), 0) AS total_price
FROM categories c
LEFT JOIN products p
    ON p.categories_id = c.id
GROUP BY c.id, c.name
ORDER BY total_price DESC;
```

Important notes

- SUM(p.price) totals product prices; it does not calculate sales revenue.
- For sales revenue, use order_items and calculate SUM(p.price * oi.quantity), joining order_items to products through oi.product_id = p.id. Join orders too if filtering or grouping by order/customer details. (better: use `oi.unit_price`, the price at purchase time)
- Without ORDER BY, output row order is not guaranteed.
- GROUP BY c.name alone can merge separate categories with identical names. Grouping by c.id, c.name keeps categories distinct.
- Aggregate functions can include SUM(), COUNT(), AVG(), MIN(), and MAX().

### 10.6 Joins inside UPDATE and DELETE

-> In PostgreSQL, use UPDATE ... FROM to update products based on another table.

Example: Increase the price of products in the Accessories category by 10%.

```sql
UPDATE products p
SET price = p.price * 1.10
FROM categories c
WHERE p.categories_id = c.id
  AND c.name = 'Accessories';
```

-> PostgreSQL uses DELETE ... USING to delete rows based on another table.

Example: Delete products belonging to the Accessories category.

```sql
DELETE FROM products p
USING categories c
WHERE p.categories_id = c.id
  AND c.name = 'Accessories';
```

```
=====================================================
# Remember:
=====================================================
    Operation                 PostgreSQL_syntax
-----------------------------------------------------
Read data from joined tables SELECT ... JOIN
Update using another table     UPDATE ... FROM
Delete using another table     DELETE ... USING
=====================================================
```

➕ edge: in `SET` the target column has no alias (`SET price = ...`, not `SET p.price`). If one target row matches many FROM rows, PostgreSQL silently uses one of them. Test in `BEGIN ... ROLLBACK` first.

### 10.7 Connecting 3 tables in PostgreSQL

Example relationship:

- `reviews.product_id` -> `products.id`
- `products.categories_id` -> `categories.id`

1. SELECT — Retrieve data

```sql
SELECT r.id, p.name, c.name AS category
FROM reviews r
JOIN products p ON p.id = r.product_id
JOIN categories c ON c.id = p.categories_id
WHERE c.name = 'Gaming';
```

Use `JOIN` to connect tables and `ON` to specify how their rows match.

1. UPDATE — Update matching rows

```sql
UPDATE reviews r
SET helpful_votes = r.helpful_votes + 1
FROM products p
JOIN categories c ON c.id = p.categories_id
WHERE p.id = r.product_id
  AND c.name = 'Gaming'
RETURNING r.id, r.helpful_votes;
```

Important: Connect the `UPDATE` target table to the joined tables in `WHERE`. Otherwise, you might update unintended rows.

1. DELETE — Delete matching rows

```sql
DELETE FROM reviews r
USING products p
JOIN categories c ON c.id = p.categories_id
WHERE p.id = r.product_id
  AND c.name = 'Gaming'
RETURNING r.id, r.product_id;
```

- `DELETE FROM reviews` specifies which table's rows will be deleted.
- `USING` supplies the other tables.
- `WHERE` connects the tables and filters the rows to delete.
- `RETURNING` shows the deleted rows.

| Operation | How to connect tables |
| --------- | -------------------------------------------------------- |
| `SELECT`  | `FROM` + `JOIN ... ON`                                   |
| `UPDATE`  | `UPDATE` + `FROM` + matching conditions in `WHERE`       |
| `DELETE`  | `DELETE FROM` + `USING` + matching conditions in `WHERE` |

Golden rule: Always connect the tables correctly and check your `WHERE` conditions before running an `UPDATE` or `DELETE`.

ex:

```sql
update reviews r set helpful_votes = helpful_votes + 1 from products p join categories c on c.id = p.categories_id where r.product_id = p.id and c.name = 'Gaming';
-- UPDATE 2
select * from reviews;
```

```
 id | customer_id | product_id | rating |         body         | reviewed_on | verified_purchase | helpful_votes
----+-------------+------------+--------+----------------------+-------------+-------------------+---------------
  6 |           3 |         16 |    2.0 | Never arrived        | 2026-09-20  | f                 |             2
 10 |           5 |         12 |    4.0 | Bought from a friend | 2026-10-10  | f                 |             2
 14 |           3 |         37 |    4.0 | Decent webcam        | 2026-10-14  | f                 |             2
 16 |           1 |         12 |    4.0 | Update: still good   | 2026-10-15  | t                 |             2
 ...
 12 |           6 |         39 |    1.0 | Stopped working      | 2026-10-12  | f                 |             3
  9 |           4 |         38 |    5.0 | Perfect controller   | 2026-10-09  | t                 |             3
(14 rows)
```

---

## 11. Subqueries, EXISTS, CTE, set operations ➕

(this whole chapter was only read before, not in my notes. Practice it with the 30 questions.)

### 11.1 Subquery = query inside another query

```sql
-- 1. scalar (one value): products above average price
SELECT name, price FROM products WHERE price > (SELECT AVG(price) FROM products);

-- 2. list with IN
SELECT name FROM customers WHERE id IN (SELECT customer_id FROM orders);

-- 3. correlated (runs again for every outer row): above their own category average
SELECT p.name FROM products p
WHERE p.price > (SELECT AVG(p2.price) FROM products p2 WHERE p2.category_id = p.category_id);
```

- 4th kind = derived table (subquery in FROM, must have alias). CTE is cleaner for that.
- scalar subquery returning more than 1 row = error.
- edge: in the correlated one, products with NULL category silently disappear (`category_id = NULL` never matches, AVG is NULL, `price > NULL` is not true).

### 11.2 EXISTS and NOT EXISTS

EXISTS is true if subquery returns at least one row (stops at first match). `SELECT 1` is just convention.

```sql
-- customers with at least one delivered order
SELECT c.name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.status = 'delivered');

-- customers with no orders
SELECT c.name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

### 11.3 NOT IN trap (most asked)

```sql
SELECT name FROM categories WHERE id NOT IN (SELECT category_id FROM products);     -- 0 rows!
SELECT c.name FROM categories c
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.category_id = c.id);             -- correct
```

- subquery returns `{1,2,3,4,NULL}`, and `5 NOT IN (...NULL)` is unknown, never true.
- **rule: use NOT EXISTS (not NOT IN) when subquery column can be NULL.**

### 11.4 ANY / ALL

```sql
WHERE price > ALL (SELECT price FROM products WHERE category_id = 2)   -- more than every Audio product
WHERE price > ANY (SELECT price FROM products WHERE category_id = 2)   -- more than at least one
```

- `= ANY(...)` is same as `IN`.

### 11.5 IN vs EXISTS vs JOIN

| | JOIN | IN / EXISTS |
| --- | --- | --- |
| duplicates | can multiply rows (customer with 3 mouse orders appears 3 times) | outer row only once |
| columns of other table | available | not available |
| use when | need data from both tables | only yes/no test |
| NULL | n/a | NOT IN breaks, NOT EXISTS safe |

### 11.6 CTE (WITH) = named temporary result for one query

```sql
WITH spend AS (
    SELECT c.id, c.name, COALESCE(SUM(i.quantity * i.unit_price), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o      ON o.customer_id = c.id AND o.status <> 'cancelled'
    LEFT JOIN order_items i ON i.order_id = o.id
    GROUP BY c.id, c.name
)
SELECT name, total_spent
FROM spend
WHERE total_spent > (SELECT AVG(total_spent) FROM spend);
```

- can write many: `WITH a AS (...), b AS (... FROM a ...) SELECT ...`
- fan-out fix: make one CTE per child table (one row per customer), then join them.
- average over all 6 customers vs only customers who bought = different answer, in interview ask which one.
- PG 12+: CTE used once is inlined, `AS MATERIALIZED` forces run once.
- CTE exists for this one query only.
- (optional, rare for freshers) recursive CTE = hierarchy of unknown depth (referral chain, comment replies):

```sql
WITH RECURSIVE chain AS (
    SELECT id, name, referred_by, 1 AS depth FROM customers WHERE id = 1     -- anchor
    UNION ALL
    SELECT c.id, c.name, c.referred_by, ch.depth + 1
    FROM customers c JOIN chain ch ON c.referred_by = ch.id                  -- next level
)
SELECT depth, name FROM chain ORDER BY depth, id;
```

  stops when a round gives no new rows. Cycle in data = infinite loop, guard with `WHERE ch.depth < 10`.

### 11.7 Set operations (stack results one below other)

| operator | result |
| --- | --- |
| UNION | all rows of both, duplicates removed |
| UNION ALL | all rows, duplicates kept (faster) |
| INTERSECT | rows in both |
| EXCEPT | rows in first but not in second |

```sql
SELECT customer_id FROM reviews
EXCEPT
SELECT customer_id FROM orders;          -- reviewed but never ordered
```

- rules: same number of columns, compatible types, names come from first query, `ORDER BY` only once at the end.
- use UNION ALL unless duplicates must go (UNION sorts).
- EXCEPT = clean way to compare two tables.

### 11.8 Which tool?

| question | tool |
| --- | --- |
| columns from related tables | JOIN |
| rows with no match | LEFT JOIN ... IS NULL or NOT EXISTS |
| does related row exist | EXISTS |
| compare row to aggregate | scalar / correlated subquery |
| step by step readable | CTE |
| stack / compare result sets | UNION / INTERSECT / EXCEPT |

---

## 12. Window functions

- GROUP BY collapses rows into one row per group. A window function computes across related rows but keeps every row, adding a new column

# Syntax

```
function(...) OVER ( [PARTITION BY cols] [ORDER BY cols] [frame] )
```

EX:

```sql
-- GROUP BY: one row per category
SELECT categories_id, ROUND(AVG(price), 2) FROM products GROUP BY categories_id;
```

```
 categories_id |  round
---------------+---------
               | 2453.58
             1 | 1277.01
             3 | 3652.96
             2 | 6798.90
(4 rows)
```

```sql
-- window: every row is kept, each with its category's average attached
SELECT name, categories_id, price,
       ROUND(AVG(price) OVER (PARTITION BY categories_id), 2) AS categories_avg
FROM products;
```

```
            name             | categories_id |  price  | categories_avg
-----------------------------+---------------+---------+----------------
 Phone Charger 20W           |             1 |  858.90 |        1277.01
 wireless headphone          |             1 | 1518.90 |        1277.01
 Wireless Mouse              |             1 | 1078.90 |        1277.01
 USB-C Hub                   |             1 | 1629.45 |        1277.01
 Laptop Stand                |             1 | 1298.90 |        1277.01
 Noise Cancelling Headphones |             2 | 6798.90 |        6798.90
 Gaming Headset              |             3 | 3199.00 |        3652.96
 Webcam HD                   |             3 | 2618.90 |        3652.96
 Webcam 4K                   |             3 | 4699.00 |        3652.96
 Gaming Controller           |             3 | 3699.00 |        3652.96
 Mechanical Keyboard         |             3 | 4048.90 |        3652.96
 Wireless Mouses             |               | 6311.84 |        2453.58
 demo item                   |               |  300.00 |        2453.58
 Old Webcam v1               |               |  748.90 |        2453.58
(14 rows)
```

➕ parts:

- `PARTITION BY` = split rows in groups (without collapsing). No PARTITION BY = whole table is one group.
- `ORDER BY` inside OVER = order inside each partition.
- frame = which nearby rows are used.

| family | functions |
| --- | --- |
| aggregate as window | SUM, AVG, COUNT, MIN, MAX ... OVER |
| ranking | ROW_NUMBER, RANK, DENSE_RANK, NTILE |
| navigation | LAG, LEAD, FIRST_VALUE, LAST_VALUE |

### 12.1 ROW_NUMBER vs RANK vs DENSE_RANK (interview)

```sql
SELECT name, price,
       ROW_NUMBER() OVER (ORDER BY price DESC, id) AS row_num,
       RANK()       OVER (ORDER BY price DESC)     AS rnk,
       DENSE_RANK() OVER (ORDER BY price DESC)     AS dense_rnk
FROM products ORDER BY price DESC, id;
```

| name | price | ROW_NUMBER | RANK | DENSE_RANK |
| --- | --- | --- | --- | --- |
| Webcam 4K | 4499 | 6 | 6 | 6 |
| Mechanical Keyboard | 3499 | 7 | 7 | 7 |
| Gaming Controller | 3499 | 8 | 7 | 7 |
| Gaming Headset | 2999 | 9 | 9 | 8 |
| Webcam HD | 2199 | 10 | 10 | 9 |

- ROW_NUMBER: always unique, ties broken randomly (add tiebreaker like id).
- RANK: tie same rank, then **skips** (7, 7, 9).
- DENSE_RANK: tie same rank, **no gap** (7, 7, 8).
- NTILE(4): 4 buckets of almost equal size (14 rows = 4, 4, 3, 3).

### 12.2 Top N per group

```sql
SELECT category_id, name, price
FROM (
    SELECT category_id, name, price,
           ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC, id) AS rn
    FROM products
) t
WHERE rn <= 2;
```

- can't write `WHERE ROW_NUMBER() OVER (...) <= 2`, window runs after WHERE. Wrap in subquery/CTE and filter outside.
- NULL category is its own partition.
- same idea: latest review per product (`PARTITION BY product_id ORDER BY reviewed_on DESC`, `rn = 1`), or `DISTINCT ON`.

### 12.3 LAG / LEAD

```sql
SELECT customer_id, id AS order_id, ordered_at,
       ordered_at - LAG(ordered_at) OVER (PARTITION BY customer_id ORDER BY ordered_at) AS days_since_prev
FROM orders;
```

- first row gives NULL (no previous). `LAG(col, 1, default)` fills it.
- LEAD = next row.

### 12.4 Running total and frame trap

- `SUM(x) OVER (ORDER BY ...)` = running total. `SUM(x) OVER ()` = grand total on every row. Percent of total: `price * 100.0 / SUM(price) OVER ()`.
- default frame with ORDER BY treats **ties as same row** (RANGE), so at two 3499 rows running total shows 58992 on both. Use `ROWS UNBOUNDED PRECEDING` for true row by row.
- `LAST_VALUE` returns own row with default frame, use `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`.
- reuse: `OVER w ... WINDOW w AS (PARTITION BY x ORDER BY y)`.

### 12.5 Edge cases

- window functions only in SELECT and ORDER BY.
- PARTITION BY treats NULLs as one group. Aggregate windows ignore NULL.
- need sorting, index on partition + order columns helps (later).

---

## 13. JSON / JSONB ➕

- JSON column = flexible / optional data (product specs, settings). Not for data I filter/join all the time (no FK, no type check there) -> real column.
- `json` = exact text copy. `jsonb` = binary, no duplicate keys, can be indexed. Use **jsonb** almost always.

```sql
WITH t AS (
  SELECT '{"brand": "Sony", "wireless": true, "colors": ["black", "blue"], "warranty_months": 12, "note": null}'::jsonb AS d
)
SELECT d -> 'brand'                       AS a,   -- "Sony"  (jsonb with quotes)
       d ->> 'brand'                      AS b,   -- Sony    (text)
       d -> 'colors' -> 0                 AS c,   -- "black"
       d #>> '{colors,1}'                 AS d2,  -- blue    (path as text)
       d ->> 'weight'                     AS e,   -- NULL    (missing key = NULL, no error)
       (d ->> 'warranty_months')::int + 1 AS f,   -- 13
       d @> '{"wireless": true}'          AS g,   -- true    (contains)
       d ? 'brand'                        AS h,   -- true    (key exists)
       (d -> 'colors') ? 'blue'           AS i    -- true    (array has this string)
FROM t;
```

| operator | meaning |
| --- | --- |
| `->` | get field/array item as jsonb |
| `->>` | get as text |
| `#>` / `#>>` | follow a path |
| `@>` | left contains right |
| `?` | key (or array string) exists |
| `\|\|` | merge objects |
| `-` | remove a key |

Change (returns new value, so `UPDATE ... SET col = ...`):

```sql
UPDATE products SET attributes = jsonb_set(attributes, '{wireless}', 'true') WHERE id = 12;
UPDATE products SET attributes = attributes - 'switch' WHERE id = 2;
UPDATE products SET attributes = attributes || '{"color_count": 2}' WHERE id = 6;
```

One row per array item:

```sql
SELECT p.name, c AS colour
FROM products p, jsonb_array_elements_text(p.attributes -> 'colors') AS c;
```

Edge cases:

- `attributes -> 'brand' = 'Sony'` fails (jsonb vs text), use `->>`.
- numbers come out as text via `->>`, cast `(...)::int` before compare/maths.
- JSON `null` is not SQL `NULL` (`->` gives json null, `->>` gives SQL NULL).
- missing key / typo = NULL silently.
- `jsonb_set` on path whose parent doesn't exist changes nothing silently.
- `jsonb_array_elements*` on non-array = error, on NULL = zero rows.
- update of one key rewrites whole value (big changing JSON is slow).
- index: GIN for `@>` and `?`, expression index for `(attributes ->> 'brand')`. normal B-tree on column doesn't help.
- some drivers treat `?` as placeholder, use `jsonb_exists(d, 'key')`.
- type JSON inside a `.sql` file, PowerShell `-c "..."` messes the quotes.

---

## 14. Transactions (basic) ➕

- transaction = group of statements, all happen or none (the A in ACID).
- by default each statement is its own transaction (auto commit).

```sql
BEGIN;                 -- start
UPDATE products SET stock = stock - 1 WHERE id = 1;
SELECT stock FROM products WHERE id = 1;
ROLLBACK;              -- undo all   (COMMIT; = keep)
```

- if one statement errors inside, the whole transaction is aborted (`current transaction is aborted`), do `ROLLBACK;` and start again.
- PostgreSQL has transactional DDL: `ALTER TABLE` / `CREATE TABLE` inside BEGIN can also be rolled back (great for testing).
- use it as sandbox before risky `UPDATE` / `DELETE`.
- isolation levels, locks, deadlocks, UPSERT, views, triggers -> coming in later phase.

---

## 15. Interview quick facts

```
1. NULL = NULL
   Returns UNKNOWN, not TRUE. Use IS NULL to check missing values.

2. TIMESTAMPTZ vs TIMESTAMP
   Use TIMESTAMPTZ for events representing a real point in time, such as order creation.

3. NUMERIC vs REAL
   Use NUMERIC for exact decimal values like prices and wallet balances; REAL is approximate.

4. Integer division
   7 / 2 returns 3. Use 7::numeric / 2 to get 3.5.

5. RETURNING
   Returns affected rows after INSERT, UPDATE, or DELETE. APIs use it to retrieve generated IDs and updated data without another query.

6. Named constraints
   Meaningful names make constraints easier to identify, debug, and drop.
```

➕ more one-liners:

- WHERE vs HAVING: WHERE filters rows before grouping, HAVING filters groups after.
- order of execution: FROM, WHERE, GROUP BY, HAVING, SELECT, DISTINCT, ORDER BY, LIMIT.
- DELETE vs TRUNCATE vs DROP: chosen rows / all rows fast / rows and table.
- primary key vs unique: one per table, never NULL / many, NULL allowed.
- `COUNT(*)` vs `COUNT(col)` vs `COUNT(DISTINCT col)`: all rows / non-NULL / unique non-NULL.
- `UNION` vs `UNION ALL`: dedupe vs keep all.
- INNER / LEFT / RIGHT / FULL / CROSS: matches / all left / all right / all both / every combination.
- IN vs EXISTS vs JOIN: JOIN can duplicate rows, EXISTS is yes/no. NOT IN breaks with NULL.
- `->` vs `->>`: jsonb vs text.
- RANK vs DENSE_RANK: skips numbers after tie vs no gap.
- second highest price: `SELECT DISTINCT price ... ORDER BY price DESC LIMIT 1 OFFSET 1` (DISTINCT because of ties) or `MAX(price) WHERE price < (SELECT MAX(price)...)`.
- find duplicates: `GROUP BY col HAVING COUNT(*) > 1`. delete duplicates keep latest: `DELETE ... USING` self join `r.id < newer.id`.
- 3NF: depends on the key, the whole key, nothing but the key.
- serial vs identity, identity vs uuid, surrogate vs natural key.
- FK delete rules: NO ACTION / RESTRICT / CASCADE / SET NULL / SET DEFAULT.
- ACID: atomicity, consistency, isolation, durability.

---

## 16. Common errors ➕

| error | meaning / fix |
| --- | --- |
| `syntax error at or near "..."` | problem is just **before** that word, check commas and order |
| `column reference "name" is ambiguous` | same column in two tables, write `p.name` |
| `column "x" must appear in the GROUP BY clause or be used in an aggregate function` | add to GROUP BY or aggregate it |
| `relation "products" does not exist` | wrong database, typo, or table not created |
| `null value in column "x" violates not-null constraint` | NULL sent to NOT NULL column |
| `duplicate key value violates unique constraint "uq_..."` | duplicate in UNIQUE / PK |
| `violates foreign key constraint "fk_..."` | parent row missing (insert) or children still exist (delete) |
| `violates check constraint "ck_..."` | value breaks CHECK |
| `numeric field overflow` | value too big for `numeric(p,s)` |
| `value too long for type character varying(n)` | text longer than n |
| `invalid input syntax for type numeric: "abc"` | wrong type of value |
| `cannot insert a non-DEFAULT value into column "id"` | identity ALWAYS, don't give id (or `OVERRIDING SYSTEM VALUE`) |
| `division by zero` | use `NULLIF(x, 0)` |
| `current transaction is aborted` | earlier error inside BEGIN, `ROLLBACK;` |
| prompt `postgres-#` | statement not finished, type `;` |
| `cannot drop the currently open database` | `\c postgres` first |
| `database is being accessed by other users` | disconnect pgAdmin or `WITH (FORCE)` |
| `schema/x.sql: No such file or directory` | psql started from wrong folder, start from project root |

---

## 17. Not covered yet (will add when I finish the phases)

- Instagram database design + feature queries (profile, feed, comments, likes, follows, search)
- Indexes (B-tree, GIN, composite, partial), `EXPLAIN ANALYZE`, keyset pagination, performance
- Transactions deeper: isolation levels, locks, deadlocks, race conditions, UPSERT (`ON CONFLICT`)
- Views, materialized views, functions, procedures, triggers
- API style queries, SQL injection, roles and privileges, backup deeper (`pg_dump` basics are in 1.8)
- Folder structure applied to the Instagram project (general full stack structure is in 1.9)

---
