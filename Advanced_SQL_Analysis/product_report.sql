CREATE VIEW gold.product_report AS 

WITH basic_query AS (
--basic query (just the filtering and joins)
SELECT p.product_key,
	   p.product_name,
	   p.category_name,
	   p.sub_category,
	   p.cost,
	   s.price,
	   s.order_number,
	   s.customer_key,
	   s.quantity,
	   s.sales_amount,
	   s.order_date
FROM gold.dim_products p
LEFT JOIN gold.fact_sales s
ON p.product_key = s.product_key
WHERE s.order_date IS NOT NULL
)
, product_aggregation AS (
--product aggregation query
SELECT product_key,
	   product_name,
	   category_name,
	   sub_category,
	   SUM(cost) AS total_cost, 
	   AVG(price) AS avg_selling_price,
	   COUNT(DISTINCT order_number) AS total_orders,
	   SUM(quantity) AS  quantity_sold,
	   SUM(sales_amount) AS total_sales,	   
	   COUNT(DISTINCT customer_key) AS total_customers,
	   DATE_PART('year', AGE(MAX(order_date), MIN(order_date))) * 12 +
	   DATE_PART('month', AGE(MAX(order_date), MIN(order_date))) 
	   AS life_span,
	   MAX(order_date) AS last_order_date
FROM basic_query
GROUP BY 1,2,3,4
ORDER BY 3,4
)
SELECT 
product_key,
product_name,
CASE WHEN total_sales > 50000 THEN 'High_Range'
     WHEN total_sales BETWEEN 10000 AND 50000 THEN 'Mid_Range'
	 ELSE 'Low_Range'
END AS product_segment,
category_name,
sub_category,
total_cost, 
avg_selling_price,
total_orders,
quantity_sold,
total_sales,	   
total_customers,
life_span,
--average order revenue
CASE WHEN total_orders = 0 THEN total_sales
	 ELSE ROUND(total_sales::numeric / total_orders ::numeric,3)
END AS average_order_revenue,
--average monthly revenue
CASE WHEN life_span =0 THEN total_sales
	 ELSE ROUND(total_sales:: numeric/life_span::numeric,3)
END AS avg_monthly_revenue,
last_order_date
FROM product_aggregation


