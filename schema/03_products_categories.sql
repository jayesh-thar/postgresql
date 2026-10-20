create table categories (
    id INTEGER generated always as identity,
    name varchar(50) not null UNIQUE
);


alter table categories
    add constraint categories_pkey PRIMARY KEY(id);

-- select * from categories;






