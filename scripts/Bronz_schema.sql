CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;

--developing bronze schema 

DROP TABLE IF EXISTS bronze.crm_customer_info;
CREATE TABLE bronze.crm_customer_info(
cst_id INT,
cst_key	VARCHAR(75),
cst_firstname VARCHAR(50),
cst_lastname VARCHAR(50),
cst_marital_status VARCHAR(20),
cst_gndr VARCHAR(10),
cst_create_date DATE
);

DROP TABLE IF EXISTS bronze.crm_product_info;
CREATE TABLE bronze.crm_product_info(
prd_id INT,
prd_key	VARCHAR(100),
prd_nm VARCHAR(100),
prd_cost FLOAT,
prd_line VARCHAR(10),
prd_start_dt DATE,
prd_end_dt DATE

);

DROP TABLE IF EXISTS bronze.crm_sales_info;
CREATE TABLE bronze.crm_sales_info(
sls_ord_num VARCHAR(75),
sls_prd_key VARCHAR(75),
sls_cust_id	INT,
sls_order_dt INT,
sls_ship_dt	INT,
sls_due_dt INT,
sls_sales FLOAT,
sls_quantity INT,
sls_price FLOAT
);



DROP TABLE IF EXISTS bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12(
cid VARCHAR(75),
bdate DATE,
gen VARCHAR(15)
);


DROP TABLE IF EXISTS bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101(
cid VARCHAR(75),
cntry VARCHAR(75)
);

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2(
ID VARCHAR(20),
cat VARCHAR(75),
subcat VARCHAR(100),
maintenance VARCHAR(20)
);

---Clear and Load into silver layer

--- crm_customer_info 
INSERT INTO silver.crm_custOmer_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date)
SELECT cst_id,
	   cst_key,
	   TRIM(cst_firstname) AS cst_firstname,
	   TRIM(cst_lastname) AS cst_lastname,
	   CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	   		WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			ELSE 'N/A'
	   END AS cst_marital_status,

	   CASE WHEN  UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	   		WHEN  UPPER(TRIM(cst_gndr))= 'F' THEN 'Female'
			ELSE 'N/A'
	   END AS cst_gndr,
	   cst_create_date  
FROM
(
		SELECT * 
		FROM
	(
			SELECT *,
				   ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS last_flag
			FROM bronze.crm_customer_info
			WHERE cst_id IS NOT NULL
		)t 
		WHERE last_flag =1
);

----end of uploading crm_customer_info

---crm_product_info clean and load
INSERT INTO silver.crm_product_info(
prd_id,
cat_id , 
prd_key,
prd_nm ,
prd_cost,
prd_line ,
prd_start_dt,
prd_end_dt
)
SELECT 
		prd_id,
		REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id,
		SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,
		prd_nm,
		COALESCE(prd_cost, 0) AS prd_cost,
		CASE WHEN UPPER(TRIM(prd_line)) = 'M' Then 'Mountain'
			 WHEN UPPER(TRIM(prd_line)) = 'R' Then 'Road'
			 WHEN UPPER(TRIM(prd_line)) = 'S' Then 'Other Sales'
			 WHEN UPPER(TRIM(prd_line)) = 'T' Then 'Touring'
			 ELSE 'N/A' 
		END AS prd_line,
		prd_start_dt,
		LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt ASC) -1  AS  prd_end_dt
FROM bronze.crm_product_info;


--Clean & Load crm_sales_details
INSERT INTO silver.crm_sales_info(
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
)
SELECT sls_ord_num,
	   sls_prd_key,
	   sls_cust_id,
	   CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::text) != 8 THEN NULL
	   		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) -- We cannot directly convert int--> date
	   END sls_order_dt,

	   CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::text) != 8 THEN NULL
	   ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) -- We cannot directly convert int--> date
	   END AS sls_ship_dt,
	   
	   CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::text) != 8 THEN NULL
	   ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) -- We cannot directly convert int--> date
	   END AS sls_due_dt,
	   	   
	   CASE WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales != sls_quantity * ABS(sls_price)
	   		THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales 
	   END AS  sls_sales,
	   
	   sls_quantity,
	   
	   CASE WHEN sls_price IS NULL OR sls_price<=0 
	   		THEN sls_sales / NULLIF(sls_quantity,0)
			ELSE sls_price 
	   END AS  sls_price	   
FROM bronze.crm_sales_info;



--clean and load erp_cust_az12
INSERT INTO silver.erp_cust_az12(
cid,
bdate,
gen
)
SELECT * 
FROM ( 
		SELECT  CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
					 ELSE cid
			  	END AS cid,
				  
				CASE WHEN bdate > CURRENT_DATE THEN NULL
				ELSE bdate
				END AS bdate,
				CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
				 	 WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
					 ELSE 'N/A'
				END AS gen
		FROM bronze.erp_cust_az12
)t		
WHERE AGE(CURRENT_DATE, bdate) <= INTERVAL '100 years';


--clean and load erp_loc_a101
INSERT INTO silver.erp_loc_a101(
cid,
cntry
)
SELECT REPLACE(cid,'-','') cid,
	   CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	   		WHEN TRIM(cntry) IN ('USA','US') THEN 'United States'
			WHEN TRIM(cntry)='' OR cntry IS NULL THEN 'N/A'
			ELSE TRIM(cntry)
	   END AS cntry
FROM bronze.erp_loc_a101;

--clean and load erp_px_cat_g1v2
INSERT INTO silver.erp_px_cat_g1v2(
id,
cat,
subcat,
maintenance
)
SELECT id,
	   cat,
	   subcat,
	   maintenance
FROM bronze.erp_px_cat_g1v2
--this table has no issues
