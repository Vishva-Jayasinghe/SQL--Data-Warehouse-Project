--Testing
--crm_customer_info

--primary key checking
SELECT 
cst_id,
COUNT(*)
FROM silver.crm_customer_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR cst_id IS NULL;

--check for unwanted spaces
SELECT cst_firstname
FROM silver.crm_customer_info
WHERE cst_firstname!= TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_customer_info
WHERE cst_lastname!= TRIM(cst_lastname);

--data consistency & standardization

SELECT DISTINCT cst_gndr
FROM  silver.crm_customer_info;


SELECT DISTINCT cst_marital_status
FROM silver.crm_customer_info;


----------products

SELECT prd_id,
	   COUNT(*)

FROM silver.crm_product_info
GROUP BY 1
HAVING COUNT(*) >1 AND prd_id IS NULL

--No issues found

--unwanted spaces
SELECT prd_nm
FROM silver.crm_product_info 
WHERE prd_nm != TRIM(prd_nm)
--no issues'

--NULL and negative numbers
SELECT prd_cost
FROM silver.crm_product_info 
WHERE prd_cost < 0 OR prd_cost IS NULL 



--Data standardization and consistency
SELECT DISTINCT prd_line
FROM silver.crm_product_info

--check for invalid date orders

SELECT * 
FROM silver.crm_product_info
WHERE prd_end_dt < prd_start_dt



SELECT * 
FROM silver.crm_product_info



------------crm_sales_details
--sls_ord_num
SELECT sls_ord_num,
	   sls_prd_key,
	   sls_cust_id,
	   sls_order_dt,
	   sls_ship_dt,
	   sls_due_dt,
	   sls_sales,
	   sls_quantity,
	   sls_price
FROM silver.crm_sales_info
WHERE sls_ord_num != TRIM(sls_ord_num)

--sls_prd_key
SELECT sls_ord_num,
	   sls_prd_key,
	   sls_cust_id,
	   sls_order_dt,
	   sls_ship_dt,
	   sls_due_dt,
	   sls_sales,
	   sls_quantity,
	   sls_price
FROM silver.crm_sales_info
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_product_info)

--sls_cust_id
SELECT sls_ord_num,
	   sls_prd_key,
	   sls_cust_id,
	   sls_order_dt,
	   sls_ship_dt,
	   sls_due_dt,
	   sls_sales,
	   sls_quantity,
	   sls_price
FROM silver.crm_sales_info
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_customer_info)




-- no issues found , update the query

-- check for dates overlapping and other dates rules violations
/* Order date must always be earlier than shipping and due date. */

SELECT * 
FROM silver.crm_sales_info
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

-- no issues found


--sls_sales , sls_quantity, sls_price 

SELECT  sls_sales,
	   sls_quantity,
	   sls_price
	   
FROM silver.crm_sales_info
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL 
OR sls_quantity IS NULL
OR sls_price IS NULL

OR sls_sales <=0 
OR sls_quantity <=0 
OR sls_price <=0 

ORDER BY 1,2,3 ; --- No  issues found

/* Rules:
If sls_sales is negative ,zero or null derive it using quantity and price
If sls_price is zero or null derive it using quantity and sales
If pirce is negative convert it to a positive value
*/


SELECT sls_quantity
FROM silver.crm_sales_info
WHERE sls_quantity IS NULL OR sls_quantity <=0
-- no issues here



----erp_cust_az1
SELECT DISTINCT bdate
FROM silver.erp_cust_az12
WHERE AGE(CURRENT_DATE, bdate) > INTERVAL '100 years'
   OR bdate > CURRENT_DATE;
--no  issues

--data intergrity
SELECT  CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
			 ELSE cid
	  	END AS cid,
		bdate,
		gen
FROM silver.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
		   ELSE cid
	  END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_customer_info)

--no issues

--gen
SELECT DISTINCT gen
FROM silver.erp_cust_az12


------------end of erp_cust_az12---------------

--erp_loc_a101
--data standardization
SELECT DISTINCT
cntry
FROM silver.erp_loc_a101



