
# SQL Business Analysis -- Sales & Customer Insights

## Project Overview

This project demonstrates **advanced SQL analytics** performed on a
sales data warehouse.\
The goal is to answer real-world **business questions** related to sales
performance, customer behavior, and product performance using
**analytical SQL queries and window functions**.

The project works on a star-schema style data warehouse with:

-   **fact_sales** -- transactional sales data\
-   **dim_customers** -- customer dimension\
-   **dim_products** -- product dimension

The analysis includes:

-   Time-based sales trend analysis
-   Cumulative and moving metrics
-   Product performance evaluation
-   Customer segmentation
-   Category contribution analysis
-   Analytical reporting views for BI tools

------------------------------------------------------------------------

# Database Structure

Main tables used in the analysis:

-   `gold.fact_sales`
-   `gold.dim_customers`
-   `gold.dim_products`

These tables are joined to analyze **customer behaviour, product
performance and sales growth over time**.

------------------------------------------------------------------------

# Key Business Analysis

## 1. Change Over Time Analysis

Analyze yearly sales performance.

``` sql
SELECT EXTRACT(YEAR FROM order_date) AS year,
       SUM(sales_amount) AS total_sales,
       COUNT(DISTINCT customer_key) AS total_customers,
       SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY EXTRACT(YEAR FROM order_date);
```

This analysis identifies:

-   Growth trends
-   Customer expansion
-   Demand increase or decrease

------------------------------------------------------------------------

# Cumulative Sales Analysis

Calculate running total sales and moving averages to identify long-term
trends.

``` sql
SELECT 
    year,
    total_sales,
    SUM(total_sales) OVER (
        ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    GROUP BY EXTRACT(YEAR FROM order_date)
) t
ORDER BY year;
```

This helps track:

-   Long-term business growth
-   Accumulated revenue performance

------------------------------------------------------------------------

# Product Performance Analysis

Evaluate yearly product performance compared with:

-   Average product sales
-   Previous year sales

Key techniques used:

-   `WINDOW FUNCTIONS`
-   `LAG()`
-   `PARTITION BY`

------------------------------------------------------------------------

# Category Contribution Analysis

Identify which product categories generate the highest sales
contribution.

``` sql
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
    ROUND((total_sales/SUM(total_sales) OVER()) * 100,2) AS contribution_percentage
FROM category_sales
ORDER BY total_sales DESC;
```

This analysis helps businesses understand:

-   Which categories drive revenue
-   Where to focus marketing and inventory

------------------------------------------------------------------------

# Customer Segmentation

Customers are segmented into three business groups:

  Segment   Definition
  --------- ---------------------------------------------------------
  VIP       Customers with \>12 months history and spending \> 5000
  Regular   Customers with \>12 months history and spending ≤ 5000
  New       Customers with \<12 months purchase history

This segmentation helps companies:

-   Identify high value customers
-   Design loyalty programs
-   Improve customer retention strategies

------------------------------------------------------------------------

# Customer Analytics Report (SQL View)

A reusable analytical view was created to summarize customer metrics.

``` sql
CREATE VIEW gold.report_customers AS
SELECT
customer_key,
customer_number,
customer_name,
total_orders,
total_sales,
avg_order_value,
avg_monthly_spend
FROM customer_aggregation;
```

The report includes:

-   Customer age group
-   Customer type (VIP / Regular / New)
-   Total orders
-   Total sales
-   Average order value
-   Monthly spending behaviour

------------------------------------------------------------------------

# Product Performance Report (SQL View)

A second analytical view summarizes product performance.

``` sql
CREATE VIEW gold.product_report AS
SELECT
product_key,
product_name,
category_name,
sub_category,
total_sales,
total_orders,
quantity_sold,
avg_monthly_revenue
FROM product_aggregation;
```

This report helps evaluate:

-   Product demand
-   Revenue contribution
-   Customer reach
-   Sales lifecycle

------------------------------------------------------------------------

# Tools Used

-   SQL (PostgreSQL)
-   Window Functions
-   Analytical Queries
-   Data Warehouse (Star Schema)
-   BI Visualization (Power BI)

------------------------------------------------------------------------

# Key SQL Techniques Used

-   Aggregations
-   Window Functions
-   LAG / DENSE_RANK
-   CTEs (Common Table Expressions)
-   Analytical Views
-   Time-based analysis
-   Customer segmentation logic

------------------------------------------------------------------------

# Project Value

This project demonstrates the ability to:

-   Solve **real business problems using SQL**
-   Perform **advanced analytical queries**
-   Build **report-ready datasets for BI tools**
-   Transform raw warehouse data into **actionable insights**

------------------------------------------------------------------------

# Author

**Vishva Suraj**\
Aspiring **Data Analyst / BI Developer / ML Practitioner**
