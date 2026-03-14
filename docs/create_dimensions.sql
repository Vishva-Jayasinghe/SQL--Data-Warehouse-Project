--customers
CREATE VIEW gold.dim_customers AS 
SELECT ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,  --primary key
	   ci.cst_id AS customer_id,
	   ci.cst_key AS customer_number, 
	   ci.cst_firstname AS first_name,
	   ci.cst_lastname AS last_name,
	   la.cntry AS country,
	   ci.cst_marital_status AS marital_status,
	   CASE WHEN ci.cst_gndr !='N/A' THEN ci.cst_gndr --crm is Master for gender
			ELSE COALESCE(ca.gen,'N/A')
	   END AS gender,
	   ca.bdate AS birth_date,
	   ci.cst_create_date AS create_date	  
FROM silver.crm_customer_info ci
LEFT JOIN silver.erp_cust_az12 ca
	 ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	 ON ci.cst_key = la.cid

--Data Integration

SELECT DISTINCT
	   ci.cst_gndr,
		    ca.gen
FROM silver.crm_customer_info ci
LEFT JOIN silver.erp_cust_az12 ca
	 ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	 ON ci.cst_key = la.cid

--there are issues
SELECT DISTINCT
	   ci.cst_gndr,
		    ca.gen,
		CASE WHEN ci.cst_gndr !='N/A' THEN ci.cst_gndr --crm is Master for gender
			 ELSE COALESCE(ca.gen,'N/A')
		END AS new_gen
FROM silver.crm_customer_info ci
LEFT JOIN silver.erp_cust_az12 ca
	 ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	 ON ci.cst_key = la.cid
-- update original query


---products
CREATE VIEW  gold.dim_products AS
SELECT ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt,pn.prd_key) AS product_key, --primary key
      pn.prd_id AS product_id,
	  pn.prd_key AS product_number,
	  pn.prd_nm AS prodcut_name,
	  pn.cat_id AS category_id,
	  pc.cat AS category_name,
	  pc.subcat AS sub_category,
	  pc.maintenance,
	  pn.prd_cost AS cost,
	  pn.prd_line AS product_line,
	  pn.prd_start_dt AS start_date
	  --pn.prd_end_dt  
FROM silver.crm_product_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc 
	 ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL --filter out all historical data

