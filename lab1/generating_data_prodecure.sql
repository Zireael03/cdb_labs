CREATE OR REPLACE PROCEDURE generate_fresh_meat_data()
LANGUAGE plpgsql
AS $$
DECLARE
    cat_names TEXT[] := ARRAY['Говядина','Свинина','Курица','Баранина','Индейка','Утка'];
    cat_descs TEXT[] := ARRAY['Свежая говядина высшего сорта','Свинина фермерская','Охлаждённая курица','Молодая баранина','Диетическая индейка','Утиное филе'];
    prod_prefixes TEXT[] := ARRAY['Стейк','Фарш','Вырезка','Ребра','Грудинка','Филе','Котлеты','Шашлык'];
    statuses TEXT[] := ARRAY['new','processing','shipped','delivered','cancelled'];
    deliveries TEXT[] := ARRAY['morning','day','evening'];
    patronymics TEXT[] := ARRAY['Иванович','Петрович','Сергеевич','Алексеевич','Дмитриевич','Андреевич','Николаевич','Михайлович'];
BEGIN


    INSERT INTO categories (name, description)
    SELECT cat_names[n], cat_descs[n]
    FROM generate_series(1, array_length(cat_names, 1)) n;


    INSERT INTO products (name, category_id, price_per_kg, stock_kg)
    SELECT 
        prod_prefixes[1 + floor(random() * array_length(prod_prefixes, 1))] || ' ' || 
        (c.name || ' #' || n),
        c.category_id,
        ROUND((50 + random() * 1500)::numeric, 2),
        ROUND((10 + random() * 200)::numeric, 2)
    FROM generate_series(1, 500) n
    CROSS JOIN categories c
    LIMIT 500;


    INSERT INTO customers (first_name, last_name, patronymic, email, phone)
    SELECT 
        'User' || n, 
        'Surname' || n,
        patronymics[1 + floor(random() * array_length(patronymics, 1))],
        'user' || n || '@example.com',
        '+79' || LPAD((floor(random() * 1000000000))::TEXT, 9, '0')
    FROM generate_series(1, 200000) n;


    INSERT INTO customer_profiles (customer_id, birth_date, loyalty_points, preferred_delivery_time)
    SELECT 
        customer_id,
        CURRENT_DATE - (floor(random() * 20000))::INT,
        floor(random() * 5000),
        deliveries[1 + floor(random() * array_length(deliveries, 1))]
    FROM customers;


    INSERT INTO orders (customer_id, order_date, status, total_amount)
    SELECT 
        1 + floor(random() * 200000)::INT,
        CURRENT_TIMESTAMP - (floor(random() * 730))::INT * INTERVAL '1 day',
        statuses[1 + floor(random() * array_length(statuses, 1))],
        0.00
    FROM generate_series(1, 1000000) n;


    WITH order_expanded AS (
        SELECT order_id, (1 + floor(random() * 500))::int AS prod_id
        FROM orders
        CROSS JOIN LATERAL generate_series(1, 3) g
    )
    INSERT INTO order_items (order_id, product_id, quantity_kg, price_at_purchase)
    SELECT 
        oe.order_id, 
        p.product_id, 
        ROUND((0.5 + random() * 5.0)::numeric, 2), 
        p.price_per_kg
    FROM order_expanded oe
    JOIN products p ON p.product_id = oe.prod_id;

    UPDATE orders o SET total_amount = sub.total
    FROM (
        SELECT order_id, SUM(quantity_kg * price_at_purchase) AS total
        FROM order_items
        GROUP BY order_id
    ) sub
    WHERE o.order_id = sub.order_id;

    RAISE NOTICE 'Генерация данных успешно завершена.';
END;
$$;