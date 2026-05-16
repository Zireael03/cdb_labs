-- 1. Товары категории с фильтрацией по популярности и цене
SELECT p.product_id, p.name, p.price_per_kg, 
       COUNT(oi.order_item_id) AS order_frequency,
       ROUND(AVG(oi.quantity_kg), 2) AS avg_order_weight
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id 
    AND o.order_date >= NOW() - INTERVAL '90 days'
WHERE c.name = 'Говядина'
  AND p.price_per_kg <= (
      SELECT AVG(price_per_kg) * 1.2 
      FROM products 
      WHERE category_id = c.category_id
  )
GROUP BY p.product_id, p.name, p.price_per_kg
HAVING COUNT(oi.order_item_id) > 0
ORDER BY order_frequency DESC;

-- 2. Заказы клиента за последние 30 дней с более чем 2 товарами
SELECT o.order_id, o.order_date, o.status, o.total_amount
FROM orders o
WHERE o.customer_id = (
        SELECT customer_id 
        FROM customers 
        WHERE email = 'user184894@example.com'
      )
  AND o.order_date >= NOW() - INTERVAL '30 days'
  AND (
        SELECT COUNT(DISTINCT product_id) 
        FROM order_items 
        WHERE order_id = o.order_id
      ) > 2
ORDER BY o.order_date DESC;


-- 3. Выручка по категориям
SELECT c.name AS category,
       SUM(oi.quantity_kg * oi.price_at_purchase) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.name
ORDER BY total_revenue DESC;

-- 4. Статистика по клиентам
SELECT CONCAT_WS(' ', cu.first_name, cu.last_name, cu.patronymic) AS client,
       COUNT(o.order_id) AS orders_count,
       ROUND(AVG(o.total_amount), 2) AS avg_check
FROM customers cu
JOIN orders o ON cu.customer_id = o.customer_id
GROUP BY cu.customer_id, cu.first_name, cu.last_name, cu.patronymic
HAVING COUNT(o.order_id) > 1
ORDER BY orders_count DESC;

-- 5. Поиск товаров по названию и цене
SELECT product_id, name, price_per_kg
FROM products
WHERE name ILIKE '%стейк%' AND price_per_kg <= 1500;

-- 6. Топ-5 клиентов по завершённым заказам с общей суммой от 10 000₽
SELECT 
    cu.first_name || ' ' || cu.last_name || ' ' || cu.patronymic AS client_name,
    cu.email,
    (SELECT COUNT(*) 
     FROM orders o2 
     WHERE o2.customer_id = cu.customer_id AND o2.status = 'delivered'
    ) AS completed_orders,
    (SELECT SUM(total_amount) 
     FROM orders o3 
     WHERE o3.customer_id = cu.customer_id AND o3.status = 'delivered'
    ) AS total_spent
FROM customers cu
WHERE cu.customer_id IN (
        SELECT customer_id 
        FROM orders 
        WHERE status = 'delivered'
      )
  AND (
        SELECT SUM(total_amount) 
        FROM orders 
        WHERE customer_id = cu.customer_id AND status = 'delivered'
      ) >= 10000
ORDER BY total_spent DESC
LIMIT 5;