--Testing
--crm_customer_info

--primary key checking
SELECT 
cst_id,
COUNT(*)
FROM bronze.crm_customer_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR cst_id IS NULL;

--check for unwanted spaces
SELECT cst_firstname
FROM bronze.crm_customer_info
WHERE cst_firstname!= TRIM(cst_firstname);

SELECT cst_lastname
FROM bronze.crm_customer_info
WHERE cst_lastname!= TRIM(cst_lastname);

--data consistency & standardization

SELECT DISTINCT cst_gndr
FROM bronze.crm_customer_info;


SELECT DISTINCT cst_marital_status
FROM bronze.crm_customer_info;

----end of crm_customer_info cleaning and testing

-------------------crm_product_info

--primary key
SELECT prd_id,
	   COUNT(*)

FROM bronze.crm_product_info
GROUP BY 1
HAVING COUNT(*) >1 AND prd_id IS NULL

--No issues found

--unwanted spaces
SELECT prd_nm
FROM bronze.crm_product_info 
WHERE prd_nm != TRIM(prd_nm)
--no issues'

--NULL and negative numbers
SELECT prd_cost
FROM bronze.crm_product_info 
WHERE prd_cost < 0 OR prd_cost IS NULL 
--replace by 0



--Data standardization and consistency
SELECT DISTINCT prd_line
FROM bronze.crm_product_info

--check for invalid date orders

SELECT * 
FROM bronze.crm_product_info
WHERE prd_end_dt < prd_start_dt


/*To avoid overlapping the dates  start < end 
as well as the end of first history should be younger than the start of the next record
So here we are going to remove all the end dates here and rebuild the end date using rules
*/
/* Having a null to the end date is fine ,but to the start date its not fine */


--so that we make a query here and after done we integrate with the main query

SELECT 
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt ASC) -1  AS  prd_end_dt_test
FROM bronze.crm_product_info


----- end of crm_product_info clean and loading--------




--crm_sales_details
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
FROM bronze.crm_sales_info
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
FROM bronze.crm_sales_info
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
FROM bronze.crm_sales_info
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_customer_info)

--DATES 
--sls_order_dt
SELECT NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_info
WHERE sls_order_dt <= 0 
OR  LENGTH(sls_order_dt::text) != 8 --length of a date must be 8
OR sls_order_dt > 20500101 --upper boundry 
OR sls_order_dt < 19000101 --lower bonudry

-- lets go and integrate our query


--sls_ship_dt
SELECT NULLIF(sls_ship_dt,0) sls_ship_dt
FROM bronze.crm_sales_info
WHERE sls_ship_dt <= 0 
OR  LENGTH(sls_ship_dt::text) != 8 --length of a date must be 8
OR sls_ship_dt > 20500101 --upper boundry 
OR sls_ship_dt < 19000101 --lower bonudry

--No issues found

---update the query


--sls_due_dt
SELECT NULLIF(sls_due_dt,0) sls_ship_dt
FROM bronze.crm_sales_info
WHERE sls_due_dt <= 0 
OR  LENGTH(sls_due_dt::text) != 8 --length of a date must be 8
OR sls_due_dt > 20500101 --upper boundry 
OR sls_due_dt < 19000101 --lower bonudry

-- no issues found , update the query

-- check for dates overlapping and other dates rules violations
/* Order date must always be earlier than shipping and due date. */

SELECT * 
FROM bronze.crm_sales_info
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

-- no issues found


--sls_sales , sls_quantity, sls_price 

SELECT DISTINCT sls_sales AS old_sales_value,
	   sls_quantity AS old_sls_quantity,
	   sls_price AS old_sls_price,
	   CASE WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales != sls_quantity * ABS(sls_price)														
	   		THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales 
	   END AS  sls_sales,

	   CASE WHEN sls_price IS NULL OR sls_price<=0 
	   		THEN sls_price / NULLIF(sls_quantity,0)
			ELSE sls_price 
	   END AS  sls_price
			  
	   
FROM bronze.crm_sales_info
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL 
OR sls_quantity IS NULL
OR sls_price IS NULL

OR sls_sales <=0 
OR sls_quantity <=0 
OR sls_price <=0 

ORDER BY 1,2,3 ;

/* Rules:
If sls_sales is negative ,zero or null derive it using quantity and price
If sls_price is zero or null derive it using quantity and sales
If pirce is negative convert it to a positive value
*/

SELECT sls_quantity
FROM bronze.crm_sales_info
WHERE sls_quantity IS NULL OR sls_quantity <=0
-- no issues here
----------------------end of cleaning and loading crm_sales_info

--erp_cust_az12 

--check for data intergrity  after transformation
SELECT  CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
			 ELSE cid
	  	END AS cid,
		bdate,
		gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
		   ELSE cid
	  END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_customer_info)



-- bdate
SELECT DISTINCT bdate
FROM bronze.erp_cust_az12
WHERE AGE(CURRENT_DATE, bdate) > INTERVAL '100 years'
   OR bdate > CURRENT_DATE;

 --lets update a main query

--gender
SELECT  
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
		 	 WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
			 ELSE 'N/A'
	 END AS gen
FROM bronze.erp_cust_az12

--have issues AND  update original query


--erp_loc_a101
--Data intergrity
SELECT REPLACE(cid,'-','')
cntry
FROM bronze.erp_loc_a101


--data standardization
SELECT DISTINCT
cntry
FROM bronze.erp_loc_a101
-- have issues make a query and update main query
