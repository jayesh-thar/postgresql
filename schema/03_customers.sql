CREATE TABLE customers (
    id           integer GENERATED ALWAYS AS IDENTITY,
    name         varchar(80) NOT NULL,
    city         varchar(50),
    referred_by  integer,
    joined_on    date NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_customers PRIMARY KEY (id),
    CONSTRAINT fk_customers_referred_by FOREIGN KEY (referred_by)
        REFERENCES customers (id) ON DELETE SET NULL
);
