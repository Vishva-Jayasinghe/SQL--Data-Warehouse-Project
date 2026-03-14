
--developing Silver schema 

DROP TABLE IF EXISTS silver.crm_customer_info;
CREATE TABLE silver.crm_customer_info(
cst_id INT,
cst_key	VARCHAR(75),
cst_firstname VARCHAR(50),
cst_lastname VARCHAR(50),
cst_marital_status VARCHAR(20),
cst_gndr VARCHAR(10),
cst_create_date DATE,
dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);

DROP TABLE IF EXISTS silver.crm_product_info;
CREATE TABLE silver.crm_product_info(
prd_id INT,
cat_id VARCHAR(100), -- Update
prd_key	VARCHAR(100),
prd_nm VARCHAR(100),
prd_cost FLOAT,
prd_line VARCHAR(75),
prd_start_dt DATE,
prd_end_dt DATE,
dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);

DROP TABLE IF EXISTS silver.crm_sales_info;
CREATE TABLE silver.crm_sales_info(
sls_ord_num VARCHAR(75),
sls_prd_key VARCHAR(75),
sls_cust_id	INT,
sls_order_dt DATE,
sls_ship_dt	DATE,
sls_due_dt DATE,
sls_sales FLOAT,
sls_quantity INT,
sls_price FLOAT,
dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


DROP TABLE IF EXISTS silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12(
cid VARCHAR(75),
bdate DATE,
gen VARCHAR(15),
dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


DROP TABLE IF EXISTS silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101(
cid VARCHAR(75),
cntry VARCHAR(100),
dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2(
id VARCHAR(20),
cat VARCHAR(75),
subcat VARCHAR(100),
maintenance VARCHAR(20),
dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


