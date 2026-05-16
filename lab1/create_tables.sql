CREATE TABLE categories (
    category_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE products (
    product_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL REFERENCES categories(category_id),
    price_per_kg NUMERIC(10,2) CHECK (price_per_kg > 0),
    stock_kg NUMERIC(10,2) DEFAULT 0
);

CREATE TABLE customers (
    customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20)
);

CREATE TABLE customer_profiles (
    profile_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT UNIQUE NOT NULL REFERENCES customers(customer_id),
    birth_date DATE,
    loyalty_points INT DEFAULT 0,
    preferred_delivery_time VARCHAR(20)
);

CREATE TABLE orders (
    order_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'new',
    total_amount NUMERIC(12,2) DEFAULT 0
);

CREATE TABLE order_items (
    order_item_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id),
    quantity_kg NUMERIC(10,2) CHECK (quantity_kg > 0),
    price_at_purchase NUMERIC(10,2) NOT NULL
);