-- Step 1: Create a new database and schema with appropriate names
CREATE DATABASE auction_db;

CREATE SCHEMA auction_schema;

-- Step 2: Define tables based on the 3NF model with appropriate data types and constraints
-- Table: seller
CREATE TABLE IF NOT EXISTS auction_schema.seller (
    s_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    s_f_name varchar(150),
    s_l_name varchar(150),
    s_address varchar(250),
    s_email varchar(150) UNIQUE NOT NULL
);

-- Table: buyer
CREATE TABLE IF NOT EXISTS auction_schema.buyer (
    b_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    b_f_name varchar(150),
    b_l_name varchar(150),
    b_address varchar(250),
    b_email varchar(150) UNIQUE NOT NULL
);

-- Table: item
CREATE TABLE IF NOT EXISTS auction_schema.item (
    i_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    i_l_num integer UNIQUE NOT NULL,
    i_description varchar(3000),
    i_s_price money DEFAULT 100.00,
    s_id_seller integer REFERENCES auction_schema.seller(s_id) ON DELETE SET NULL
);


-- Table: category
CREATE TABLE IF NOT EXISTS auction_schema.category (
    c_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    c_name varchar(150)
);

-- Table: m2m_Item_buyer
CREATE TABLE IF NOT EXISTS auction_schema."m2m_item_buyer" (
    i_id_item integer REFERENCES auction_schema.item(i_id),
    b_id_buyer integer REFERENCES auction_schema.buyer(b_id),
    PRIMARY KEY (i_id_item, b_id_buyer)
);


-- Table: m2m_item_category
CREATE TABLE IF NOT EXISTS auction_schema."m2m_item_category" (
    i_id_item integer REFERENCES auction_schema.item(i_id),
    c_id_category integer REFERENCES auction_schema.category(c_id),
    PRIMARY KEY (i_id_item, c_id_category)
);


-- Table: company
CREATE TABLE IF NOT EXISTS auction_schema.company (
    cp_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cp_a_info varchar(3000),
    cp_is_sold boolean,
    cp_seller_info varchar(3000)
);


-- Table: auction
CREATE TABLE IF NOT EXISTS auction_schema.auction (
    a_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    a_date date CHECK (a_date > '2000-01-01'),
    a_location varchar(250),
    a_type varchar(150),
    cp_id_company integer REFERENCES auction_schema.company(cp_id) ON DELETE SET NULL
);


-- Table: m2m_item_auction
CREATE TABLE IF NOT EXISTS auction_schema."m2m_item_auction" (
    i_id_item integer REFERENCES auction_schema.item(i_id),
    a_id_auction integer REFERENCES auction_schema.auction(a_id),
    PRIMARY KEY (i_id_item, a_id_auction)
);


-- Table: employee
CREATE TABLE IF NOT EXISTS auction_schema.employee (
    e_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    e_name varchar(150),
    e_role varchar(150),
    e_j_date date,
    e_d_buyer varchar(250),
    e_p_item money DEFAULT 0.00,
    cp_id_company integer REFERENCES auction_schema.company(cp_id) ON DELETE SET NULL
);



-- Step 3: Apply check constraints
-- Add check constraints in respective tables
ALTER TABLE auction_schema.seller
ADD CONSTRAINT check_seller_email CHECK (position('@' in s_email) > 0);

ALTER TABLE auction_schema.buyer
ADD CONSTRAINT check_buyer_email CHECK (position('@' in b_email) > 0);

ALTER TABLE auction_schema.item
ADD CONSTRAINT check_item_price CHECK (i_s_price >= money(0.00));

ALTER TABLE auction_schema.employee
ADD CONSTRAINT check_employee_price CHECK (e_p_item >= money(0.00));


-- Step 4: Populate tables with sample data (at least two rows per table)
INSERT INTO auction_schema.seller (s_f_name, s_l_name, s_address, s_email)
VALUES ('John', 'Doe', '123 Main St', 'john.doe@example.com'),
       ('Alice', 'Smith', '456 Elm St', 'alice.smith@example.com');


INSERT INTO auction_schema.buyer (b_f_name, b_l_name, b_address, b_email)
VALUES ('Bob', 'Johnson', '789 Oak St', 'bob.johnson@example.com'),
       ('Emily', 'Wilson', '101 Pine St', 'emily.wilson@example.com');


INSERT INTO auction_schema.item (i_l_num, i_description, i_s_price, s_id_seller)
VALUES (1001, 'Antique Vase', 200.00, 1),
       (1002, 'Rare Painting', 500.00, 2);


INSERT INTO auction_schema.category (c_name)
VALUES ('Art'),
       ('Antiques');


INSERT INTO auction_schema.company (cp_a_info, cp_is_sold, cp_seller_info)
VALUES ('Auction House Inc.', false, 'Seller info 1'),
       ('Antiques Unlimited', true, 'Seller info 2');


INSERT INTO auction_schema.auction (a_date, a_location, a_type, cp_id_company)
VALUES ('2023-01-15', 'New York', 'Art Auction', 1),
       ('2023-03-20', 'Los Angeles', 'Antiques Auction', 2);


INSERT INTO auction_schema.employee (e_name, e_role, e_j_date, e_d_buyer, e_p_item, cp_id_company)
VALUES ('Sarah Brown', 'Auctioneer', '2021-05-10', 'Buyer data 1', 500.00, 1),
       ('Michael Green', 'Appraiser', '2022-02-15', 'Buyer data 2', 350.00, 2);


-- manual adding values to these bridges
INSERT INTO auction_schema."m2m_item_buyer" (i_id_item, b_id_buyer)
VALUES (1, 1),
       (2, 2);

INSERT INTO auction_schema."m2m_item_category" (i_id_item, c_id_category)
VALUES (1, 1),
       (2, 2);

INSERT INTO auction_schema."m2m_item_auction" (i_id_item, a_id_auction)
VALUES (1, 3),
       (2, 4);

-- But it can also be done by triggers automatically  (The same it can be done with "m2m_item_category" and "m2m_item_auction" fields)
-- Create an AFTER INSERT trigger on the "item" table
CREATE OR REPLACE FUNCTION insert_into_m2m_item_buyer()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auction_schema."m2m_item_buyer" (i_id_item, b_id_buyer)
    VALUES (NEW.i_id, NEW.b_id_buyer);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER item_to_buyer_trigger
AFTER INSERT ON auction_schema.item
FOR EACH ROW
EXECUTE FUNCTION insert_into_m2m_Item_buyer();


-- Step 5: Add 'record_ts' field to each table
ALTER TABLE auction_schema.seller ADD COLUMN record_ts timestamp DEFAULT current_date;
ALTER TABLE auction_schema.buyer ADD COLUMN record_ts timestamp DEFAULT current_date;
ALTER TABLE auction_schema.item ADD COLUMN record_ts timestamp DEFAULT current_date;
ALTER TABLE auction_schema.auction ADD COLUMN record_ts timestamp DEFAULT current_date;
ALTER TABLE auction_schema.category ADD COLUMN record_ts timestamp DEFAULT current_date;
ALTER TABLE auction_schema.employee ADD COLUMN record_ts timestamp DEFAULT current_date;
ALTER TABLE auction_schema.company ADD COLUMN record_ts timestamp DEFAULT current_date;

