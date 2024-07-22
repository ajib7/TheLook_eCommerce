-- pembuatan tabel fact orders --

CREATE TABLE `astro-data-test.dataastro.fact_orders` AS
SELECT
  u.id AS id,
  u.email,
  u.traffic_source,
  u.age,
  u.gender,
  u.country,
  oi.order_id,
  oi.user_id,
  oi.product_id,
  oi.inventory_item_id,
  oi.status,
  oi.created_at,
  oi.shipped_at,
  oi.delivered_at,
  oi.returned_at,
  oi.sale_price,
  p.cost,
  p.category,
  p.name,
  p.brand,
  p.department,
  o.num_of_item
FROM
  `astro-data-test.dataastro.ORDER_ITEMS` oi
JOIN
  `astro-data-test.dataastro.USERS` u
ON
  oi.user_id = u.id
JOIN
  `astro-data-test.dataastro.PRODUCTS` p
ON
  oi.product_id = p.id
JOIN
  `astro-data-test.dataastro.ORDERS` o
ON
  oi.order_id = o.order_id;

-- report_monthly_orders_country_agg --

CREATE TABLE `astro-data-test.dataastro.report_monthly_orders_country_agg` AS
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(created_at, MONTH) AS order_month,
        country,
        SUM(sale_price*num_of_item) AS revenue
    FROM
        `astro-data-test.dataastro.fact_orders`
    WHERE 
        status NOT IN ('Cancelled','Returned')
    GROUP BY
        order_month, country
),
country_rankings AS (
    SELECT
        order_month,
        country,
        revenue,
    FROM
        monthly_sales
)
SELECT
    order_month,
    country,
    revenue,
    RANK() OVER (PARTITION BY order_month ORDER BY revenue DESC) AS sales_rank
FROM
    country_rankings
ORDER BY
    order_month, sales_rank;

-- report_monthly_orders_product_agg --

CREATE TABLE `astro-data-test.dataastro.report_monthly_orders_product_agg` AS
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(created_at, MONTH) AS order_month,
        name,
        SUM(sale_price*num_of_item) AS revenue
    FROM
        `astro-data-test.dataastro.fact_orders`
    WHERE 
        status NOT IN ('Cancelled','Returned')
    GROUP BY
        order_month, name
),
country_rankings AS (
    SELECT
        order_month,
        name,
        revenue,
    FROM
        monthly_sales
)
SELECT
    order_month,
    name,
    revenue,
    RANK() OVER (PARTITION BY order_month ORDER BY revenue DESC) AS sales_rank
FROM
    country_rankings
ORDER BY
    order_month, sales_rank;

-- Monthly Sales --

SELECT 
  DATE_TRUNC(DATE(created_at),MONTH) AS order_date,
  SUM(sale_price*num_of_item) AS revenue,
  COUNT(DISTINCT order_id) AS total_order,
  COUNT(DISTINCT user_id) AS customers_purchased
FROM 
  `astro-data-test.dataastro.fact_orders`
WHERE 
  status NOT IN ('Cancelled','Returned')
GROUP BY 1
ORDER BY 1 DESC;

-- Aging Order --

SELECT
  id,
  country,
  sale_price,
  num_of_item,
  created_at,
  delivered_at,
  DATE_DIFF(delivered_at, created_at, DAY) AS aging
FROM
  `astro-data-test.dataastro.fact_orders`
WHERE
  status = 'Complete';

-- Brands Sales --

SELECT 
  brand,
  SUM(sale_price*num_of_item) AS revenue,
  SUM(num_of_item) AS quantity
FROM 
  `astro-data-test.dataastro.fact_orders`
WHERE 
  status NOT IN ('Cancelled','Returned')
GROUP BY 1
ORDER BY 3 DESC;

-- Customers by Gender --

SELECT 
  gender,
  SUM(sale_price*num_of_item) revenue,
  SUM(num_of_item) quantity
FROM 
  `astro-data-test.dataastro.fact_orders`
WHERE 
  status NOT IN ('Cancelled','Returned')
GROUP BY 1
ORDER BY 2;

-- Customers by Age Group --

SELECT
  CASE 
    WHEN age <16 THEN 'Kids'
    WHEN age BETWEEN 16 AND 25 THEN 'Teenager'
    WHEN age BETWEEN 26 AND 45 THEN 'Adult'
    WHEN age >45 THEN 'Elder' END AS age_group,
  COUNT(DISTINCT user_id) total_customer
FROM 
  `astro-data-test.dataastro.fact_orders`
WHERE 
  status NOT IN ('Cancelled','Returned')
GROUP BY 1
ORDER BY 2 DESC;

-- Products Cancel & Return --

SELECT 
  category,
SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE null END) AS Cancelled,
SUM(CASE WHEN status = 'Returned' THEN 1 ELSE null END) AS Returned
FROM `astro-data-test.dataastro.fact_orders`
GROUP BY 1
ORDER BY 2 DESC;

-- Traffic (Marketing)--

SELECT
  traffic_source, 
  COUNT(DISTINCT user_id) total_customer
FROM
 `astro-data-test.dataastro.fact_orders`
WHERE
  status NOT IN ('Cancelled','Returned')
GROUP BY 1
ORDER BY 2 DESC;


