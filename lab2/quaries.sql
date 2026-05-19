--Запрос для первой задачи
COPY (
    SELECT 
        c.customer_id,
        COUNT(o.order_id) AS order_count,
        COALESCE(SUM(o.total_amount), 0) AS total_spent,
        COALESCE(AVG(o.total_amount), 0) AS avg_check,
        COALESCE(MAX(o.total_amount), 0) AS max_order_amount,
        COUNT(DISTINCT oi.product_id) AS unique_products,
        COUNT(DISTINCT p.category_id) AS unique_categories,
        EXTRACT(DAY FROM (CURRENT_DATE - MIN(o.order_date))) AS days_since_first_order,
        CASE WHEN cp.preferred_delivery_time = 'morning' THEN 1 ELSE 0 END AS delivery_morning,
        CASE WHEN cp.preferred_delivery_time = 'day' THEN 1 ELSE 0 END AS delivery_day,
        CASE WHEN cp.preferred_delivery_time = 'evening' THEN 1 ELSE 0 END AS delivery_evening
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN customer_profiles cp ON c.customer_id = cp.customer_id
    GROUP BY c.customer_id, cp.preferred_delivery_time
) TO 'C:\my_files\programming\python\BD_labs\lab2\ml_dataset.csv' WITH CSV HEADER;
--Запрос для второй задачи
COPY (
    WITH customer_stats AS (
        SELECT 
            o2.customer_id,
            o2.order_id,
            COUNT(o2.order_id) OVER (PARTITION BY o2.customer_id 
                ORDER BY o2.order_date 
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS customer_total_orders,
            AVG(o2.total_amount) OVER (PARTITION BY o2.customer_id 
                ORDER BY o2.order_date 
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS customer_avg_check,
            EXTRACT(DAY FROM (o2.order_date - MIN(o2.order_date) OVER (PARTITION BY o2.customer_id))) AS days_since_first_order
        FROM orders o2
    ),
    order_items_agg AS (
        SELECT 
            oi.order_id,
            COUNT(oi.order_item_id) AS items_count,
            SUM(oi.quantity_kg) AS total_kg,
            AVG(oi.price_at_purchase) AS avg_price_per_kg,
            COUNT(DISTINCT p.category_id) AS unique_categories,
            MAX(CASE WHEN p.price_per_kg > 1000 THEN 1 ELSE 0 END) AS has_premium_product,
            MAX(p.stock_kg) AS max_stock_kg
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        GROUP BY oi.order_id
    )
    SELECT 
        o.order_id,
        o.customer_id,
        EXTRACT(DOW FROM o.order_date)::INT AS order_day_of_week,
        EXTRACT(MONTH FROM o.order_date)::INT AS order_month,
        o.total_amount AS order_total_amount,
        o.status,
        COALESCE(cs.customer_total_orders, 0) AS customer_total_orders,
        COALESCE(cs.customer_avg_check, 0) AS customer_avg_check,
        COALESCE(cs.days_since_first_order, 0) AS days_since_first_order,
        cp.loyalty_points,
        CASE WHEN cp.preferred_delivery_time = 'morning' THEN 1 ELSE 0 END AS delivery_morning,
        CASE WHEN cp.preferred_delivery_time = 'day' THEN 1 ELSE 0 END AS delivery_day,
        CASE WHEN cp.preferred_delivery_time = 'evening' THEN 1 ELSE 0 END AS delivery_evening,
        COALESCE(oi_agg.items_count, 0) AS items_count,
        COALESCE(oi_agg.total_kg, 0) AS total_kg,
        COALESCE(oi_agg.avg_price_per_kg, 0) AS avg_price_per_kg,
        COALESCE(oi_agg.unique_categories, 0) AS unique_categories,
        COALESCE(oi_agg.has_premium_product, 0) AS has_premium_product,
        COALESCE(oi_agg.max_stock_kg, 0) AS max_stock_kg
    FROM orders o
    LEFT JOIN customer_stats cs ON o.order_id = cs.order_id
    LEFT JOIN customer_profiles cp ON o.customer_id = cp.customer_id
    LEFT JOIN order_items_agg oi_agg ON o.order_id = oi_agg.order_id
) TO 'C:\my_files\programming\python\BD_labs\lab2\ml_dataset2.csv' WITH CSV HEADER;

