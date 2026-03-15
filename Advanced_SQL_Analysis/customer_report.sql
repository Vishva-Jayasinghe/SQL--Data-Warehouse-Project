					
CREATE VIEW  gold.report_customers AS
WITH basic_details AS (
--basic details
SELECT 
s.order_number,
s.product_key,
s.order_date,
s.sales_amount,
s.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name,' ',c.last_name) AS customer_name,
DATE_PART('year', AGE(c.birth_date)) AS age
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON c.customer_key = s.customer_key
WHERE order_date IS NOT NULL
)
,customer_aggregation AS (
------Customer aggregations : summarize 
SELECT 
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order_date,
DATE_PART('year', AGE(MAX(order_date), MIN(order_date))) * 12 +
DATE_PART('month', AGE(MAX(order_date), MIN(order_date))) 
AS life_span
FROM basic_details
GROUP BY 1,2,3,4
)
SELECT 
customer_key,
customer_number,
customer_name,
age,
CASE 
WHEN age < 20 THEN 'Under 20'
WHEN age BETWEEN 20 AND 29 THEN '20-29'
WHEN age BETWEEN 30 AND 39  THEN '30-39'
WHEN age BETWEEN 40 AND 49  THEN '40-49'
ELSE '50 and Above'
END AS age_group,

CASE
WHEN life_span >12 	AND total_sales > 5000 THEN 'VIP'
WHEN life_span >=12 AND total_sales <=5000 THEN 'Regular'
ELSE 'New'
END  AS customer_type,
total_orders,
total_sales,
total_quantity,
total_products,
last_order_date,
life_span,
--- average order value (avg)
CASE WHEN total_orders = 0 THEN 0
     ELSE ROUND((total_sales / total_orders)::numeric,2)
END AS avg_order_value,
--average monthly spend
CASE WHEN life_span =0 THEN total_sales
	 ELSE total_sales / life_span
END AS avg_monthly_spend 
FROM customer_aggregation;

---




