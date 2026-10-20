CREATE TABLE orders (
    id           integer GENERATED ALWAYS AS IDENTITY,
    customer_id  integer     NOT NULL,
    ordered_at   date        NOT NULL,
    status       varchar(12) NOT NULL DEFAULT 'placed',
    CONSTRAINT pk_orders PRIMARY KEY (id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (id),
    CONSTRAINT ck_orders_status CHECK (status IN ('placed', 'shipped', 'delivered', 'cancelled'))
);
