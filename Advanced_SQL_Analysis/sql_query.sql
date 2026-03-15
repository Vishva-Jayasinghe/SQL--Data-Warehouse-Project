/* Change over time analysis */
--year wise sales
SELECT EXTRACT(YEAR FROM order_date) AS year,
       SUM(sales_amount) AS total_sales,
	   COUNT(DISTINCT customer_key) AS total_customers,
	   SUM(quantity)  AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY EXTRACT(YEAR FROM order_date);

--Monthly
SELECT 
    EXTRACT(MONTH FROM order_date) AS month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity,
    DENSE_RANK() OVER (ORDER BY SUM(sales_amount) DESC) AS sales_rank
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY month;



--Month and Year
SELECT year,
	   month,
	   total_sales,
	   rank
FROM (
SELECT 
	EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity,
	DENSE_RANK() OVER(PARTITION BY EXTRACT(YEAR FROM order_date) ORDER BY SUM(sales_amount) DESC) AS rank
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(MONTH FROM order_date), EXTRACT(YEAR FROM order_date)
ORDER BY year,month) t

WHERE rank =1;


---Cumulative analysis

/* calculate the total sales per month and the running total of sales over time */
SELECT 
    year,
    total_sales,
    SUM(total_sales) OVER (
        ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
	AVG(avg_price) OVER(
		ORDER BY year 
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	)AS moving_average
FROM 
(
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year,
        SUM(sales_amount) AS total_sales,
		AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM order_date)
) t
ORDER BY year;

--Performance analyzing
---comparing current value to a target value

/*Analyze the yearly peformance of products by comparing each product's sales to both its average sales 
performance and the previous year's sales */
WITH yearly_product_sales AS (
SELECT EXTRACT(YEAR FROM s.order_date) AS year,
	   p.product_name,
	   SUM(s.sales_amount) AS current_sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p 
ON s.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY 1,2
)
SELECT 
		year,
		product_name,
		current_sales,
		AVG(current_sales) OVER (PARTITION BY product_name) AS  avg_sales,
		current_sales - AVG(current_sales) OVER (PARTITION BY product_name)  AS diff_avg,
		CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above avg'
		     WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below avg'
			 ELSE 'Avg'
		END AS avg_change,
		--year over year---
		COALESCE(LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year),0) AS py_sales, -- compare current year sales with previous year sale
		current_sales -  COALESCE(LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year),0) AS diff_py,
			CASE WHEN current_sales -  COALESCE(LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year),0) > 0  THEN 'Grow_up'
			WHEN current_sales -  COALESCE(LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year),0) < 0  THEN 'Grow_down'
			ELSE 'No differnce'
			END AS py_change
			
FROM yearly_product_sales
ORDER BY product_name, year;


/* Which categories contribute the most to overall sales? */
WITH category_sales AS ( 
SELECT p.category_name,
	   SUM(s.sales_amount) AS total_sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON p.product_key = s.product_key
GROUP BY p.category_name
) 
SELECT 
		category_name,
		total_sales,
		CONCAT(ROUND((total_sales/SUM(total_sales) OVER())::numeric * 100,3),'%') AS contribution
FROM 
category_sales
ORDER BY total_sales DESC;



/* Segment products into cost ranges and count  how many products fall into 
each segment */
WITH product_segment AS (
SELECT product_key,
	   product_name,
	   cost,
	   CASE WHEN cost < 100 THEN 'Below 100'
	   		WHEN cost BETWEEN 100 AND 500 THEN '100-500'
			WHEN cost BETWEEN 500 AND 1000 THEN '500 -1000'
			ELSE 'Above 1000'
		END AS cost_range
FROM 
gold.dim_products)
SELECT cost_range,
	   COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY 2 DESC;

/*
Group customers into three segments based on their spending behaviour :
		* VIP : customers with at least 12 months of history but spending more than 5000.
		* Regular : customers with at least 12 months of history but spending 5000 or less.
		* New : customer with a  life span less than 12 months.
Find the total number of customers by each group.*/

--life span is time between first order and last order
SELECT customer_type,
	   COUNT(customer_key)
	
FROM 
(
WITH customer_spending AS (
SELECT 
    c.customer_key,
    SUM(s.sales_amount) AS total_spending,
    MIN(s.order_date) AS first_order,
    MAX(s.order_date) AS last_order,
    DATE_PART('year', AGE(MAX(s.order_date), MIN(s.order_date))) * 12 +
    DATE_PART('month', AGE(MAX(s.order_date), MIN(s.order_date))) 
    AS life_span_months
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
    ON s.customer_key = c.customer_key
GROUP BY c.customer_key
)
SELECT customer_key,
	   total_spending,
	   life_span_months,
	   CASE WHEN life_span_months >12 AND total_spending > 5000 THEN 'VIP'
	   		WHEN life_span_months >=12 AND total_spending <=5000 THEN 'Regular'
			ELSE 'New'
	   END  AS customer_type
			   
FROM customer_spending
)t
GROUP BY 1;








